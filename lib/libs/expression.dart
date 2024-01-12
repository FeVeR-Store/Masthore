import 'package:get/get.dart';
import 'package:masthore/bottom_bar.dart';
import 'package:masthore/graph.dart';
import 'package:masthore/libs/rust_api/api.dart';
import 'package:masthore/libs/rust_api/libs/expression.dart';

/* 表达式上下文 */
class ExpressionContext {
  ExpressionContext({required this.constantList, required this.expression});
  // id，用于确定是否改变了函数
  int id = 1;
  // 常量列表
  List<ConstantWithDefault> constantList; // 或许应该改为Map<identity, ConstantList>
  // 表达式
  Expression? expression;
}

/* 包含默认值的常量 */
class ConstantWithDefault extends Constant {
  ConstantWithDefault(
      {required super.identity,
      required super.value,
      required super.max,
      required super.min,
      required super.step,
      required this.defaultValue});
  // 默认值
  final double defaultValue;
}

/* 表达式controller */
class ExpressionController extends GetxController {
  // 上下文
  late ExpressionContext expressionContext =
      ExpressionContext(constantList: [], expression: null);
  // 更新画布
  void graphUpdate() {
    Get.find<GraphController>().graphUpdate();
  }

  // 更新常量表达式
  void editorUpdate() {
    super.update(["constant-editor"]);
  }

  // 修改常量的值
  void changeConstant(String identity, double value) {
    // 查找此identity对应的常量的索引
    int index = expressionContext.constantList
        .indexWhere((element) => element.identity == identity);
    // 若此常量存在
    if (index != -1) {
      // 设置新值
      expressionContext.constantList[index].value = value;
    }
    graphUpdate();
    editorUpdate();
  }

  // 将常量的值设置为默认值
  void changeConstantToDefault(String identity) {
    // 与上面的类似
    int constant = expressionContext.constantList
        .indexWhere((element) => element.identity == identity);
    ConstantWithDefault target = expressionContext.constantList[constant];
    target.value = target.defaultValue;
    graphUpdate();
    editorUpdate();
  }

  // 设置常量列表
  void setConstantList(List<Constant> constants) {
    // 将常量排序（根据常量的名字）
    constants.sort((a, b) => a.identity.compareTo(b.identity));
    // 将列表的Constant全部转化为ConstantWithDefault，然后设置为常量列表
    expressionContext.constantList =
        constants.map((e) => e.toConstantWithDefault()).toList();
    editorUpdate();
  }

  // 获取常量的值
  double getConstantValue(String identity) {
    return expressionContext.constantList
        .firstWhere((element) => element.identity == identity)
        .value;
  }

  // 改变函数
  void changeFunction(Expression expression) {
    // 设置新的expression
    expressionContext.expression = expression;
    // 更新id
    expressionContext.id++;
    // 清除常量列表
    expressionContext.constantList.clear();
    // 收起底栏
    Get.find<BottomBarController>().shrink();
    graphUpdate();
  }
}

/* Constant拓展 */
extension ConstantExtension on Constant {
  /* 将常量转化为ConstantWithDefault */
  ConstantWithDefault toConstantWithDefault({double? defaultValue}) {
    // 若值为空，那么就用常量本身的值
    defaultValue ??= value;
    // 返回构建的ConstantWithDefault
    return ConstantWithDefault(
        max: max,
        min: min,
        step: step,
        identity: identity,
        value: value,
        defaultValue: defaultValue);
  }
}
