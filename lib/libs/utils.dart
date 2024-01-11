import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:latext/latext.dart';
import 'package:masthore/libs/graphics.dart';
import 'package:masthore/libs/painter.dart';

Offset coordinateToOffset(double dx, double dy) {
  return Offset(dx, -dy);
}

LaTexT toLatex(String latex) {
  return LaTexT(laTeXCode: Text(latex));
}

extension PaintExtension on Canvas {
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

  void paintGraphics(List<Graphic> graphicsList) async {
    for (var element in graphicsList) {
      switch (element.type) {
        case GraphicsTypes.text:
          TextGraphicsStyle style = element.textGraphicsStyle!;
          paintText(element.content!, element.point!,
              style: style.textStyle,
              textAlign: style.textAlign,
              direction: style.direction);
          break;
        case GraphicsTypes.path:
          drawPath(element.path!, element.paint!());
          break;
        case GraphicsTypes.line:
          drawLine(element.lineStart!, element.lineEnd!, painter());
          break;
        case GraphicsTypes.point:
          drawPoints(PointMode.points, element.points!, element.paint!());
          break;
        case GraphicsTypes.empty:
          break;
        case GraphicsTypes.multi:
          paintGraphics(element.graphics!);
          break;
      }
    }
  }
}
