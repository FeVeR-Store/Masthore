import 'package:bottom_bar_with_sheet/bottom_bar_with_sheet.dart';
import 'package:flutter/material.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:get/get.dart';
import 'package:masthore/editor.dart';
import 'package:masthore/function_list.dart';
import 'package:masthore/libs/expression.dart';
import 'package:masthore/main.dart';

enum BottomBarView { functionList, constantEditor }

class BottomBarController extends GetxController {
  late BottomBarWithSheetController controller;
  int currtentView = 0;
  double cumulative = 0;
  double itemBarHeight = 0;
  late double glideHeight;
  late double Function() getSheetChildHeight;
  late double Function() getLatexHeight;
  late double Function() getSliderHeight;
  late Size screen;
  late double _minHeight;
  bool transparent = false;

  @override
  void onInit() {
    super.onInit();
    glideHeight = 0;
    controller =
        BottomBarWithSheetController(initialIndex: 0, sheetOpened: true);
  }

  void init(Size screen) {
    if (screen.width == 0 || screen.height == 0) {
      return;
    }
    this.screen = screen;
    _minHeight = screen.height * .7 - 95;
  }

  void shrink() {
    setGlideHeight(_minHeight);
  }

  void setTransparent(bool state) {
    transparent = state;
    update();
  }

  void setGlideHeight(double top) {
    this.glideHeight = top;
    update();
  }

  void setGetBottomBarChildHeight(double Function() getSheetChildHeight) {
    this.getSheetChildHeight = getSheetChildHeight;
  }

  void setGetLatexHeight(double Function() getLatexHeight) {
    this.getLatexHeight = getLatexHeight;
  }

  void setGetSliderHeight(double Function() getSliderHeight) {
    this.getSliderHeight = getSliderHeight;
  }

  void changeTopByDrag(double y) {
    if (currtentView != 0 &&
        Get.find<ExpressionController>().expressionContext.expression != null &&
        Get.find<ConstantInputController>().isShowSlider) {
      return;
    }
    cumulative += y;
    if (cumulative.abs() > screen.height * .15) {
      glideHeight = glideHeight + cumulative;
      if (glideHeight >= _minHeight) {
        glideHeight = _minHeight;
      }
      update();
      cumulative = 0;
    }
  }

  void changeView(BottomBarView view) {
    currtentView = view.index;
    if (glideHeight >= _minHeight - 200) {
      glideHeight = 0;
    }
    update();
    controller.selectItem(view.index);
  }
}

@immutable
class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    return GetBuilder<BottomBarController>(
        init: BottomBarController(),
        builder: (BottomBarController _) {
          bool transparent = _.transparent;
          return Draggable(
              controller: _,
              child: BottomBarWithSheet(
                  curve: Curves.ease,
                  controller: _.controller,
                  onSelectItem: (int id) {
                    if (id != _.currtentView) {
                      _.changeView(BottomBarView.values[id]);
                    } else {
                      _.setGlideHeight(0);
                    }
                  },
                  duration: const Duration(milliseconds: 200),
                  mainActionButtonBuilder: (BuildContext context) {
                    return Column(
                      children: [
                        FilledButton.tonal(
                          onPressed: () {
                            _.setGlideHeight(0);
                          },
                          style: ButtonStyle(
                            fixedSize:
                                const MaterialStatePropertyAll(Size(72, 18)),
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.pressed)) {
                                  return theme.colorScheme.onSecondaryContainer
                                      .withAlpha(150);
                                } else if (states
                                    .contains(MaterialState.hovered)) {
                                  return theme.colorScheme.onSecondaryContainer
                                      .withAlpha(200);
                                }
                                return transparent
                                    ? Colors.transparent
                                    : theme.colorScheme
                                        .onSecondaryContainer; // Use the component's default.
                              },
                            ),
                          ),
                          child: Icon(
                              color: transparent
                                  ? Colors.transparent
                                  : theme.colorScheme.onSecondary,
                              _.currtentView == 0
                                  ? Icons.content_paste_search_outlined
                                  : Icons.edit_document),
                        ),
                        Text(
                          _.currtentView == 0 ? "函数列表" : "参数设置",
                          style: TextStyle(
                              color: transparent ? Colors.transparent : null),
                        )
                      ],
                    );
                  },
                  sheetChild: SheetChild(
                    controller: _,
                  ),
                  autoClose: false,
                  mainActionButtonTheme: MainActionButtonTheme(
                      size: 50,
                      transform: Matrix4.translationValues(
                          ((size.width + 60) / 4) *
                              (_.currtentView == 0 ? 1 : -1),
                          0,
                          0)),
                  bottomBarTheme: BottomBarTheme(
                      mainButtonPosition: _.currtentView == 0
                          ? MainButtonPosition.left
                          : MainButtonPosition.right,
                      heightClosed: 90,
                      heightOpened: size.height * .7 - _.glideHeight,
                      selectedItemIconColor: Colors.transparent,
                      itemIconColor: transparent ? Colors.transparent : null,
                      contentPadding: const EdgeInsets.only(top: 15),
                      decoration: BoxDecoration(
                          color: transparent
                              ? Colors.transparent
                              : theme.colorScheme.secondaryContainer,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(25)))),
                  items: const [
                    BottomBarWithSheetItem(
                        icon: Icons.content_paste_search_outlined),
                    BottomBarWithSheetItem(icon: Icons.edit_document)
                  ]));
        });
  }
}

class Draggable extends StatelessWidget {
  final Widget child;
  final BottomBarController controller;
  const Draggable({super.key, required this.child, required this.controller});
  @override
  Widget build(BuildContext context) {
    return XGestureDetector(
        onMoveUpdate: (MoveEvent event) {
          controller.changeTopByDrag(event.delta.dy);
        },
        child: child);
  }
}

class SheetChild extends StatelessWidget {
  final BottomBarController controller;
  const SheetChild({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    controller.setGetBottomBarChildHeight(() => context.size!.height);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
          color: controller.transparent
              ? Colors.transparent
              : theme.colorScheme.secondaryContainer,
          child:
              controller.currtentView == 0 ? FunctionList() : const Editor()),
    );
  }
}
