import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masthore/bottom_bar.dart';
import 'package:masthore/graph.dart';
import 'package:masthore/libs/expression.dart';
import 'package:masthore/libs/painter.dart';
import 'package:masthore/libs/rust_api.dart';
import 'package:masthore/libs/utils.dart';
import 'package:masthore/main.dart';

enum GraphicsTypes { text, path, line, point, empty, multi }

double reviseY(double y) {
  return -y;
}

int oldId = 0;

class Range {
  double min;
  double max;
  Range(this.min, this.max);
}

Graphics newFunction(ExpressionContext context, double width, double height,
    Offset offset, double scale) {
  scale = pow(2, (scale - 1)).toDouble();
  double unitLength = min(width, height) / 7 * scale;
  double xUnitLength = unitLength;
  double yUnitLength = unitLength;
  double discontinuityThreshold = height / yUnitLength * scale;
  double stepLength = 1 / width;
  double xMin = -offset.dx / xUnitLength;
  double xMax = (-offset.dx + width) / xUnitLength;
  Path path = Path();
  if (context.expression == null) {
    // cacheController.reset();
    return empty();
  }
  CalcReturnForDart calcReturnForDart = api.draw(
      func: context.expression!.name,
      variableBuilder: VariableBuilder(
          identity: "x",
          uninitialized: false,
          min: xMin,
          max: xMax,
          step: stepLength,
          value: 0),
      constantProvider: context.constant,
      changeContext: oldId != context.id);
  if (calcReturnForDart.constants.isNotEmpty) {
    Get.find<GraphController>().setConstants(calcReturnForDart.constants);
    oldId = context.id;
  }
  List<double> result = calcReturnForDart.result;
  path.moveTo(-offset.dx, reviseY(result.first) * yUnitLength);
  double currentX = xMin;
  double previousY = result.first;
  for (int i = 0; i < result.length; i++) {
    currentX += stepLength;
    double y = result[i];
    if (y.isNaN) {
      continue;
    }
    if ((y - previousY).abs() > discontinuityThreshold) {
      path.moveTo(currentX * xUnitLength, reviseY(y * yUnitLength));
    } else {
      path.lineTo(currentX * xUnitLength, reviseY(y * yUnitLength));
    }
    previousY = y;
  }
  return newPath(path, painter);
}

double degreeToRadian(double degree) {
  // 角度转弧度的公式：弧度 = 角度 * (π / 180)
  return degree * (3.141592653589793 / 180.0);
}

Graphics newArrow(double degree, Offset position, Paint paint) {
  Path path = Path()
    ..moveTo(-5, -10)
    ..lineTo(0, 0)
    ..lineTo(5, -10);
  Matrix4 z = Matrix4.rotationZ(degreeToRadian(degree + 180));
  Matrix4 r = Matrix4.translationValues(position.dx, position.dy, 0);
  r.multiply(z);
  path = path.transform(r.storage);
  return newPath(path, painter);
}

const double appbarHeight = 56;

double findMagnification(double magnification) {
  if (magnification < 0) {
    // if (magnification>=0.2&&magnification<0.5){
    //   return 0.5;
    // }
    return magnification;
  } else if (magnification == 1 || magnification == 2) {
    return magnification;
  } else if (magnification % 2 == 0 &&
      magnification % 4 == 0 &&
      magnification % 3 != 0 &&
      magnification % 5 != 0 &&
      magnification % 7 != 0 &&
      magnification % 11 != 0 &&
      magnification % 13 != 0 &&
      magnification % 17 != 0 &&
      magnification % 19 != 0 &&
      magnification % 23 != 0 &&
      magnification % 29 != 0 &&
      magnification % 31 != 0 &&
      magnification % 37 != 0 &&
      magnification % 41 != 0 &&
      magnification % 43 != 0 &&
      magnification % 47 != 0 &&
      magnification % 53 != 0 &&
      magnification % 59 != 0 &&
      magnification % 61 != 0 &&
      magnification % 67 != 0 &&
      magnification % 71 != 0 &&
      magnification % 73 != 0 &&
      magnification % 79 != 0 &&
      magnification % 83 != 0 &&
      magnification % 89 != 0 &&
      magnification % 97 != 0 &&
      magnification % 101 != 0 &&
      magnification % 103 != 0 &&
      magnification % 107 != 0 &&
      magnification % 109 != 0 &&
      magnification % 113 != 0 &&
      magnification % 127 != 0 &&
      magnification % 131 != 0 &&
      magnification % 137 != 0 &&
      magnification % 139 != 0 &&
      magnification % 149 != 0 &&
      magnification % 151 != 0 &&
      magnification % 157 != 0 &&
      magnification % 163 != 0 &&
      magnification % 167 != 0 &&
      magnification % 173 != 0 &&
      magnification % 179 != 0 &&
      magnification % 181 != 0 &&
      magnification % 191 != 0 &&
      magnification % 193 != 0 &&
      magnification % 197 != 0 &&
      magnification % 199 != 0) {
    return magnification;
  } else {
    return findMagnification(magnification - 1);
  }
}

Graphics newGrid(double width, double height, double scale, Offset offset_,
    double gridWidth, bool withTick, Paint Function() paint) {
  final double statusBarHeight =
      MediaQuery.of(globalKey.currentContext!).padding.top;
  // final double operationBarHeight =
  //     MediaQuery.of(globalKey.currentContext!).padding.bottom;

  final safeAreaHeight = height;
  // - appbarHeight- operationBarHeight;
  double bottomBarHeight;
  if (!Platform.isWindows) {
    BottomBarController bottomBarController = Get.find<BottomBarController>();
    bottomBarHeight = bottomBarController.transparent
        ? 0
        : height * .7 - bottomBarController.top;
  } else {
    bottomBarHeight = 0;
  }
  Path path = Path()..moveTo(0, height / 2);
  double $offset = 0;
  // scale = scale % 1 + 1;
  Offset offset = offset_;
  double $gridWidth = gridWidth;
  // gridWidth /= ((scale - scale % 1) - 1);
  scale = pow(2, (scale - 1)).toDouble();
  gridWidth *= scale;
  while (gridWidth > $gridWidth * 2) {
    gridWidth /= 2;
  }
  while (gridWidth < $gridWidth) {
    gridWidth *= 2;
  }
  List<Graphics> list = [Graphics(type: GraphicsTypes.path)];

  int magnification = scale.floor();
  path.moveTo(0, 0);
  // x 负半轴
  for (int i = 0; $offset < width + offset.dx; $offset += gridWidth, i--) {
    path.moveTo(offset.dx - $offset, 0);
    path.lineTo(offset.dx - $offset, offset.dy.abs() + height);
    if (withTick && i != 0) {
      String tick =
          (i / findMagnification(magnification.toDouble())).toString();
      list.add(newText(
          tick,
          coordinateToOffset(
            -$offset + 5,
            (offset.dy < statusBarHeight
                ? offset.dy - statusBarHeight
                : offset.dy > safeAreaHeight - bottomBarHeight - 20
                    ? offset.dy - safeAreaHeight + bottomBarHeight + 20
                    : 0),
          ),
          textGraphicsStyle()));
    }
  }
  $offset = 0;
  // x 正半轴
  for (int i = 0; $offset < width - offset.dx; $offset += gridWidth, i++) {
    path.moveTo(offset.dx + $offset, 0);
    path.lineTo(offset.dx + $offset, offset.dy.abs() + height);
    if (withTick && i != 0) {
      String tick =
          (i / findMagnification(magnification.toDouble())).toString();
      list.add(newText(
          tick,
          coordinateToOffset(
            $offset + 5,
            (offset.dy < statusBarHeight
                ? offset.dy - statusBarHeight
                : offset.dy > safeAreaHeight - bottomBarHeight - 20
                    ? offset.dy - safeAreaHeight + bottomBarHeight + 20
                    : 0),
          ),
          textGraphicsStyle()));
    }
  }
  $offset = 0;
  // y 正半轴
  for (int i = 0; $offset < height + offset.dy; $offset += gridWidth, i++) {
    path.moveTo(0, offset.dy - $offset);
    path.lineTo(width + offset.dx.abs(), offset.dy - $offset);
    if (i == 0) {
      if (offset.dx >= -10) {
        list.add(
            newText("0", coordinateToOffset(5, $offset), textGraphicsStyle()));
      }
    } else if (withTick) {
      String tick =
          (i / findMagnification(magnification.toDouble())).toString();
      list.add(newText(
          tick,
          coordinateToOffset(
              5 +
                  (offset.dx < 0
                      ? -offset.dx
                      : offset.dx > width - 20
                          ? -offset.dx + width - 25 - tick.length * 3.5
                          : 0),
              $offset),
          textGraphicsStyle()));
    }
  }
  $offset = 0;
  // y 负半轴
  for (int i = 0; $offset < height - offset.dy; $offset += gridWidth, i--) {
    path.moveTo(0, offset.dy + $offset);
    path.lineTo(width + offset.dx.abs(), offset.dy + $offset);
    if (withTick && i != 0) {
      String tick =
          (i / findMagnification(magnification.toDouble())).toString();
      list.add(newText(
          tick,
          coordinateToOffset(
              5 +
                  (offset.dx < 0
                      ? -offset.dx
                      : offset.dx > width - 20
                          ? -offset.dx + width - 25 - tick.length * 3.5
                          : 0),
              -$offset),
          textGraphicsStyle()));
    }
  }

  path = path
      .transform(Matrix4.translationValues(-offset.dx, -offset.dy, 0).storage);
  list[0]
    ..paint = paint
    ..path = path;
  return newMulti(list);
}

Graphics newAxis(double width, double height, Offset offset, double xUnitLength,
    double yUnitLength) {
  Path path = Path()
    ..moveTo(-width - offset.dx, 0)
    ..lineTo(width - offset.dx, 0)
    ..moveTo(0, height - offset.dy)
    ..lineTo(0, -height - offset.dy)
    ..moveTo(width / 2 - 10 + (width / 2 - offset.dx), 5)
    ..relativeLineTo(10, -5)
    ..relativeLineTo(-10, -5)
    ..moveTo(-5, -height / 2 + 10 - (offset.dy - height / 2))
    ..relativeLineTo(5, -10)
    ..relativeLineTo(5, 10);
  return newPath(path, lightPainer);
}

TextGraphicsStyle textGraphicsStyle() {
  return TextGraphicsStyle(
      textStyle: TextStyle(
          color:
              Theme.of(globalKey.currentContext!).brightness == Brightness.light
                  ? Colors.black
                  : Colors.white));
}

class TextGraphicsStyle {
  TextStyle textStyle;
  TextAlign textAlign;
  TextDirection direction;
  TextGraphicsStyle(
      {this.textStyle = const TextStyle(),
      this.textAlign = TextAlign.right,
      this.direction = TextDirection.ltr});
}

class Graphics {
  final GraphicsTypes type;
  String? content;
  TextGraphicsStyle? textGraphicsStyle;
  Path? path;
  Offset? lineStart;
  Offset? lineEnd;
  Offset? point;
  Paint Function()? paint;
  List<Offset>? points;
  List<Graphics>? graphics;
  Graphics({
    required this.type,
    this.paint,
    this.content,
    this.textGraphicsStyle,
    this.lineEnd,
    this.lineStart,
    this.path,
    this.point,
    this.points,
    this.graphics,
  });
}

Graphics newText(
    String content, Offset point, TextGraphicsStyle textGraphicsStyle) {
  return Graphics(
      type: GraphicsTypes.text,
      content: content,
      point: point,
      textGraphicsStyle: textGraphicsStyle);
}

Graphics newLine(Offset start, Offset end) {
  return Graphics(type: GraphicsTypes.line, lineStart: start, lineEnd: end);
}

Graphics newPath(Path path, Paint Function() paint) {
  return Graphics(type: GraphicsTypes.path, path: path, paint: paint);
}

Graphics newPoints(List<Offset> points, Paint Function() paint) {
  return Graphics(type: GraphicsTypes.point, points: points, paint: paint);
}

Graphics newMulti(List<Graphics> graphics) {
  return Graphics(type: GraphicsTypes.multi, graphics: graphics);
}

Graphics empty() {
  return Graphics(type: GraphicsTypes.empty);
}
