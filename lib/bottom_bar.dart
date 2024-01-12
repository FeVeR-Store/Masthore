import 'package:bottom_bar_with_sheet/bottom_bar_with_sheet.dart';
import 'package:flutter/material.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:get/get.dart';
import 'package:masthore/editor.dart';
import 'package:masthore/function_list.dart';
import 'package:masthore/main.dart';

/* 底栏的两个view */
enum BottomBarView { functionList, constantEditor }

/* 底栏controller */
class BottomBarController extends GetxController {
  // 底栏组件控制器
  late BottomBarWithSheetController bottomBarWithSheetController;
  // 当前视图
  BottomBarView currtentView = BottomBarView.functionList;
  // 滑动累计值，用于实现分段滑动
  double _cumulative = 0;
  // 最小拖动距离，当累计值大于这个距离时就会拖动（在初始化init函数中设置）
  late double minDragDistance;
  // 需要展开的距离，当切换view时的底栏拉起的高度小于这个距离时就会展开
  final double shouldExpandDistance = 200;
  // 设置下降高度
  late double glideHeight;
  // 用于获取底栏内容高度
  late double Function() getSheetChildHeight;
  // 用于储存表达式高度
  late double Function() getLatexHeight;
  // 屏幕尺寸
  late Size _screen;
  // 最小高度，当底栏
  late double _shrinkHeight;
  // 是否透明
  bool transparent = false;

  // 初始化
  @override
  void onInit() {
    super.onInit();
    glideHeight = 0;
    // 创建底栏组件控制器
    bottomBarWithSheetController = BottomBarWithSheetController(
        initialIndex: 0, // 初始index为0
        sheetOpened: true // 展开，实际上并没有采用组件提供的展开收起方法，使用的是自己实现的滑动方法，因此始终展开
        );
  }

  // 初始化
  void init(Size screen) {
    if (screen.width == 0 || screen.height == 0) {
      return;
    }
    // 设置屏幕尺寸
    _screen = screen;
    // 设置最小拖动距离
    minDragDistance = _screen.height * .15;
    // 计算收起底栏时的尺寸
    _shrinkHeight = screen.height * .7 - 95;
  }

  // 收起底栏
  void shrink() {
    setGlideHeight(_shrinkHeight);
  }

  // 展开底栏
  void expand() {
    setGlideHeight(0);
  }

  // 设置透明/取消透明
  void setTransparent(bool state) {
    transparent = state;
    update();
  }

  // 设置下降高度
  void setGlideHeight(double glideHeight) {
    this.glideHeight = glideHeight;
    update();
  }

  // 通过拖拽设置下降高度
  void darg(double y) {
    if (currtentView == BottomBarView.constantEditor // 当view为常量编辑器时
            &&
            // Get.find<ExpressionController>().expressionContext.expression != null // 已经选择函数
            //  &&
            Get.find<ConstantInputController>().isShowSlider // 显示拖动条时不可拖拽
        ) {
      return;
    }
    // 将拖动的距离变化加到累计距离中
    _cumulative += y;
    // 如果拖动距离大于最小拖动距离
    if (_cumulative.abs() > minDragDistance) {
      // 那么更新下降高度
      glideHeight = glideHeight + _cumulative;
      // 如果下降高度大于底栏收起高度，那么就设置为收起的高度，防止显示不全
      if (glideHeight >= _shrinkHeight) {
        glideHeight = _shrinkHeight;
      }
      update();
      // 重置累计高度
      _cumulative = 0;
    }
  }

  // 切换view
  void changeView(BottomBarView view) {
    // 设置当前的view
    currtentView = view;
    // 如果底栏拉起的高度小于shouldExpandDistance就会展开（将下降高度设置为0）
    if (glideHeight >= _shrinkHeight - shouldExpandDistance) {
      glideHeight = 0;
    }
    update();
    // 更新按钮位置
    bottomBarWithSheetController.selectItem(view.index);
  }
}

/* 底栏 */
@immutable
class BottomBar extends StatelessWidget {
  const BottomBar({super.key});
  @override
  Widget build(BuildContext context) {
    // 屏幕尺寸
    Size screen = MediaQuery.sizeOf(context);
    return GetBuilder<BottomBarController>(
        init: BottomBarController(), // 底栏controller
        builder: (_) {
          // 是否透明
          bool transparent = _.transparent;
          return Draggable(
              controller: _, // 传递给拖动组件，用于实现拖动效果
              child: BottomBarWithSheet(
                  curve: Curves.ease, // 拖动时的动画
                  duration: const Duration(milliseconds: 200), // 拖动时的延时
                  controller: _.bottomBarWithSheetController, // 底栏组件控制器
                  // 点击按钮切换时
                  onSelectItem: (int index) {
                    // 如果切换的视图与现在不同
                    if (index != _.currtentView.index) {
                      // 那么就切换视图
                      _.changeView(BottomBarView.values[index]);
                    }
                  },
                  mainActionButtonBuilder: (BuildContext context) {
                    // 这里是一个主按钮，用于实现点击按钮时切换的效果
                    return Column(
                      children: [
                        // 主按钮
                        FilledButton.tonal(
                          // 点击时展开
                          onPressed: () {
                            _.expand();
                          },
                          // 样式
                          style: ButtonStyle(
                            fixedSize: const MaterialStatePropertyAll(
                                Size(72, 18)), // 大小
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.pressed)) {
                                  return theme.colorScheme.onSecondaryContainer
                                      .withAlpha(150); // 按下时的颜色
                                } else if (states
                                    .contains(MaterialState.hovered)) {
                                  return theme.colorScheme.onSecondaryContainer
                                      .withAlpha(200); // hover时的颜色
                                }
                                return transparent // 是否需要透明
                                    ? Colors.transparent // 透明
                                    : theme.colorScheme
                                        .onSecondaryContainer; // 正常的颜色
                              },
                            ),
                          ),
                          // 图标，以及实现了透明
                          child: Icon(
                              color: transparent
                                  ? Colors.transparent
                                  : theme.colorScheme.onSecondary,
                              _.currtentView == BottomBarView.functionList
                                  ? Icons.content_paste_search_outlined
                                  : Icons.edit_document),
                        ),
                        Text(
                          _.currtentView == BottomBarView.functionList
                              ? "函数列表"
                              : "参数设置",
                          style: TextStyle(
                              color: transparent ? Colors.transparent : null),
                        )
                      ],
                    );
                  },
                  // 主按钮样式
                  mainActionButtonTheme: MainActionButtonTheme(
                      size: 50, // 大小
                      transform: Matrix4.translationValues(
                          ((screen.width + 60) / 4) *
                              (_.currtentView == BottomBarView.functionList
                                  ? 1
                                  : -1),
                          0,
                          0)), // 位置变换，用于实现按钮点击切换效果
                  // 底栏内容
                  sheetChild: SheetChild(
                    controller: _,
                  ),
                  // 自动关闭，不需要，因为我们使用自己实现的拖动效果
                  autoClose: false,
                  // 底栏样式
                  bottomBarTheme: BottomBarTheme(
                      mainButtonPosition:
                          _.currtentView == BottomBarView.functionList
                              ? MainButtonPosition.left
                              : MainButtonPosition.right, // 切换主按钮位置，配合位置变换
                      heightClosed: 90, // 关闭时的高度，也就是收起时底栏高度
                      heightOpened: screen.height * .7 -
                          _.glideHeight, // 展开时的高度，也就是原高度减去下降高度
                      selectedItemIconColor: Colors
                          .transparent, // 选中的按钮颜色，因为我们使用主按钮实现切换效果，因此yinchang
                      itemIconColor: transparent
                          ? Colors.transparent
                          : null, // 未选中的按钮，如果不是透明就使用默认颜色
                      contentPadding:
                          const EdgeInsets.only(top: 15), // 与底栏内容隔开一定距离
                      decoration: BoxDecoration(
                          color: transparent // 还是透明效果
                              ? Colors.transparent
                              : theme.colorScheme.secondaryContainer,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(25)))), // 顶栏圆角
                  // 按钮的图标，只能是两个，多了会错位
                  items: const [
                    BottomBarWithSheetItem(
                        icon: Icons.content_paste_search_outlined), // 函数列表图标
                    BottomBarWithSheetItem(icon: Icons.edit_document) // 常量编辑器图标
                  ]));
        });
  }
}

/* 拖拽组件 */
class Draggable extends StatelessWidget {
  const Draggable({super.key, required this.child, required this.controller});
  // 内容
  final Widget child;
  // 底栏controller
  final BottomBarController controller;
  @override
  Widget build(BuildContext context) {
    return XGestureDetector(
        // 监听拖动
        onMoveUpdate: (MoveEvent event) {
          // 调用底栏拖拽
          controller.darg(event.delta.dy);
        },
        child: child);
  }
}

/* 底栏内容 */
class SheetChild extends StatelessWidget {
  const SheetChild({super.key, required this.controller});
  // 底栏controller
  final BottomBarController controller;
  @override
  Widget build(BuildContext context) {
    // 设置底栏内容高度，用于计算滑动条位置
    controller.getSheetChildHeight = (() => context.size!.height);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
          color: controller.transparent // 透明实现
              ? Colors.transparent
              : theme.colorScheme.secondaryContainer,
          child: controller.currtentView == BottomBarView.functionList
              ? FunctionList()
              : const Editor() // view切换实现
          ),
    );
  }
}
