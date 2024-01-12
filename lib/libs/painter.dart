import 'package:flutter/material.dart';
import 'package:masthore/main.dart';

/* 创建Paint */
Paint Function() createPaint(
    {required double width,
    required Color Function() color,
    PaintingStyle paintingStyle = PaintingStyle.stroke}) {
  return () => Paint()
    ..color = color()
    ..strokeWidth = width
    ..style = paintingStyle
    ..isAntiAlias = true // 抗锯齿
    ..strokeCap = StrokeCap.round;
}

// 主题颜色
final ColorScheme colors = theme.colorScheme;

// 获取颜色
Color Function() getColor(String color) {
  // 使用函数是为了在切换深/浅色模式时能切换颜色
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

// 细线
final Paint Function() thinPaint =
    createPaint(width: 1, color: getColor('grey'));
// 更细的线
final Paint Function() finerPaint =
    createPaint(width: 0.25, color: getColor('grey'));
// 主要的线
final Paint Function() painter =
    createPaint(width: 2, color: getColor('primary'));
// 浅色线
final Paint Function() lightPainer =
    createPaint(width: 2, color: getColor('light'));
