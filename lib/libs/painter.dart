import 'package:flutter/material.dart';
import 'package:masthore/main.dart';

Paint Function() createPaint(double width, Color Function() getColor) {
  return () => Paint()
    ..color = getColor()
    ..strokeWidth = width
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round;
}

final ColorScheme colors = Theme.of(globalKey.currentContext!).colorScheme;
Color Function() getTheme(String color) {
  return () =>
      (Theme.of(globalKey.currentContext!).brightness == Brightness.dark
          ? {
              "grey": const Color(0xff707070),
              "primary": colors.primary,
              "light": const Color(0xFFB4B4B4),
            }
          : {
              "grey": const Color(0xff939393),
              "primary": colors.primary,
              "light": const Color.fromARGB(255, 34, 34, 34),
            })[color]!;
}

final Paint Function() thinPaint = createPaint(1, getTheme('grey'));
final Paint Function() finerPaint = createPaint(0.25, getTheme('grey'));
final Paint Function() painter = createPaint(2, (getTheme('primary')));
final Paint Function() lightPainer = createPaint(2, (getTheme('light')));
