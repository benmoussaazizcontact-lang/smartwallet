import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduce(context);
    return Listener(
      onPointerDown: widget.onPressed == null || widget.loading
          ? null
          : (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down && !reduce ? 0.98 : 1,
        duration: AppMotion.of(context, AppMotion.press),
        curve: AppMotion.easeOut,
        child: FilledButton(
          onPressed: widget.loading ? null : widget.onPressed,
          child: widget.loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.label),
        ),
      ),
    );
  }
}
