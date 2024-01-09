import 'package:masthore/function_list.dart';
import 'package:masthore/libs/rust_api.dart';

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
