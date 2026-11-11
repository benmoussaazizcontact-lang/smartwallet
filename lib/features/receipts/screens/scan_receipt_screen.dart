import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/receipt_draft.dart';
import '../providers/receipt_providers.dart';
import '../services/ocr_errors.dart';
import '../services/ocr_parser.dart';
import '../services/ocr_service.dart';

class ScanReceiptScreen extends ConsumerStatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  ConsumerState<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends ConsumerState<ScanReceiptScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  Uint8List? _preview;
  String? _path;
  bool _busy = false;
  String? _error;
  late final AnimationController _scanLine;

  @override
  void initState() {
    super.initState();
    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _scanLine.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2400,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _preview = bytes;
        _path = file.path;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      final text = error.toString().toLowerCase();
      final denied = text.contains('permission') ||
          text.contains('access_denied') ||
          text.contains('camera_access');
      setState(() {
        _error = denied
            ? context.l10n.permissionDeniedMedia
            : context.l10n.ocrUnreadableImage;
      });
    }
  }

  Future<void> _ocr() async {
    if (_preview == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final text = await OcrService().recognize(
        imagePath: _path,
        bytes: _preview,
      );
      if (text.trim().isEmpty) {
        throw const OcrFailure(OcrFailureKind.noText);
      }
      final parsed = const OcrParser().parse(text);
      if (!mounted) return;
      final resume =
          GoRouterState.of(context).uri.queryParameters['resume'] == '1';
      var operationId = const Uuid().v4();
      if (resume) {
        final pending = ref.read(pendingReceiptsProvider).asData?.value;
        if (pending != null && pending.isNotEmpty) {
          operationId = pending.first.operationId;
        }
      }
      await context.push(
        '/scan/confirm',
        extra: ReceiptDraft(
          operationId: operationId,
          imageBytes: _preview!,
          imagePath: _path ?? '',
          rawText: parsed.rawText,
          merchant: parsed.merchant,
          receiptNumber: parsed.receiptNumber,
          amount: parsed.total,
          currency: parsed.currency,
          paymentMethod: parsed.paymentMethod,
          date: parsed.date,
          tax: parsed.tax,
          items: parsed.items,
          arabicScriptSeen: parsed.arabicScriptSeen,
          amountNeedsReview: parsed.amountNeedsReview,
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = localizedOcrMessage(error, context.l10n));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reduce = AppMotion.reduce(context);
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;
      setState(() {
        _preview = null;
        _path = null;
        _error = null;
        _busy = false;
      });
    });
    if (reduce && _scanLine.isAnimating) {
      _scanLine.stop();
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanReceipt),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(l10n.scanIntro, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: _preview == null
                        ? Center(
                            child: Text(
                              l10n.scanFrameHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          )
                        : Image.memory(_preview!, fit: BoxFit.cover),
                  ),
                  CustomPaint(painter: _ScanFramePainter()),
                  if (_busy && !reduce)
                    AnimatedBuilder(
                      animation: _scanLine,
                      builder: (context, _) {
                        return Align(
                          alignment: Alignment(0, -1 + (_scanLine.value * 2)),
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 28),
                            color: AppColors.accent.withValues(alpha: 0.85),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            Text(l10n.ocrProgress, textAlign: TextAlign.center),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(l10n.ocrRetryHint, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.gallery),
                ),
              ),
            ],
          ),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(l10n.ocrWebHint),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              l10n.ocrArabicLocalUnsupported,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.scanOcr,
            loading: _busy,
            onPressed: _preview == null ? null : _ocr,
          ),
        ],
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const inset = 22.0;
    const len = 28.0;
    final rect = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(len, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, len), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-len, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, len), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(len, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -len), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-len, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
