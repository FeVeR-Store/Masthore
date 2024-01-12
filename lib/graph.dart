import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:get/get.dart';
import 'package:masthore/bottom_bar.dart';
import 'package:masthore/libs/expression.dart';
import 'package:masthore/libs/graphics.dart';
import 'package:masthore/libs/painter.dart';
import 'package:masthore/libs/utils.dart';

// 画布controller
class GraphController extends GetxController {
  // 画布id，用于更新画布
  int id = 1;
  // 是否初始化
  bool _isInit = false;
  // 缩放，初始值为1 这个值是根据是通过缩放的变化来更新的
  double currentScale = 1;
  // 最大缩放与最小缩放
  final double _minScale = 0.2;
  final double _maxScale = 6;
  // 记录上一次的缩放量，用于计算缩放变化
  double _oldScale = 1;
  // 偏移量，初始值为(dx=0,dy=0)
  Offset offset = Offset.zero;
  // x轴单位长度
  double xUnitLength = 0;
  // y轴单位长度
  double yUnitLength = 0;
  // 屏幕高度
  double _height = 0;
  // 屏幕宽度
  double _width = 0;
  // 初始时较窄边的格子数
  double fr = 7;
  // graphics图像列表，graph会画出所有Graphic类的元素
  // List<Graphic> graphics = []; // TODO：把graphics转移到graphController中

  /* 初始化，获取屏幕的宽高并计算单位长度 */
  void init(Size screen) {
    // 若为(0,0)，表示尚未准备好，直接return
    if (screen.width == 0 || screen.height == 0) {
      return;
    }
    // 未初始化时
    if (!_isInit) {
      // 临时保存
      double height = screen.height;
      double width = screen.width;
      // 若值相同，忽略
      if (_height != height || _width != width) {
        /* 计算单位长度 */

        // 取屏幕较窄的一边
        double length = min(width, height);

        // 单位长度为较窄边的 fr/1
        double unitLength = length / fr * currentScale;

        // x轴和y轴的单位长度相等
        xUnitLength = unitLength;
        yUnitLength = unitLength;
        // 更新屏幕长度
        _height = height;
        _width = width;
      }
      _isInit = true;
      // 初始化偏移量，使坐标原点位于屏幕中心
      offsetChange(Offset(width / 2, (height) / 2));
    }
  }

  void calcUnitLength() {
    double length = min(_height, _width);
    double unitLength = length / fr;
    xUnitLength = unitLength * currentScale;
    yUnitLength = xUnitLength;
  }

  /* 更新画布 */
  void graphUpdate() {
    id++; // 注意要更新id
    super.update(["graph"]); // 只更新画布
  }

  /* 更新常量编辑器 */
  void editorUpdate() {
    super.update(["constant-editor"]); // 只更新常量编辑器
  }

  /* 修改偏移量，用于拖动和修补缩放中心 */
  void offsetChange(Offset offset) {
    this.offset = offset;
    graphUpdate();
  }

  /* 重置oldScale，在缩放方向改变时调用 */
  void resetOldScale() {
    _oldScale = 1;
  }

  /* 修改缩放 */
  void scaleChange(double newScale, Offset scaleCenter) {
    // 记录currentScale
    double scale = currentScale;
    // 当缩放方向改变时重置oldScale
    if (newScale > 1 && _oldScale < 1 || newScale < 1 && _oldScale > 1) {
      resetOldScale();
    }
    // 计算当前的缩放
    scale += (newScale - _oldScale);

    // 如果当前缩放不在支持的缩放的范围内，忽略
    if (!(scale > _minScale && scale < _maxScale)) return;

    // 设置缩放
    currentScale = scale;
    // 计算新的单位长度
    calcUnitLength();

    /* 修正原缩放中心至真正缩放中心 */

    // 首先计算缩放的实际改变量
    double scaleChange = 1 - pow(2, newScale - _oldScale).toDouble();
    // 然后计算原缩放中心与实际缩放中心的距离，并乘以缩放的改变量，这就是实际缩放中心被推开的距离
    Offset offsetChange = (offset - scaleCenter) * scaleChange;
    // 最后将偏移量减去被推开的距离即可修正
    offset -= offsetChange;
    _oldScale = newScale;
    graphUpdate();
  }
}

/* 画布 */
class Graph extends StatelessWidget {
  const Graph({super.key});
  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽高
    Size screen = MediaQuery.of(context).size;
    return XGestureDetector(
        /* 监听拖动 */
        onMoveUpdate: (MoveEvent details) {
          Get.find<GraphController>()
              .offsetChange(Get.find<GraphController>().offset + details.delta);
        },
        /* 在缩放开始时重置oldScale */
        onScaleStart: (__) {
          Get.find<GraphController>().resetOldScale();
        },
        /* 监听缩放 */
        onScaleUpdate: (ScaleEvent details) {
          Get.find<GraphController>()
              .scaleChange(details.scale, details.focalPoint);
        },
        child: GetBuilder<GraphController>(
            id: "graph", // 标记id，可以指定id来只更新该组件
            init: GraphController(), // 指定控制器
            builder: (graph) {
              // 初始化GraphController
              graph.init(screen);
              double height = screen.height;
              double width = screen.width;
              return GetBuilder<ExpressionController>(
                  init: ExpressionController(),
                  builder: (exp) => GetBuilder<BottomBarController>(
                      init: BottomBarController(),
                      builder: (bottomBar) {
                        // 初始化BottomBarController
                        bottomBar.init(screen);
                        return CustomPaint(
                          isComplex: true, // 表示是复杂图像
                          size: screen, // 设置画布大小
                          // 通过Graphics进行绘制
                          painter: GraphPainter(graph.offset, graph.id, [
                            // 绘制细网格，比网格密5被
                            newGrid(
                                width: width,
                                height: height,
                                scale: graph.currentScale,
                                offset: graph.offset,
                                gridWidth: min(width, height) / graph.fr / 5,
                                withTick: false,
                                paint: finerPaint),
                            // 绘制网格以及坐标
                            newGrid(
                                width: width,
                                height: height,
                                scale: graph.currentScale,
                                offset: graph.offset,
                                gridWidth: min(width, height) / graph.fr,
                                withTick: true, // 绘制坐标
                                paint: thinPaint),
                            // 绘制坐标和箭头
                            newAxis(
                                width: width,
                                height: height,
                                offset: graph.offset,
                                xUnitLength: graph.xUnitLength,
                                yUnitLength: graph.yUnitLength),
                            // 绘制函数图像
                            newFunction(
                                context: exp.expressionContext,
                                width: width,
                                height: height,
                                offset: graph.offset,
                                fr: graph.fr,
                                scale: graph.currentScale)
                          ]),
                        );
                      }));
            }));
  }
}

/* 绘制器 */
class GraphPainter extends CustomPainter {
  // 偏移量
  Offset offset;
  // 用于确定是否更新图像
  int id;
  // 绘制内容
  List<Graphic> graphics;
  // 构造函数
  GraphPainter(this.offset, this.id, this.graphics);
  @override
  // 绘制函数
  void paint(Canvas canvas, Size size) {
    // 偏移量
    canvas.translate(offset.dx, offset.dy);
    // 绘制
    canvas.paintGraphics(graphics);
  }

  @override
  // 是否重绘
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.id != id;
  }
}
