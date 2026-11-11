import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_motion.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.ready, required this.onFinished});

  final bool ready;
  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _glow;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.reduce(context)) {
        _master.value = 1;
        _tryFinish();
      } else {
        _master.forward();
        _glow.repeat();
        _master.addStatusListener((status) {
          if (status == AnimationStatus.completed) _tryFinish();
        });
      }
    });
  }

  @override
  void didUpdateWidget(SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready) _tryFinish();
  }

  void _tryFinish() {
    if (_finished || !widget.ready) return;
    if (_master.status != AnimationStatus.completed && _master.value < 1) {
      return;
    }
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _master.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reduce = AppMotion.reduce(context);
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: AnimatedBuilder(
        animation: Listenable.merge([_master, _glow]),
        builder: (context, _) {
          final t = _master.value;
          final bg = Curves.easeOut.transform((t / 0.2).clamp(0.0, 1.0));
          final logoT = Curves.easeOutCubic.transform(
            ((t - 0.2) / 0.3).clamp(0.0, 1.0),
          );
          final titleT = Curves.easeOutCubic.transform(
            ((t - 0.4) / 0.33).clamp(0.0, 1.0),
          );
          final sweep = Curves.easeInOut.transform(
            ((t - 0.73) / 0.27).clamp(0.0, 1.0),
          );
          return Opacity(
            opacity: bg,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF070B14),
                        Color(0xFF0E1A36),
                        Color(0xFF14102A),
                      ],
                    ),
                  ),
                ),
                if (!reduce)
                  CustomPaint(
                    painter: _AmbientPainter(
                      glow: _glow.value,
                      sweep: sweep,
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.92 + (0.08 * logoT),
                        child: Opacity(
                          opacity: logoT,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 28,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: titleT,
                        child: Transform.translate(
                          offset: Offset(0, 14 * (1 - titleT)),
                          child: Text(
                            l10n.appTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimaryDark,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({required this.glow, required this.sweep});

  final double glow;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.38);
    final pulse = 0.55 + (math.sin(glow * math.pi * 2) * 0.12);
    canvas.drawCircle(
      center,
      size.width * 0.42 * pulse,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.72),
      90,
      Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
    final rnd = math.Random(7);
    for (var i = 0; i < 18; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final drift = math.sin((glow + i) * math.pi * 2) * 6;
      canvas.drawCircle(
        Offset(x, y + drift),
        1.6 + (i % 3),
        Paint()..color = Colors.white.withValues(alpha: 0.12 + (i % 4) * 0.04),
      );
    }
    if (sweep > 0) {
      final y = size.height * (0.2 + sweep * 0.5);
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 24),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.12),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, y, size.width, 24)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) =>
      oldDelegate.glow != glow || oldDelegate.sweep != sweep;
}
