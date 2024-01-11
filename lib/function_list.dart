import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latext/latext.dart';
import 'package:masthore/libs/expression.dart';
import 'package:masthore/libs/rust_api/api.dart';
import 'package:masthore/libs/utils.dart';

// 标星函数
class MarkedItem {
  // 函数名称（唯一），用于确定函数
  final String name;
  // 函数表达式，chip中显示的内容
  final String latex;
  MarkedItem(this.name, this.latex);
}

// 用于储存表达式
final List<Expression> _expressionList = [];

/* 标星函数controller */
class MarkedItemController extends GetxController {
  // 存储
  final GetStorage box = GetStorage();
  // 获取函数列表
  List<Expression> expressions = _expressionList;
  // 标星函数的列表
  late List<dynamic> markedItems = box.read("markedItem") ?? [];

  // 添加标星函数
  void addMarkedItem(MarkedItem item) {
    // 添加
    markedItems.add({"name": item.name, "latex": item.latex});
    // 先更新视图，否则视图会卡顿
    update();
    // 然后持久储存
    box.write("markedItem", markedItems);
  }

  // 删除标星函数
  void removeMarkedItem(String name) {
    // 通过name查出标星的函数，移除
    markedItems.removeWhere((element) => element["name"] == name);
    // 更新视图并持久储存
    update();
    box.write("markedItem", markedItems);
  }

  // 通过name获取函数
  Expression getExpression(String name) =>
      expressions.firstWhere((element) => element.name == name);
  // 通过name查询是否标星
  bool isMarked(String name) =>
      markedItems.any((element) => element["name"] == name);
}

/* 标星函数栏 */
class MarkedItemBar extends StatelessWidget {
  const MarkedItemBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GetBuilder<MarkedItemController>(
        init: MarkedItemController(), // controller
        builder: (_) => SizedBox(
            height: 40, // 栏高40px
            child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20), // 左右各20px
                child: ListView(
                  scrollDirection: Axis.horizontal, // 横向（水平）排列
                  children: _.markedItems // 内容（所有标星函数）
                      .map(
                        (e) => Padding(
                            padding: const EdgeInsets.only(right: 10), // 隔开标星函数
                            child: GestureDetector(
                                onLongPress: () {
                                  _.removeMarkedItem(e['name']!); // 长按时取消标星
                                },
                                // 主体
                                child: ActionChip(
                                  onPressed: () {
                                    Get.find<ExpressionController>()
                                        .changeFunction(_.getExpression(
                                            e['name']!)); // 点击时切换至这个标星函数
                                  },
                                  // 圆角
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  // 内容，标星函数的latex表达式
                                  label: LaTexT(
                                    laTeXCode: Text(
                                      e['latex']!,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ))),
                      )
                      .toList(), // 将iter转化为list
                ))));
  }
}

/* 展开列表controller */
class ExpandedController extends GetxController {
  // 记录各列表的展开情况
  final Map<int, bool> _isExpanded = {};
  // 添加列表
  void add(int index) {
    _isExpanded[index] ??= false;
  }

  // 展开与收缩
  void expand(int index) {
    _isExpanded[index] = !_isExpanded[index]!;
    update();
  }

  // 确定是否展开
  bool isExpanded(int index) => _isExpanded[index] ?? false;
}

/* 展开列表 */
class ExpandedList extends StatelessWidget {
  const ExpandedList(
      {super.key,
      required this.id,
      required this.title,
      required this.description,
      required this.expressions});
  // 用于确定展开列表
  final int id;
  // 标题
  final Widget title;
  // 描述
  final String description;
  // 内容
  final List<Expression> expressions;
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExpandedController>(
        init: ExpandedController(), // 展开列表controller
        builder: (_) {
          _.add(id); // 记录
          return Material(
              color: Colors.transparent,
              // 点击水波效果
              child: InkWell(
                child: Column(
                  children: [
                    ListTile(
                      // 展开和收起时的图标
                      leading: Icon(
                          size: 40,
                          _.isExpanded(id)
                              ? Icons.keyboard_arrow_down_outlined
                              : Icons.keyboard_arrow_right_outlined),
                      title: title,
                      subtitle: Text(description),
                      onTap: () {
                        _.expand(id); // 点击时切换展开和收起
                      },
                    ),
                    // 展开后显示内容
                    ...(_.isExpanded(id)
                        ? expressions.map(
                            (e) => Padding(
                              // 向右移动40，添加深度
                              padding: const EdgeInsets.only(left: 40),
                              // 单条函数
                              child: SingleExpression(expression: e),
                            ),
                          )
                        : [])
                  ],
                ),
              ));
        });
  }
}

/* 单条函数 */
class SingleExpression extends StatelessWidget {
  const SingleExpression({super.key, required this.expression});
  // 通过Express获取内容
  final Expression expression;
  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        // 水波
        child: InkWell(
            onTap: () {
              Get.find<ExpressionController>().changeFunction(expression);
            },
            child: ListTile(
              leading: CircleAvatar(
                child: Text(expression.avatar),
              ),
              // 使用latex表达式
              title: toLatex(expression.latex), // 把latex字符串转化为LaTeX组件
              subtitle: Text(expression.description), // 描述
              trailing: SizedBox.square(
                  // 正方形，边长为45px
                  dimension: 45,
                  child: GetBuilder<MarkedItemController>(
                      init: MarkedItemController(), // 标星函数controller
                      builder: (markedItemController) {
                        bool isMarked = markedItemController
                            .isMarked(expression.name); // 判断是否标星
                        return IconButton(
                            // 点击标星/取消
                            onPressed: () {
                              if (isMarked) {
                                markedItemController
                                    .removeMarkedItem(expression.name);
                              } else {
                                markedItemController.addMarkedItem(MarkedItem(
                                    expression.name, expression.latex));
                              }
                            },
                            // 图标
                            icon: Icon(
                                size: 28,
                                isMarked
                                    ? Icons.star // 标星时为填充的星
                                    : Icons.star_border_outlined) // 未标星时只有边框
                            );
                      })),
              isThreeLine: true,
            )));
  }
}

/* 函数列表 */
class FunctionList extends StatelessWidget {
  FunctionList({super.key});
  // 通过native的getFunctions获取所有的函数
  final List<ExpressionList> expressionList = getFunctions();
  @override
  Widget build(BuildContext context) {
    int index = 0;
    return ListView(children: [
      // 标星函数栏
      const MarkedItemBar(),
      // 函数列表
      ...expressionList.map((ExpressionList expreesionList) {
        // 单独一条函数（根据函数列表是否为空）
        if (expreesionList.list.isEmpty) {
          // 将ExpressionList转为Expression
          Expression expression = Expression(
              avatar: expreesionList.avatar,
              latex: expreesionList.latex,
              description: expreesionList.description,
              name: expreesionList.name);
          // 保存到函数列表中，用于标星函数
          _expressionList.add(expression);
          // 返回单条函数
          return SingleExpression(expression: expression);
        } else {
          // 否则即是可折叠的函数列表
          return ExpandedList(
              id: index++,
              // 折叠列表的标题
              title: Text(expreesionList.name),
              // 折叠列表的描述
              description: expreesionList.description,
              // 折叠列表的内容，即包含的函数
              expressions: expreesionList.list.map((expression) {
                // 把列表的所有函数保存到函数列表中
                _expressionList.add(expression);
                return expression;
              }).toList() // 把iter转化为list
              );
        }
      }).toList() // 把iter转化为list
    ]);
  }
}
