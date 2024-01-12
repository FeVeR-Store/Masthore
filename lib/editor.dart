import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_size/flutter_keyboard_size.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:get/get.dart';
import 'package:keyboard_height_plugin/keyboard_height_plugin.dart';
import 'package:latext/latext.dart';
import 'package:masthore/bottom_bar.dart';
import 'package:masthore/libs/expression.dart';
import 'package:masthore/libs/rust_api/libs/expression.dart';

import 'package:masthore/main.dart';
import 'package:flutter_xlider/flutter_xlider.dart';

/* 常量编辑器 */
class Editor extends StatelessWidget {
  const Editor({super.key});
  @override
  Widget build(BuildContext context) {
    // Size size = MediaQuery.of(context).size;
    return GetBuilder<ExpressionController>(
        id: "constant-editor", // 标记id
        init: ExpressionController(), // 表达式controller
        builder: (_) {
          return Padding(
              padding: const EdgeInsets.only(top: 30),
              child: ListView(
                children: [
                  // 函数表达式
                  LatexPanel(exp: _),
                  // 常量列表
                  ..._.expressionContext.constantList.map((e) => ConstantInput(
                      identity: e.identity, value: e.value, constant: e))
                ],
              ));
        });
  }
}

/* 函数表达式 */
class LatexPanel extends StatelessWidget {
  final ExpressionController exp;
  const LatexPanel({super.key, required this.exp});
  @override
  Widget build(BuildContext context) {
    // 传递给底栏本组件的高度，用于计算滑动条的位置
    Get.find<BottomBarController>().getLatexHeight =
        (() => context.size!.height);
    return Center(
        child: exp.expressionContext.expression != null
            // 函数若不为空，则展示函数表达式
            ? LaTexT(
                laTeXCode: Text(
                exp.expressionContext.expression!.latex,
                style: const TextStyle(fontSize: 22),
              ))
            // 若为空，提醒
            : FilledButton.icon(
                icon: const Icon(Icons.keyboard_arrow_left),
                label: const Text("先选择一个函数吧"),
                onPressed: () {
                  // 返回函数选择页面
                  Get.find<BottomBarController>()
                      .changeView(BottomBarView.functionList);
                },
              ));
  }
}

/* 常量输入controller */
class ConstantInputController extends GetxController {
  // 是否显示滑动条
  bool isShowSlider = false;
  // 用于确认改变的常量
  String identity = "";
  // 键盘高度
  double keyboardHeight = 0;
  // 原底栏下降高度，用于在隐藏滑动条时恢复原高度
  double oldGlideHeight = 0;
  // 是否在滑动，用于隐藏底栏，更大范围展示函数图像的变化
  bool isSliding = false;
  // 键盘是否收起（目前没有用到）
  // bool hideKeyboard = true;
  // 当前的聚焦点，用于点击外部时收起键盘，以及活动完毕后重新聚焦（后者在更换滑动条组件后去除，因为新组件不再抢占焦点）
  FocusNode? currentFocusNode;
  @override
  // 初始化
  void onInit() {
    super.onInit();
    // 监听键盘高度变化
    KeyboardHeightPlugin().onKeyboardHeightChanged((height) {
      // 当高度小于已经记录的键盘高度时，表示键盘仍然在弹出
      if (height > keyboardHeight) {
        // 更新键盘高度
        keyboardHeight = height;
      }
      // 如果键盘高度为0，表示键盘已经收起
      if (height == 0) {
        // hideKeyboard = true;
        closeSlider(); // 当键盘收起时，关闭滑动条
      } else {
        // hideKeyboard = false;
      }
    });
  }

  // controller移除时，将聚焦点设为空
  @override
  void onClose() {
    currentFocusNode = null;
    super.onClose();
  }

  // 设置聚焦点
  void setFocusNode(FocusNode node) {
    currentFocusNode = node;
  }

  // 聚焦
  void focusOnTextField() {
    currentFocusNode?.requestFocus();
  }

  // 设置滑动状态
  void setSlidState(bool state) {
    // 是否正在滑动
    if (state != isSliding) {
      isSliding = state;
      // 将底栏设置为透明/取消透明
      Get.find<BottomBarController>().setTransparent(isSliding);
    }
    // 更新视图
    update();
  }

  // 显示滑动条
  void showSlider(String identity, double input, bool noKeyboard) {
    // 获取屏幕尺寸
    MediaQueryData mediaQueryData = MediaQuery.of(globalKey.currentContext!);
    // 如果有键盘并且平台时安卓或ios之一
    if (!noKeyboard &&
        (Platform.isAndroid || Platform.isIOS) &&
        mediaQueryData.viewInsets.bottom == 0) {
      // 使用Future，可以执行延时时停止本次函数，如果不停止就无法再次调用
      Future(() {
        // 如果键盘未弹出，延时200ms后重新执行显示滑动条函数
        if (keyboardHeight == 0) {
          sleep(Durations.short4);
        }
        showSlider(identity, input, noKeyboard);
      });
      // 停止本函数
      return;
    }
    // 设置为当前常量的identity
    this.identity = identity;
    // 表示显示滑动条
    isShowSlider = true;
    // 因为下面要用许多属性，所以储存为临时变量
    BottomBarController bottomBarController = Get.find<BottomBarController>();
    // 设置原底栏下降高度
    oldGlideHeight = bottomBarController.glideHeight;
    // 滑动条高度
    double sliderHeight = 50;
    // 函数表达式的高度
    double latexHeight = bottomBarController.getLatexHeight();
    // 底栏总高度
    double bottomHeight = mediaQueryData.size.height * .7;
    // 底栏按钮区域 = (底栏高度 - 底栏下降高度) - 底栏view高度
    double bottomBarBtnPanelHeight =
        (bottomHeight - bottomBarController.glideHeight) -
            bottomBarController.getSheetChildHeight();
    // 设置下降高度
    bottomBarController.setGlideHeight(bottomHeight -
        ((noKeyboard ? 0 : keyboardHeight) +
            sliderHeight +
            input +
            latexHeight +
            bottomBarBtnPanelHeight +
            40 +
            30 +
            5)); // TODO：魔法数字消除
    update();
  }

  // 关闭滑动条
  void closeSlider() {
    // FocusManager.instance.primaryFocus!.unfocus();
    // currentFocusNode?.unfocus();
    // 恢复原高度
    Get.find<BottomBarController>().setGlideHeight(oldGlideHeight);
    // 重置常量identity
    identity = "";
    // 表示隐藏滑动条
    isShowSlider = false;
    update();
  }
}

/* 常量输入 */
@immutable
class ConstantInput extends StatelessWidget {
  // 常量identity
  final String identity;
  // 常量的值
  final double value;
  // 常量
  final Constant constant;
  const ConstantInput(
      {super.key,
      required this.identity,
      required this.value,
      required this.constant});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ConstantInputController>(
        init: ConstantInputController(), // 常量输入controller
        builder: (_) => !_.isShowSlider // 若不显示滑动条，那么显示输入框
                ||
                _.identity == identity // 如果显示滑动条，那么只显示与滑动条相同identity的输入框
            ? Column(children: [
                Padding(
                    padding: const EdgeInsets.all(20),
                    child: Input(
                      value: value,
                      identity: identity,
                      constantInputController: _,
                      constant: constant,
                    )), // 输入框
                _.isShowSlider && // 如果需要显示滑动条
                        _.identity == identity // 且identity相同，那么就显示滑动条
                    ? ConstantInputSlider(
                        identity: identity,
                        controller: _,
                        value: value,
                        constant: constant,
                      )
                    // 否则不显示
                    : const Divider(
                        color: Colors.transparent,
                        height: 0,
                      )
              ])
            // 不显示
            : const Divider(
                color: Colors.transparent,
                height: 0,
              ));
  }
}

/* 常量滑动条 */
class ConstantInputSlider extends StatelessWidget {
  const ConstantInputSlider(
      {super.key,
      required this.constant,
      required this.value,
      required this.controller,
      required this.identity});
  // 常量的identity
  final String identity;
  // 常量的值
  final double value;
  // 常量
  final Constant constant;
  // 常量输入controller
  final ConstantInputController controller;
  @override
  Widget build(BuildContext context) {
    // ExpressionController
    ExpressionController expressionController =
        Get.find<ExpressionController>();
    // 记录上一次的值
    double oldValue = value;
    // 需要保留的小数位数
    int shouldFixed = constant.step // 常量步长
        .toString() // 转化为字符串
        .split(".") // 从小数点处切割 -> [整数部分, 小数部分]
        [1] // 获取小数部分
        .length; // 小数部分长度，也就是要保留的位数
    return Container(
        height: 50, // 滑动条栏高度50
        decoration: BoxDecoration(
            color: controller.isSliding // 拖动时隐藏滑动条栏（不隐藏滑动条，只隐藏栏）
                ? Colors.transparent
                : theme.colorScheme.onSecondary,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(
                    25))), // 只有滑动条栏上面的部分为圆角，下半部分无圆角，可以和输入法或者控制栏融合
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: GetBuilder<InputController>(
              id: "slider", // 标记id
              init: InputController(), // 输入框controller
              // 滑动条本体
              builder: (inputController) => FlutterSlider(
                    trackBar: const FlutterSliderTrackBar(
                      // 滑动条轨道
                      // 活动部分（已滑过部分）
                      activeTrackBarHeight: 8, // 高度
                      activeTrackBar: BoxDecoration(
                          // 样式
                          borderRadius:
                              BorderRadius.all(Radius.circular(25))), // 圆角
                      // 未活动部分（未滑过部分）
                      inactiveTrackBar:
                          BoxDecoration(color: Colors.transparent), // 透明
                    ),
                    handler: FlutterSliderHandler(
                        child: Container(), // 不需要内容，所以用一个Container
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, // 圆形
                          color: theme.colorScheme.primary, // 颜色
                        )),
                    handlerHeight: 18, // 滑块高度
                    values: [
                      constant.value
                    ], // 默认值，使用数组包裹的原因：这个滑动条组件支持范围滑动，所以可以有多个滑块，数组里的值就是滑块的初始值，一个值表示只有一个滑块
                    // 滑动的步长，即滑动的最小变化值
                    step: FlutterSliderStep(
                        step: constant.step / 5), // 常量步长的五分之一，滑动的精度更高，变化更细腻
                    max: constant.max, // 最大值
                    min: constant.min, // 最小值
                    tooltip: FlutterSliderTooltip(
                        disabled: true), // 不显示滑动时弹出的提示，因为输入框里有值
                    // 滑动时
                    onDragging: (_, value, __) {
                      // 设置正在滑动
                      Get.find<ConstantInputController>().setSlidState(true);
                      // 改变常量的值
                      expressionController.changeConstant(identity, value);
                      // 当值的变化等于或者超过步长时
                      if ((value - oldValue).abs() >= constant.step) {
                        inputController
                                .getTextHandlers(identity, 0)
                                .textEditingController // 获取输入框控制器
                                .text =
                            (value - (value % constant.step)) // 将值设置成最小单位为步长的值
                                .toStringAsFixed(shouldFixed); // 保留小数位数
                        oldValue = value; // 设置旧值
                      }
                    },
                    // 滑动完毕时
                    onDragCompleted: (_, value, ___) {
                      // 设置停止滑动
                      Get.find<ConstantInputController>().setSlidState(false);
                      // 滑动停止时将值设置为最接近当前的最小单位为步长的值
                      inputController
                              .getTextHandlers(identity, 0)
                              .textEditingController
                              .text =
                          (value - (value % constant.step))
                              .toStringAsFixed(shouldFixed);
                    },
                  )),
        ));
  }
}

/* 输入框Handlers，储存一些必备内容 */
class TextFieldHandlers {
  TextFieldHandlers(
      {required this.textEditingController,
      required this.focusNode,
      required this.isReadonly});
  // 输入框控制器
  final TextEditingController textEditingController;
  // 输入框的焦点
  final FocusNode focusNode;
  // 是否只读
  bool isReadonly;
}

/* 输入框controller */
class InputController extends GetxController {
  // 储存所有的输入框handlers
  final Map<String, TextFieldHandlers> _textHandlerMap = {};
  // 通过id获取输入框handlers
  TextFieldHandlers getTextHandlers(String id, double defaultValue) {
    // 若该id还未储存handlers
    if (_textHandlerMap[id] == null) {
      // 那么创建新的handlers
      _textHandlerMap[id] = TextFieldHandlers(
          textEditingController:
              // 输入框的默认值
              TextEditingController(text: defaultValue.toString()),
          focusNode: FocusNode(),
          isReadonly: true);
    }
    return _textHandlerMap[id]!; // 返回handlers
  }

  // 通过id切换是否只读
  void changeReadonly(String id, bool value) {
    if (_textHandlerMap[id] != null) {
      _textHandlerMap[id]!.isReadonly = value;
      update();
    }
  }
}

/* 输入框 */
class Input extends StatelessWidget {
  const Input(
      {super.key,
      required this.value,
      required this.constant,
      required this.identity,
      required this.constantInputController});
  // 值
  final double value;
  // 常量identity
  final String identity;
  // 常量
  final Constant constant;
  // 常量输入controller
  final ConstantInputController constantInputController;
  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: InputController(), // 输入框controller
        builder: (inputController) =>
            // 监听屏幕高度
            Consumer<ScreenHeight>(builder: (context, res, _) {
              // 获取输入框handlers
              TextFieldHandlers textFieldHandlers =
                  inputController.getTextHandlers(identity, value);
              // 焦点
              FocusNode focusNode = textFieldHandlers.focusNode;
              // 输入框控制器
              TextEditingController textController =
                  textFieldHandlers.textEditingController;
              // 旧值
              String oldValue = value.toString();
              return XGestureDetector(
                child: TextField(
                  // 输入框是否只读
                  readOnly: textFieldHandlers.isReadonly,
                  // 焦点
                  focusNode: focusNode,
                  // 控制器
                  controller: textController,
                  // 字体样式
                  style: const TextStyle(fontSize: 20), // 20px
                  // 输入类型为数字，可以让输入法显示数字键盘（但是不能限制只输入数字）
                  keyboardType: TextInputType.number,
                  // 点击外部时
                  onTapOutside: (__) {
                    // 如果显示滑动条但是没有正在滑动
                    if (!constantInputController.isSliding &&
                        constantInputController.isShowSlider) {
                      // 获取点击位置的纵坐标
                      double dy = __.position.dy;
                      // 当纵坐标在滑动栏中时
                      if (dy >
                              res.screenHeight - res.keyboardHeight - 50 - 10 &&
                          dy < res.screenHeight - res.keyboardHeight + 10) {
                        // 请求焦点
                        // focusNode.requestFocus();
                      } else // 不在滑动栏时
                      {
                        // 设置值为当前常量的值（常量的值在滑动时会更新）
                        textController.text = Get.find<ExpressionController>()
                            .getConstantValue(identity)
                            .toString();
                        // 设置为只读
                        inputController.changeReadonly(identity, true);
                        // 关闭滑动条
                        constantInputController.closeSlider();
                      }
                    }
                  },
                  // 输入规则
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                        (RegExp("[(\\-).0-9]"))) // 允许输入：负号（-） 小数点（.） 0 ~ 9
                  ], // 数组，表示输入规则
                  // 输入时
                  onChanged: (value) {
                    // 对负号的处理
                    if (value.indexOf("-") > 1) {
                      // 如果输入的负号不在第一位
                      value = oldValue; // 将值设置为旧值（相当于忽略输入）
                      textController.text = value;
                    }
                    // 对小数点的处理
                    if (value.indexOf(".") != value.lastIndexOf(".")) {
                      // 如果包含两个小数点
                      value = oldValue; // 忽略输入
                      textController.text = value;
                    }
                    // 判断是否合法
                    if (double.tryParse(value) != null) {
                      // 合法
                      double val = double.parse(value);
                      // 判断是否超过允许的常量范围
                      val = val >= constant.max // 若超过最大值
                          ? constant.max // 设置为最大值
                          : (val < constant.min // 若小于最小值
                              ? constant.min // 设置为最小值
                              : val); // 否则不改变值
                      String valString = val.toString(); // 转化为字符串
                      // if (val == double.parse(value)) {
                      // } else { 好像没用
                      // 如果是整数但有小数部分.0，移除
                      textController.text = valString.endsWith(".0")
                          ? valString.replaceFirst(".0", "")
                          : valString;
                      // }
                      // 设置常量的值
                      Get.find<ExpressionController>()
                          .changeConstant(identity, val);
                    }
                    // 设置旧值
                    oldValue = value;
                  },
                  // 输入框样式
                  decoration: InputDecoration(
                    // 输入框前面的部分（xxx = ）
                    prefixIcon: SizedBox(
                        height: 0,
                        width: 72,
                        child: Center(
                            child: Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: LaTexT(
                            laTeXCode: Text("$identity =", // xxx =
                                style: TextStyle(
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400)),
                          ),
                        ))),
                    // 输入框后面的部分（设置为默认值）
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: IconButton(
                          onPressed: () {
                            Get.find<ExpressionController>()
                                .changeConstantToDefault(identity); // 将常量重置为默认值
                            textController.text =
                                Get.find<ExpressionController>()
                                    .getConstantValue(identity)
                                    .toString(); // 将输入框的值设置为默认值
                          },
                          icon: const Icon(Icons.restart_alt_outlined)), // 图标
                    ),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(50))), // 输入框样式：仅显示边框
                  ),
                  // 点击时不显示键盘，只显示滑动条
                  onTap: () {
                    // 通过Future可以让onTap回调结束，但是仍然运行其中的函数（showSlider），当其中有延时时不会导致视图卡住
                    Future(() {
                      // 显示滑动条
                      constantInputController.showSlider(
                          identity, // 常量的identity
                          context.size?.height ?? 100, // 输入框的高，如果为空则返回100
                          true // 不显示键盘
                          );
                    });
                  },
                ),
                // 长按时显示滑动条和键盘，可以输入
                onLongPress: (_) {
                  Future(() {
                    // 设置为可编辑
                    inputController.changeReadonly(identity, false);
                    // 设置焦点
                    Get.find<ConstantInputController>().setFocusNode(focusNode);
                    // 显示滑动条
                    constantInputController.showSlider(
                        identity,
                        context.size?.height ?? 100, // 与点击时相同
                        false // 显示键盘
                        );
                  });
                },
              );
            }));
  }
}
