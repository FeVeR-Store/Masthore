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
import 'package:masthore/libs/rust_api.dart';
import 'package:masthore/main.dart';
import 'package:flutter_xlider/flutter_xlider.dart';

class Editor extends StatelessWidget {
  const Editor({super.key});
  @override
  Widget build(BuildContext context) {
    // Size size = MediaQuery.of(context).size;
    return GetBuilder<ExpressionController>(
        id: "constant-editor",
        init: ExpressionController(),
        builder: (_) {
          return Padding(
              padding: const EdgeInsets.only(top: 30),
              child: ListView(
                // controller: ScrollController(),
                children: [
                  EditorLatexPanel(exp: _),
                  ..._.expressionContext.constant.map((e) => ConstantInput(
                      identity: e.identity, value: e.value, constant: e))
                ],
              ));
        });
  }
}

class EditorLatexPanel extends StatelessWidget {
  final ExpressionController exp;
  const EditorLatexPanel({super.key, required this.exp});
  @override
  Widget build(BuildContext context) {
    Get.find<BottomBarController>()
        .setGetLatexHeight(() => context.size!.height);
    return Center(
        child: exp.expressionContext.expression != null
            ? LaTexT(
                laTeXCode: Text(
                exp.expressionContext.expression!.latexString,
                style: const TextStyle(fontSize: 22),
              ))
            : FilledButton.icon(
                icon: const Icon(Icons.keyboard_arrow_left),
                label: const Text("先选择一个函数吧"),
                onPressed: () {
                  Get.find<BottomBarController>().changeView(0);
                },
              ));
  }
}

class ConstantInputController extends GetxController {
  bool showSlider = false;
  String identity = "";
  double keyboardHeight = 0;
  double oldBottomBarTop = 0;
  bool isSliding = false;
  bool hideKeyboard = true;
  FocusNode? currentFocusNode;
  @override
  void onInit() {
    super.onInit();
    KeyboardHeightPlugin().onKeyboardHeightChanged((height) {
      if (height > keyboardHeight) {
        keyboardHeight = height;
      }
      if (height == 0) {
        hideKeyboard = true;
        closeSlider();
      }
    });
  }

  @override
  void onClose() {
    currentFocusNode = null;
    super.onClose();
  }

  void setFocusNode(FocusNode node) {
    currentFocusNode = node;
  }

  void focusOnTextField() {
    currentFocusNode?.requestFocus();
  }

  void setSlidState(bool state) {
    isSliding = state;
    update();
    Get.find<BottomBarController>().setTransparent(isSliding);
  }

  void changeShowSlider(String identity, double input, bool noKeyboard) {
    MediaQueryData mediaQueryData = MediaQuery.of(globalKey.currentContext!);
    if (!noKeyboard &&
        (Platform.isAndroid || Platform.isIOS || Platform.isFuchsia) &&
        mediaQueryData.viewInsets.bottom == 0) {
      Future(() {
        if (keyboardHeight == 0) {
          sleep(Durations.short4);
        }
        changeShowSlider(identity, input, noKeyboard);
      });
      return;
    }
    this.identity = identity;
    showSlider = true;
    BottomBarController bottomBarController = Get.find<BottomBarController>();
    oldBottomBarTop = bottomBarController.top;
    // double keyBoardHeight = mediaQueryData.viewInsets.bottom;
    double sliderHeight = 50;
    double latexHeight = bottomBarController.getLatexHeight();
    double sheetBarHeight = mediaQueryData.size.height * .7;
    double sheetItemHeight = (sheetBarHeight - bottomBarController.top) -
        bottomBarController.getSheetChildHeight();
    bottomBarController.setTop(sheetBarHeight -
        ((noKeyboard ? 0 : keyboardHeight) +
            sliderHeight +
            input +
            latexHeight +
            sheetItemHeight +
            40 +
            30 +
            5));
    update();
  }

  void closeSlider() {
    FocusManager.instance.primaryFocus!.unfocus();
    currentFocusNode?.unfocus();
    Get.find<BottomBarController>().setTop(oldBottomBarTop);
    identity = "";
    showSlider = false;
    update();
  }
}

@immutable
class ConstantInput extends StatelessWidget {
  final String identity;
  final double value;
  final Constant constant;
  const ConstantInput(
      {super.key,
      required this.identity,
      required this.value,
      required this.constant});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ConstantInputController>(
        init: ConstantInputController(),
        builder: (_) => !_.showSlider || _.identity == identity
            ? Column(children: [
                Padding(
                    padding: const EdgeInsets.all(20),
                    child: Input(
                      value: value,
                      identity: identity,
                      constantInputController: _,
                      constant: constant,
                    )),
                _.showSlider && _.identity == identity
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
                      constantInputController.changeShowSlider(
                          identity, context.size?.height ?? 100, true);
                    });
                  },
                  onTapOutside: (__) {
                    if (!constantInputController.isSliding &&
                        constantInputController.showSlider) {
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
                    constantInputController.changeShowSlider(
                        identity, context.size?.height ?? 100, false);
                  });
                },
              );
            }));
  }
}
