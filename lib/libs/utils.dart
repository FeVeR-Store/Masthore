import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:latext/latext.dart';
import 'package:masthore/libs/graphics.dart';
import 'package:masthore/libs/painter.dart';

/* 坐标转Offset */
Offset coordinateToOffset(double dx, double dy) {
  return Offset(dx, -dy);
}

/* 矫正y值 */
double reviseY(double y) {
  return -y;
}

/* latex字符串转LaTexT组件 */
LaTexT toLatex(String latex) {
  return LaTexT(laTeXCode: Text(latex));
}

/* 角度转弧度 */
double degreeToRadian(double degree) {
  // 角度转弧度的公式：弧度 = 角度 * (π / 180)
  return degree * (3.141592653589793 / 180.0);
}

/* Canvas拓展 */
extension PaintExtension on Canvas {
  /* 绘制字符 */
  void paintText(String text, Offset postion,
      {TextStyle style = const TextStyle(),
      TextAlign textAlign = TextAlign.right,
      TextDirection direction = TextDirection.ltr}) {
    TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: direction,
    )..layout(maxWidth: 100);
    painter.paint(this, postion);
  }

  /* 绘制Graphics */
  void paintGraphics(List<Graphic> graphicsList) {
    // 遍历GraphicsList
    for (var element in graphicsList) {
      // 通过Graphic类型绘制
      switch (element.type) {
        // 文字
        case GraphicType.text:
          TextGraphicsStyle style = element.textGraphicsStyle!;
          paintText(element.content!, element.point!,
              style: style.textStyle,
              textAlign: style.textAlign,
              direction: style.direction);
          break;
        // Path
        case GraphicType.path:
          drawPath(element.path!, element.paint!());
          break;
        // 直线
        case GraphicType.line:
          drawLine(element.lineStart!, element.lineEnd!, painter());
          break;
        // 点
        case GraphicType.point:
          drawPoints(PointMode.points, element.points!, element.paint!());
          break;
        // 复合Graphics
        case GraphicType.multi:
          paintGraphics(element.graphics!);
          break;
        // 空
        case GraphicType.empty:
          break;
      }
    }
  }
}
