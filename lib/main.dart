import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent; // 防止FluentUI的模块与其他冲突
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_size/flutter_keyboard_size.dart';
import 'package:masthore/bottom_bar.dart';
import "package:masthore/bottom_bar_windows.dart" as windows;

import 'package:masthore/graph.dart';
import 'package:get_storage/get_storage.dart';
import 'package:masthore/libs/rust_api/frb_generated.dart';
import 'package:system_theme/system_theme.dart';

void main() async {
  // 初始化getx-storage，用于简单存储
  await GetStorage.init();
  // 初始化system account，用于获取强调色
  await SystemTheme.accentColor.load();
  await RustLib.init();
  runApp(const Masthore());
}

// 全局变量
final GlobalKey<NavigatorState> globalKey =
    GlobalKey<NavigatorState>(); // 用于获取全局的context

// final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
late ThemeData theme; // 用于获取主题色 TODO：应该改为在theme中定义，而不是从theme中直接读取

// 主组件
class Masthore extends StatelessWidget {
  const Masthore({super.key});
  @override
  Widget build(BuildContext context) {
    // 强调色
    final accentColor = SystemTheme.accentColor.accent;
    // 多平台UI支持
    if (Platform.isWindows) {
      // windows平台使用fluentUI
      return fluent.FluentApp(
          title: 'Masthore',
          // 标记navigatorKey，用于获取改context
          navigatorKey: globalKey,
          // 主题，基于强调色
          theme: fluent.FluentThemeData(
            accentColor: accentColor.toAccentColor(),
          ),
          // 首页
          home: const HomePage(),
          debugShowCheckedModeBanner: false);
    } else {
      // 其他平台使用Material 3 TODO：多平台UI支持
      // 主题种子，使用默认颜色（强调色表现不佳）
      ColorScheme colorScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF0078D4), // accentColor
          background:
              // 背景色
              MediaQuery.platformBrightnessOf(context) == Brightness.dark
                  ? const Color(0xFF1f1f1f)
                  : Colors.white,
          // 主颜色
          primary: const Color(0xFF0078D4), // accentColor,
          // 深色浅色模式切换
          brightness: MediaQuery.platformBrightnessOf(context));
      // 创建主题
      theme = ThemeData(
        // chip透明及深色支持
        chipTheme:
            ChipThemeData(backgroundColor: colorScheme.secondaryContainer),
        colorScheme: colorScheme,
        useMaterial3: true,
      );
      return MaterialApp(
        title: 'Masthore',
        navigatorKey: globalKey,
        theme: theme,
        home: const HomePage(),
      );
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  final double scale = 1;
  @override
  Widget build(BuildContext context) {
    return KeyboardSizeProvider(
        child: Scaffold(
            // resizeToAvoidBottomInset: false,
            body: const Graph(),
            // Windows平台使用特定底栏
            bottomNavigationBar: Platform.isWindows
                ? const windows.BottomBar()
                : const BottomBar()));
  }
}
