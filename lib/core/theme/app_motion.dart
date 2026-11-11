import 'package:flutter/widgets.dart';

class AppMotion {
  AppMotion._();

  static const press = Duration(milliseconds: 140);
  static const card = Duration(milliseconds: 320);
  static const page = Duration(milliseconds: 380);
  static const modal = Duration(milliseconds: 300);
  static const chart = Duration(milliseconds: 560);
  static const splashBg = Duration(milliseconds: 300);
  static const splashLogo = Duration(milliseconds: 450);
  static const splashTitle = Duration(milliseconds: 500);
  static const splashSweep = Duration(milliseconds: 400);

  static const Curve easeOut = Cubic(0.16, 1, 0.3, 1);
  static const Curve easeInOut = Cubic(0.4, 0, 0.2, 1);

  static bool reduce(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration of(BuildContext context, Duration duration) =>
      reduce(context) ? Duration.zero : duration;

  static Duration stagger(BuildContext context, int index, {int stepMs = 45}) {
    if (reduce(context)) return Duration.zero;
    return Duration(milliseconds: (index * stepMs).clamp(0, 280));
  }
}
