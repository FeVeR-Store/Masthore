import 'dart:io';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:masthore/libs/rust_api.dart';

const base = 'native';
final path = Platform.isWindows ? '$base.dll' : 'lib$base.so';
final dylib = loadLibForFlutter(path);
final api = NativeImpl(dylib);
