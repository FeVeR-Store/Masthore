import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:get/get.dart';
import 'package:masthore/bottom_bar.dart';
import 'package:masthore/function_list.dart';
import 'package:masthore/libs/expression.dart';
import 'package:masthore/libs/graphics.dart';
import 'package:masthore/libs/painter.dart';
import 'package:masthore/libs/rust_api.dart';
import 'package:masthore/main.dart';

double scale = 1;

class ExpresionController extends GetxController {}

class GraphController extends GetxController {
  late int id = 1;
  late String str = '';
  late double scale;
  bool isInit = false;
  Offset offset = Offset.zero;
  double xUnitLength = 0;
  double yUnitLength = 0;
  double oldScale = 1;
  double height = 0;
  double width = 0;
  List<Graphics> graphics = [];
  ExpressionContext expressionContext =
      ExpressionContext(constant: [], expression: null);
  BuildContext context = globalKey.currentContext!;
  Size screen = MediaQuery.of(globalKey.currentContext!).size;

  void updateScreen(Size screen) {
    if (screen.width == 0 || screen.height == 0) {
      return;
    }
    this.screen = screen;
    if (!isInit) {
      double height = screen.height;
      double width = screen.width;
      scale = 1;
      if (this.height != height || this.width != width) {
        double length = min(width, height);
        double fr = 7;
        double unitLength = length / fr * scale;
        xUnitLength = unitLength;
        yUnitLength = unitLength;
        this.height = height;
        this.width = width;
      }
      isInit = true;
      offsetChange(Offset(width / 2, (height) / 2));
    }
  }

  void graphUpdate() {
    id++;
    super.update(["graph"]);
  }

  void editorUpdate() {
    super.update(["constant-editor"]);
  }

  void offsetChange(Offset offset) {
    this.offset = offset;
    graphUpdate();
  }

  void resetOldScale() {
    oldScale = 1;
  }

  void scaleChange(double scale, Offset scaleCenter) {
    double $scale = this.scale;
    if (scale > 1 && oldScale < 1) {
      oldScale = 1;
    }
    if (scale < 1 && oldScale > 1) {
      oldScale = 1;
    }
    $scale += (scale - oldScale);
    if ($scale > 0.2 && $scale < 6) {
      double length = min(screen.height, screen.width);
      double fr = 7;
      double unitLength = length / fr * this.scale;
      this.scale = $scale;
      xUnitLength = unitLength * this.scale;
      yUnitLength = xUnitLength;
      double scaleChange = 1 - pow(2, scale - oldScale).toDouble();

      // 缩放中心修正
      // 减去手指缩放中心和缩放中心（原点）的距离与缩放变化的乘积偏移量
      // 抵消掉原有的缩放
      offset -= (offset - scaleCenter) * scaleChange;
      // offset = offset -
      //     Offset(scaleChange * (offset.dx - scaleCenter.dx),
      //         scaleChange * (offset.dy - scaleCenter.dy));
    }
    oldScale = scale;
    graphUpdate();
  }

  void changeConstant(String identity, double value) {
    int oldConstant = expressionContext.constant
        .indexWhere((element) => element.identity == identity);
    if (oldConstant != -1) {
      expressionContext.constant[oldConstant].value = value;
    }
    graphUpdate();
    editorUpdate();
  }

  void changeConstantToDefault(String identity) {
    int constant = expressionContext.constant
        .indexWhere((element) => element.identity == identity);
    ConstantWithDefault target = expressionContext.constant[constant];
    target.value = target.defaultValue;
    graphUpdate();
    editorUpdate();
  }

  void setConstants(List<Constant> constants) {
    constants.sort((a, b) => a.identity.compareTo(b.identity));
    expressionContext.constant =
        constants.map((e) => e.toConstantWithDefault(null)).toList();
    editorUpdate();
  }

  double getConstant(String identity) {
    return expressionContext.constant
        .firstWhere((element) => element.identity == identity)
        .value;
  }

  void changeFunction(Expression expression) {
    expressionContext.expression = expression;
    expressionContext.id++;
    expressionContext.constant.clear();
    Get.find<BottomBarController>().setTop(height * .7 - 95);
    graphUpdate();
  }
}

class Graph extends StatelessWidget {
  const Graph({super.key});
  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return XGestureDetector(
        onMoveUpdate: (MoveEvent details) {
          Get.find<GraphController>()
              .offsetChange(Get.find<GraphController>().offset + details.delta);
        },
        onScaleStart: (__) {
          Get.find<GraphController>().resetOldScale();
        },
        onScaleEnd: () {
          Get.find<GraphController>().resetOldScale();
        },
        onScaleUpdate: (ScaleEvent details) {
          Get.find<GraphController>()
              .scaleChange(details.scale, details.focalPoint);
        },
        child: GetBuilder<GraphController>(
            id: "graph",
            init: GraphController(),
            builder: (_) {
              _.updateScreen(screen);
              double height = screen.height;
              double width = screen.width;
              return GetBuilder<BottomBarController>(
                  init: BottomBarController(),
                  builder: (__) {
                    __.updateScreen(screen);
                    return CustomPaint(
                      isComplex: true,
                      size: Size(width, height),
                      painter: GraphPainter(_, _.offset, _.id, [
                        newGrid(width, height, _.scale, _.offset,
                            min(width, height) / 7 / 5, false, finerPaint),
                        newGrid(width, height, _.scale, _.offset,
                            min(width, height) / 7, true, thinPaint),
                        newAxis(width, height, _.offset, _.xUnitLength,
                            _.yUnitLength),
                        newFunction(_.expressionContext, width, height,
                            _.offset, _.scale)
                      ]),
                    );
                  });
            }));
  }
}

class GraphPainter extends CustomPainter {
  Offset offset;
  int id;
  List<Graphics> graphics;
  GraphPainter(this.controller, this.offset, this.id, this.graphics);
  GraphController controller;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(offset.dx, offset.dy);
    // canvas.scale(controller.scale);
    canvas.paintGraphics(graphics);
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.id != id;
  }
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

  void paintGraphics(List<Graphics> graphicsList) async {
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
