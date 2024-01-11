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
                  ..._.expressionContext.constant.map((e) => ConstantInput(
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
    Get.find<BottomBarController>()
        .setGetLatexHeight(() => context.size!.height);
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
        builder: (_) =>
            !_.isShowSlider || _.identity == identity // 若没有显示滑动条，那么显示
                ? Column(children: [
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: Input(
                          value: value,
                          identity: identity,
                          constantInputController: _,
                          constant: constant,
                        )),
                    _.isShowSlider && _.identity == identity
                        ? ConstantInputSlider(
                            identity: identity,
                            controller: _,
                            value: value,
                            constant: constant,
                          )
                        : const Divider(
                            color: Colors.transparent,
                            height: 0,
                          )
                  ])
                : const Divider(
                    color: Colors.transparent,
                    height: 0,
                  ));
  }
}

class ConstantInputSlider extends StatelessWidget {
  const ConstantInputSlider(
      {super.key,
      required this.constant,
      required this.value,
      required this.controller,
      required this.identity});
  final double value;
  final Constant constant;
  final ConstantInputController controller;
  final String identity;
  @override
  Widget build(BuildContext context) {
    Get.find<BottomBarController>()
        .setGetSliderHeight(() => context.size!.height);
    ExpressionController expressionController =
        Get.find<ExpressionController>();
    double oldValue = value;
    int toFixed = constant.step.toString().split(".")[1].length;
    return Container(
        height: 50,
        decoration: BoxDecoration(
            color: controller.isSliding
                ? Colors.transparent
                : theme.colorScheme.onSecondary,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(25))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: GetBuilder<InputController>(
              id: "slider",
              init: InputController(),
              builder: (inputController) => FlutterSlider(
                  trackBar: const FlutterSliderTrackBar(
                      activeTrackBarHeight: 8,
                      inactiveTrackBar:
                          BoxDecoration(color: Colors.transparent),
                      activeTrackBar: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(25)))),
                  tooltip: FlutterSliderTooltip(disabled: true),
                  handlerHeight: 18,
                  handler: FlutterSliderHandler(
                      child: Container(),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                      )),
                  values: [constant.value],
                  onDragCompleted: (_, value, ___) {
                    // Get.find<ConstantInputController>().focusOnTextField();
                    Get.find<ConstantInputController>().setSlidState(false);
                    inputController
                            .getTextHandlers(identity, 0)
                            .textEditingController
                            .text =
                        (value - (value % constant.step))
                            .toStringAsFixed(toFixed);
                  },
                  onDragging: (_, value, __) {
                    Get.find<ConstantInputController>().setSlidState(true);
                    expressionController.changeConstant(identity, value);
                    if ((value - oldValue).abs() >= constant.step) {
                      inputController
                              .getTextHandlers(identity, 0)
                              .textEditingController
                              .text =
                          (value - (value % constant.step))
                              .toStringAsFixed(toFixed);
                      oldValue = value;
                    }
                  },
                  step: FlutterSliderStep(step: constant.step / 5),
                  max: constant.max,
                  min: constant.min)),
        ));
  }
}

class TextFieldHandlers {
  final TextEditingController textEditingController;
  final FocusNode focusNode;
  bool isReadonly;
  TextFieldHandlers(
      {required this.textEditingController,
      required this.focusNode,
      required this.isReadonly});
}

class InputController extends GetxController {
  Map<String, TextFieldHandlers> textControllerList = {};
  TextFieldHandlers getTextHandlers(String id, double defaultValue) {
    if (textControllerList[id] == null) {
      textControllerList[id] = TextFieldHandlers(
          textEditingController:
              TextEditingController(text: defaultValue.toString()),
          focusNode: FocusNode(),
          isReadonly: true);
    }
    return textControllerList[id]!;
  }

  void changeReadonly(String id, bool value) {
    if (textControllerList[id] != null) {
      textControllerList[id]!.isReadonly = value;
      update();
    }
  }
}

class Input extends StatelessWidget {
  const Input(
      {super.key,
      required this.value,
      required this.constant,
      required this.identity,
      required this.constantInputController});
  final double value;
  final String identity;
  final ConstantInputController constantInputController;
  final Constant constant;
  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: InputController(),
        builder: (inputController) =>
            Consumer<ScreenHeight>(builder: (context, res, _) {
              TextFieldHandlers textFieldHandlers =
                  inputController.getTextHandlers(identity, value);
              FocusNode focusNode = textFieldHandlers.focusNode;
              TextEditingController textController =
                  textFieldHandlers.textEditingController;
              String oldValue = value.toString();
              return XGestureDetector(
                child: TextField(
                  readOnly: textFieldHandlers.isReadonly,
                  focusNode: focusNode,
                  controller: textController,
                  style: const TextStyle(fontSize: 20),
                  keyboardType: TextInputType.number,
                  // enabled: false,
                  onTap: () {
                    Future(() {
                      // Get.find<ConstantInputController>()
                      //     .setFocusNode(focusNode);
                      constantInputController.showSlider(
                          identity, context.size?.height ?? 100, true);
                    });
                  },
                  onTapOutside: (__) {
                    if (!constantInputController.isSliding &&
                        constantInputController.isShowSlider) {
                      double dy = __.position.dy;
                      if (dy >
                              res.screenHeight - res.keyboardHeight - 50 - 10 &&
                          dy < res.screenHeight - res.keyboardHeight + 10) {
                        focusNode.requestFocus();
                      } else {
                        textController.text = Get.find<ExpressionController>()
                            .getConstant(identity)
                            .toString();
                        inputController.changeReadonly(identity, true);
                        constantInputController.closeSlider();
                      }
                    }
                  },
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow((RegExp("[(\\-).0-9]")))
                  ],
                  onChanged: (value) {
                    // 对负号的处理
                    if (value.indexOf("-") > 1) {
                      value = oldValue;
                      textController.text = value;
                    }
                    // 对小数点的处理
                    if (value.indexOf(".") != value.lastIndexOf(".")) {
                      value = oldValue;
                      textController.text = value;
                    }
                    // 判断是否合法
                    if (double.tryParse(value) != null) {
                      double val = double.parse(value);
                      val = val >= constant.max
                          ? constant.max
                          : (val < constant.min ? constant.min : val);
                      String valString = val.toString();
                      if (val == double.parse(value)) {
                      } else {
                        textController.text = valString.endsWith(".0")
                            ? valString.replaceFirst(".0", "")
                            : valString;
                      }
                      Get.find<ExpressionController>()
                          .changeConstant(identity, val);
                    }
                    oldValue = value;
                  },
                  decoration: InputDecoration(
                    prefixIcon: SizedBox(
                        height: 0,
                        width: 72,
                        child: Center(
                            child: Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: LaTexT(
                            laTeXCode: Text("$identity =",
                                style: TextStyle(
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400)),
                          ),
                        ))),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: IconButton(
                          onPressed: () {
                            Get.find<ExpressionController>()
                                .changeConstantToDefault(identity);
                            textController.text =
                                Get.find<ExpressionController>()
                                    .getConstant(identity)
                                    .toString();
                          },
                          icon: const Icon(Icons.restart_alt_outlined)),
                    ),
                    // contentPadding: EdgeInsets.only(left: 25),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                  ),
                ),
                onLongPress: (_) {
                  Future(() {
                    inputController.changeReadonly(identity, false);
                    Get.find<ConstantInputController>().setFocusNode(focusNode);
                    constantInputController.showSlider(
                        identity, context.size?.height ?? 100, false);
                  });
                },
              );
            }));
  }
}
