import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masthore/bottom_bar.dart';
import 'package:masthore/libs/expression.dart';
import 'package:masthore/libs/painter.dart';

import 'package:masthore/libs/rust_api/api.dart';
import 'package:masthore/libs/rust_api/libs/expression.dart';
import 'package:masthore/libs/utils.dart';
import 'package:masthore/main.dart';

/* 所有的Graphic类型 */
enum GraphicType { text, path, line, point, empty, multi }

// 用于确认是否更新函数
int oldId = 0;

// 渲染时的长度转数学计算时的长度
double renderLengthToMathLength(double renderLength, double unitLength) {
  return renderLength / unitLength;
}

// 数学计算时的长度转渲染时的长度
double mathLengthToRenderLength(double mathLength, double unitLength) {
  return mathLength * unitLength;
}

/* 绘制函数图像 */
Graphic newFunction(
    {required ExpressionContext context, // 上下文
    required double width, // 屏幕宽
    required double height, // 屏幕高
    required Offset offset, // 偏移量
    required double fr, // 初始时较窄边的格子数
    required double scale // 放大倍数
    }) {
  // 放大程度为 2^(实际正常缩放-1)
  scale = pow(2, (scale - 1)).toDouble();
  // 单位长度
  double unitLength = min(width, height) / fr * scale;
  double xUnitLength = unitLength;
  double yUnitLength = unitLength;
  // 这个值用于tan之类的函数图像，当函数的图像的两个值差别极大时从连线改为移动，防止绘制错误图像 TODO：需要改进
  double discontinuityThreshold =
      renderLengthToMathLength(height, yUnitLength) * scale; // 将渲染的长度转化为计算时用的长度
  double stepLength = 1 / width; // 步长，也就是计算的精度
  double xMin = renderLengthToMathLength(-offset.dx, xUnitLength); // 最小值
  double xMax =
      renderLengthToMathLength(-offset.dx + width, xUnitLength); // 最大值
  if (context.expression == null) {
    // cacheController.reset();
    return empty();
  }
  Path path = Path(); // 创建图像的path
  // 传递给rust进行计算
  CalcReturnForDart calcReturnForDart = draw(
      func: context.expression!.name, // 函数唯一的名字
      // 变量构建器
      variableBuilder: VariableBuilder(
          identity: "x", // 变量名
          uninitialized: false, // 保留字段，目前未使用
          min: xMin, // 最小值
          max: xMax, // 最大值
          step: stepLength, // 步长（精度）
          value: 0 // 值，这里的值其实没有用，真正的值会在rust中计算
          ),
      constantProvider: context.constantList, // 常量列表
      changeContext: oldId != context.id // 是否更新上下文
      );
  // 第一次执行时会返回常量列表，之后就返回空列表
  if (calcReturnForDart.constants.isNotEmpty) {
    // 当返回常量列表时，设置常量列表
    Get.find<ExpressionController>()
        .setConstantList(calcReturnForDart.constants);
    // 设置oldId
    oldId = context.id;
  }
  // 计算的结果
  List<double> result = calcReturnForDart.result;
  // 将画笔移动到屏幕最左侧的图像开头
  path.moveTo(
      -offset.dx, // 横坐标
      mathLengthToRenderLength(
          reviseY(result.first), // 矫正y值
          yUnitLength));
  double currentX = xMin; // 当前的横坐标
  double previousY = result.first; // 之前的纵坐标
  // 遍历结果，将结果绘制成图像
  for (int i = 0; i < result.length; i++) {
    // 移动横坐标
    currentX += stepLength;
    // 获取对应的纵坐标
    double y = result[i];
    if (y.isNaN) {
      continue; // 如果是非数字（无解之类的情况），跳过
    }
    // 当横坐标和纵坐标差别巨大时
    if ((y - previousY).abs() > discontinuityThreshold) {
      // 移动笔触
      path.moveTo(mathLengthToRenderLength(currentX, xUnitLength),
          mathLengthToRenderLength(reviseY(y), yUnitLength));
    } else {
      // 否则连线
      path.lineTo(mathLengthToRenderLength(currentX, xUnitLength),
          mathLengthToRenderLength(reviseY(y), yUnitLength));
    }
    // 更新之前的纵坐标
    previousY = y;
  }
  // 返回Path Graphic
  return newPath(path, painter);
}

/* 绘制箭头 */
Graphic newArrow(double degree, Offset position, Paint paint) {
  // 画出箭头
  Path path = Path()
    ..moveTo(-5, -10)
    ..lineTo(0, 0)
    ..lineTo(5, -10);
  // 旋转
  Matrix4 z = Matrix4.rotationZ(degreeToRadian(degree + 180));
  // 定位
  Matrix4 r = Matrix4.translationValues(position.dx, position.dy, 0);
  // 将旋转和定位效果合并
  r.multiply(z);
  // 将效果应用到箭头上
  path = path.transform(r.storage);
  return newPath(path, painter);
}

// const double appbarHeight = 56;

// 判断能不能被列表中素数整除
bool isNotMultipleOfPrimes(double magnification) {
  // 这个列表很长，请把它折叠，里面是200以内的部分素数
  List<int> primes = [
    3,
    5,
    7,
    11,
    13,
    17,
    19,
    23,
    29,
    31,
    37,
    41,
    43,
    47,
    53,
    59,
    61,
    67,
    71,
    73,
    79,
    83,
    89,
    97,
    101,
    103,
    107,
    109,
    113,
    127,
    131,
    137,
    139,
    149,
    151,
    157,
    163,
    167,
    173,
    179,
    181,
    191,
    193,
    197,
    199
  ];
  // 遍历，如果 magnification 是任何一个素数的倍数，则返回 false
  for (int prime in primes) {
    if (magnification % prime == 0) {
      return false;
    }
  }
  // 如果 magnification 不是任何素数的倍数，则返回 true
  return true;
}

// 查找合适的放大倍数
double findMagnification(double magnification) {
  // 如果放大倍数小于0，直接返回
  if (magnification < 0) {
    return magnification;
  } // 如果放大倍数为1或2时，直接返回
  else if (magnification == 1 || magnification == 2) {
    return magnification;
  } // 如果放大倍数可被2或4整除，并且不能被素数整除，直接返回
  else if (magnification % 2 == 0 &&
      magnification % 4 == 0 &&
      isNotMultipleOfPrimes(magnification)) {
    return magnification;
  } // 否则将放大倍数减一，再次代入
  else {
    return findMagnification(magnification - 1);
  }
}

/* 绘制网格 */
Graphic newGrid(
    {required double width,
    required double height,
    required double scale,
    required Offset offset,
    required double gridWidth,
    required bool withTick, // 是否绘制坐标刻度
    required Paint Function() paint}) {
  final double statusBarHeight =
      MediaQuery.of(globalKey.currentContext!).padding.top; // 状态栏的高度

  double bottomBarHeight;
  if (Platform.isWindows) {
    // 如果为windows平台，那么就没有底栏高度
    bottomBarHeight = 0;
  } else {
    // 如果是其他平台
    BottomBarController bottomBarController = Get.find<BottomBarController>();
    bottomBarHeight = bottomBarController.transparent
        ? 0 // 如果底栏透明，那么底栏高度为0
        : height * .7 - bottomBarController.glideHeight; // 否则就为底栏的高度
  }

  Path path = Path(); // 创建网格的Path
  // ..moveTo(0, height / 2); // 将画笔移动到网格
  double $gridWidth = gridWidth; // 保留网格宽度
  scale = pow(2, (scale - 1)).toDouble(); // 计算出真正的放大倍数
  gridWidth *= scale; // 放大后的网格宽度
  // 将网格宽度设置转化为放大倍数1~1.5倍之间
  while (gridWidth > $gridWidth * 2) {
    gridWidth /= 2;
  }
  while (gridWidth < $gridWidth) {
    gridWidth *= 2;
  }
  // Graphics列表，因为Graphic会堆叠，所以让网格在坐标刻度之下
  List<Graphic> list = [Graphic(type: GraphicType.path)];
  // 放大倍数
  int magnification = scale.floor();
  // 将画笔移动到坐标原点
  path.moveTo(0, 0);
  double currentPostion = 0; // 绘制时的位置
  // x 负半轴 竖线
  for (int i = 0;
      currentPostion < width + offset.dx;
      currentPostion += gridWidth, i--) // 从坐标轴开始，画到屏幕左侧
  {
    path.moveTo(offset.dx - currentPostion, 0); // 移动画笔
    path.lineTo(offset.dx - currentPostion, offset.dy.abs() + height); // 画线
    // 绘制刻度
    if (withTick && i != 0) {
      // 不写0
      String tick =
          (i / findMagnification(magnification.toDouble())).toString(); // 刻度值
      list.add(newText(
          tick, // 刻度值
          // coordinateToOffset用于转化坐标
          coordinateToOffset(
            -currentPostion + 5, // 横坐标
            (offset.dy < statusBarHeight // 如果刻度被状态栏挡住
                ? offset.dy - statusBarHeight // 就刻度移动到状态栏之下
                : offset.dy > height - bottomBarHeight - 20 // 如果刻度被底栏挡住
                    ? offset.dy - height + bottomBarHeight + 20 // 就移动到底栏之上
                    : 0 // 否则不移动
            ),
          ),
          textGraphicsStyle() // 文字样式，默认
          ));
    }
  }
  currentPostion = 0; // 重置绘制时的位置
  // x 正半轴 竖线 与上面的类似
  for (int i = 0;
      currentPostion < width - offset.dx;
      currentPostion += gridWidth, i++) {
    path.moveTo(offset.dx + currentPostion, 0);
    path.lineTo(offset.dx + currentPostion, offset.dy.abs() + height);
    if (withTick && i != 0) {
      String tick =
          (i / findMagnification(magnification.toDouble())).toString();
      list.add(newText(
          tick,
          coordinateToOffset(
            currentPostion + 5,
            (offset.dy < statusBarHeight
                ? offset.dy - statusBarHeight
                : offset.dy > height - bottomBarHeight - 20
                    ? offset.dy - height + bottomBarHeight + 20
                    : 0),
          ),
          textGraphicsStyle()));
    }
  }
  currentPostion = 0;
  // y 正半轴 横线
  for (int i = 0;
      currentPostion < height + offset.dy;
      currentPostion += gridWidth, i++) // 从坐标轴开始，画到屏幕顶部
  {
    path.moveTo(0, offset.dy - currentPostion);
    path.lineTo(width + offset.dx.abs(), offset.dy - currentPostion);
    if (withTick) {
      if (i == 0) {
        // 刻度0
        if (offset.dx >= -10) {
          list.add(newText(
              "0", coordinateToOffset(5, currentPostion), textGraphicsStyle()));
        }
      } else {
        String tick =
            (i / findMagnification(magnification.toDouble())).toString();
        list.add(newText(
            tick,
            coordinateToOffset(
                5 +
                    (offset.dx < 0
                        ? -offset.dx
                        : offset.dx > width - 20
                            ? -offset.dx +
                                width -
                                25 -
                                tick.length * 3.5 // 根据刻度的字数来偏移
                            : 0),
                currentPostion),
            textGraphicsStyle()));
      }
    }
  }
  currentPostion = 0;
  // y 负半轴 横线
  for (int i = 0;
      currentPostion < height - offset.dy;
      currentPostion += gridWidth, i--) {
    path.moveTo(0, offset.dy + currentPostion);
    path.lineTo(width + offset.dx.abs(), offset.dy + currentPostion);
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
              -currentPostion),
          textGraphicsStyle()));
    }
  }

  // 移动(-offset.dx, -offset.dy, 0)
  path = path
      .transform(Matrix4.translationValues(-offset.dx, -offset.dy, 0).storage);
  list[0]
    ..paint = paint
    ..path = path; // 将paint和path代入网格Graphic中
  return newMulti(list);
}

/* 绘制坐标轴 */
Graphic newAxis(
    {required double width,
    required double height,
    required Offset offset,
    required double xUnitLength,
    required double yUnitLength}) {
  Path path = Path()
    ..moveTo(-width - offset.dx, 0)
    ..lineTo(width - offset.dx, 0) // 绘制x轴
    ..moveTo(0, height - offset.dy)
    ..lineTo(0, -height - offset.dy) // 绘制y轴
    ..moveTo(width / 2 - 10 + (width / 2 - offset.dx), 5)
    ..relativeLineTo(10, -5)
    ..relativeLineTo(-10, -5) // x轴箭头
    ..moveTo(-5, -height / 2 + 10 - (offset.dy - height / 2))
    ..relativeLineTo(5, -10)
    ..relativeLineTo(5, 10); // y轴箭头
  return newPath(path, lightPainer);
}

// 默认字体样式
TextGraphicsStyle textGraphicsStyle() {
  return TextGraphicsStyle(
      textStyle: TextStyle(
          color: Theme.of(globalKey.currentContext!).brightness ==
                  Brightness.light // 根据深色/浅色模式变色
              ? Colors.black // 浅色模式 -> 黑色
              : Colors.white // 深色模式 -> 白色
          ));
}

/* 字体样式 */
class TextGraphicsStyle {
  TextGraphicsStyle(
      {this.textStyle = const TextStyle(),
      this.textAlign = TextAlign.right,
      this.direction = TextDirection.ltr});
  // 字体样式
  TextStyle textStyle;
  // 字体对齐方式
  TextAlign textAlign;
  // 字体方向
  TextDirection direction;
}

/* Graphic */
class Graphic {
  Graphic({
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
  // Graphic类型
  final GraphicType type;
  // Paint
  Paint Function()? paint;

/* --- 文字 --- */
  // 内容
  String? content;
  // 字体样式
  TextGraphicsStyle? textGraphicsStyle;
  // 坐标
  Offset? point;

/* --- Path --- */
  // Path
  Path? path;

/* --- 直线 --- */
  // 起始坐标
  Offset? lineStart;
  // 终止坐标
  Offset? lineEnd;

/* --- 点 --- */
  // 点列表
  List<Offset>? points;

/* --- 复合Graphic --- */
  // Graphic列表
  List<Graphic>? graphics;
}

/* 基础Graphic */

/* 绘制文字 */
Graphic newText(
    String content, Offset point, TextGraphicsStyle textGraphicsStyle) {
  return Graphic(
      type: GraphicType.text,
      content: content,
      point: point,
      textGraphicsStyle: textGraphicsStyle);
}

/* 绘制直线 */
Graphic newLine(Offset start, Offset end) {
  return Graphic(type: GraphicType.line, lineStart: start, lineEnd: end);
}

/* 绘制Path */
Graphic newPath(Path path, Paint Function() paint) {
  return Graphic(type: GraphicType.path, path: path, paint: paint);
}

/* 绘制点 */
Graphic newPoints(List<Offset> points, Paint Function() paint) {
  return Graphic(type: GraphicType.point, points: points, paint: paint);
}

/* 绘制复合Graphic */
Graphic newMulti(List<Graphic> graphics) {
  return Graphic(type: GraphicType.multi, graphics: graphics);
}

/* 空 */
Graphic empty() {
  return Graphic(type: GraphicType.empty);
}
