import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latext/latext.dart';
import 'package:masthore/libs/expression.dart';
import 'package:masthore/libs/rust_api.dart';
import 'package:masthore/main.dart';

final List<Expression> expressionList = [];

class MarkedItem {
  final String name;
  final String latex;
  MarkedItem(this.name, this.latex);
}

class MarkedItemController extends GetxController {
  final GetStorage box = GetStorage();
  List<Expression> expressions = expressionList;
  late List<dynamic> markedItems = box.read("markedItem") ?? [];

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      update();
    };
  }

  void addMarkedItem(MarkedItem item) {
    markedItems.add({"name": item.name, "latex": item.latex});
    update();
    box.write("markedItem", markedItems);
  }

  void removeMarkedItem(String name) {
    markedItems.removeWhere((element) => element["name"] == name);
    update();
    box.write("markedItem", markedItems);
  }

  Expression getExpression(String name) =>
      expressions.firstWhere((element) => element.name == name);
  bool isMarked(String name) =>
      markedItems.any((element) => element["name"] == name);
}

class FunctionList extends StatelessWidget {
  FunctionList({super.key});
  final List<SampleListForDart> sampleListForDart = api.getSampleForDart();
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExpandedController>(
        init: ExpandedController(),
        builder: (_) {
          return ListView(children: [
            const MarkedItemBar(),
            ...sampleListForDart.map((SampleListForDart sampleList) {
              if (sampleList.list.isEmpty) {
                Expression expression = Expression(
                    avatar: sampleList.avater,
                    latexString: sampleList.latex,
                    laTexT: LaTexT(laTeXCode: Text(sampleList.latex)),
                    description: sampleList.description,
                    name: sampleList.label);
                expressionList.add(expression);
                return SingleExpression(expression: expression);
              } else {
                return ExpandedList(
                    title: Text(sampleList.label),
                    description: sampleList.description,
                    expressions: sampleList.list.map((e) {
                      Expression expression = Expression(
                          description: e.description,
                          avatar: e.avater,
                          latexString: e.latex,
                          laTexT: LaTexT(laTeXCode: Text(e.latex)),
                          name: e.label);
                      expressionList.add(expression);
                      return expression;
                    }).toList());
              }
            }).toList()
          ]);
        });
  }
}

class MarkedItemBar extends StatelessWidget {
  const MarkedItemBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GetBuilder<MarkedItemController>(
        init: MarkedItemController(),
        builder: (_) => SizedBox(
            height: 40,
            child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _.markedItems
                      .map(
                        (e) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                                onLongPress: () {
                                  _.removeMarkedItem(e['name']!);
                                },
                                child: ActionChip(
                                  onPressed: () {
                                    Get.find<ExpressionController>()
                                        .changeFunction(
                                            _.getExpression(e['name']!));
                                  },
                                  // padding: const EdgeInsets.all(),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  label: LaTexT(
                                    laTeXCode: Text(
                                      e['latex']!,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ))),
                      )
                      .toList(),
                ))));
  }
}

class ExpandedController extends GetxController {
  bool isExpaneded = false;
  void expand() {
    isExpaneded = !isExpaneded;
    update();
  }
}

class Expression {
  final String name;
  final String latexString;
  final LaTexT laTexT;
  final String avatar;
  const Expression(
      {required this.avatar,
      required this.laTexT,
      required this.name,
      this.description,
      required this.latexString});
  final String? description;
}

class ExpandedList extends StatelessWidget {
  const ExpandedList(
      {super.key,
      required this.title,
      required this.description,
      required this.expressions});
  final Widget title;
  final String description;
  final List<Expression> expressions;
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExpandedController>(
      init: ExpandedController(),
      builder: (_) => Material(
          color: Colors.transparent,
          child: InkWell(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                      size: 40,
                      _.isExpaneded
                          ? Icons.keyboard_arrow_down_outlined
                          : Icons.keyboard_arrow_right_outlined),
                  title: title,
                  subtitle: Text(description),
                  onTap: () {
                    _.expand();
                  },
                ),
                ...(_.isExpaneded
                    ? expressions.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: SingleExpression(expression: e),
                        ),
                      )
                    : [])
              ],
            ),
          )),
    );
  }
}

class SingleExpression extends StatelessWidget {
  const SingleExpression({super.key, required this.expression});
  final Expression expression;
  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: () {
              Get.find<ExpressionController>().changeFunction(expression);
            },
            child: ListTile(
              leading: CircleAvatar(
                child: Text(expression.avatar),
              ),
              title: expression.laTexT,
              subtitle: Text(expression.description ?? ""),
              trailing: SizedBox.square(
                  dimension: 45,
                  child: GetBuilder<MarkedItemController>(
                      init: MarkedItemController(),
                      builder: (markedItemController) {
                        bool isMarked =
                            markedItemController.isMarked(expression.name);
                        return IconButton(
                            onPressed: () {
                              if (isMarked) {
                                markedItemController
                                    .removeMarkedItem(expression.name);
                              } else {
                                markedItemController.addMarkedItem(MarkedItem(
                                    expression.name, expression.latexString));
                              }
                            },
                            icon: Icon(
                                size: 28,
                                isMarked
                                    ? Icons.star
                                    : Icons.star_border_outlined));
                      })),
              isThreeLine: true,
            )));
  }
}
