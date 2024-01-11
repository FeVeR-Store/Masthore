import 'package:get/get.dart';
import 'package:masthore/bottom_bar.dart';
import 'package:masthore/graph.dart';
import 'package:masthore/libs/rust_api/api.dart';
import 'package:masthore/libs/rust_api/libs/expression.dart';

class ExpressionContext {
  int id = 1;
  List<ConstantWithDefault> constant;
  Expression? expression;
  ExpressionContext({required this.constant, required this.expression});
}

class ConstantWithDefault extends Constant {
  final double defaultValue;
  ConstantWithDefault(
      {required super.identity,
      required super.value,
      required super.max,
      required super.min,
      required super.step,
      required this.defaultValue});
}

class ExpressionController extends GetxController {
  late ExpressionContext expressionContext =
      ExpressionContext(constant: [], expression: null);

  void graphUpdate() {
    Get.find<GraphController>().graphUpdate();
  }

  void editorUpdate() {
    super.update(["constant-editor"]);
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
    Get.find<BottomBarController>().shrink();
    graphUpdate();
  }
}

extension ConstantExtension on Constant {
  ConstantWithDefault toConstantWithDefault(double? defaultValue) {
    defaultValue ??= value;
    return ConstantWithDefault(
        max: max,
        min: min,
        step: step,
        identity: identity,
        value: value,
        defaultValue: defaultValue);
  }
}
