import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:latext/latext.dart';
import 'package:masthore/libs/expression.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExpressionController>(
        id: "constant-editor",
        init: ExpressionController(),
        builder: (_) {
          return Expander(
              header: Text('参数设置'),
              content: SizedBox(
                  height: 300,
                  child: ListView(
                      // controller: ScrollController(),
                      children: _.expressionContext.constantList
                          .map((e) => Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  SizedBox(
                                    child: LaTexT(laTeXCode: Text(e.identity)),
                                    width: 50.0,
                                    height: 50.0,
                                  ),
                                  TextBox(
                                    controller: TextEditingController(),
                                  ),
                                ],
                              ))
                          .toList())));
        });
  }
}
