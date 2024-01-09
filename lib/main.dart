import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_size/flutter_keyboard_size.dart';
import 'package:masthore/bottom_bar.dart';
import "package:masthore/bottom_bar_windows.dart" as windows;

import 'package:masthore/graph.dart';
export 'package:masthore/libs/rust_bridge.dart' show api;
import 'package:get_storage/get_storage.dart';
import 'package:system_theme/system_theme.dart';

void main() async {
  await GetStorage.init();
  await SystemTheme.accentColor.load();
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> globalKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
late ThemeData theme;

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final accentColor = SystemTheme.accentColor.accent;
    if (Platform.isWindows) {
      return fluent.FluentApp(
          title: 'Masthore',
          navigatorKey: globalKey,
          theme: fluent.FluentThemeData(
            accentColor: accentColor.toAccentColor(),
          ),
          home: const MyHomePage(),
          debugShowCheckedModeBanner: false);
    } else {
      ColorScheme colorScheme = ColorScheme.fromSeed(
          seedColor: accentColor, // const Color(0xFF0078D4),
          background:
              MediaQuery.platformBrightnessOf(context) == Brightness.dark
                  ? const Color(0xFF1f1f1f)
                  : Colors.white,
          primary: accentColor, //const Color(0xFF0078D4),
          brightness: MediaQuery.platformBrightnessOf(context));
      theme = ThemeData(
        chipTheme:
            ChipThemeData(backgroundColor: colorScheme.secondaryContainer),
        colorScheme: colorScheme,
        useMaterial3: true,
      );
      return MaterialApp(
        title: 'Masthore',
        navigatorKey: globalKey,
        theme: theme,
        home: const MyHomePage(),
      );
    }
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return KeyboardSizeProvider(
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: const Graph(),
            bottomNavigationBar: Platform.isWindows
                ? const windows.BottomBar()
                : const BottomBar()));
  }
}

// class FloatButton extends StatelessWidget {
//   const FloatButton({super.key});
//   @override
//   Widget build(context) {
//     return FloatingActionButton(
//       onPressed: () {
//         Scaffold.of(context).showBottomSheet<void>(
//           (BuildContext context) {
//             return const Editor();
//           },
//         );
//       },
//       tooltip: 'Increment',
//       child: const Icon(Icons.add),
//     ); // This trailing comma makes auto-formatting nicer for build methods.
//   }
// }
