import 'dart:io';

import 'package:flutter/services.dart';

class MethodUtils {
  static final MethodUtils _instance = MethodUtils._internal();
  factory MethodUtils() {
    return _instance;
  }

  MethodUtils._internal() {
    channel = const MethodChannel('plugin.xraph.com/custom_channel');
  }

  late MethodChannel channel;

  Future<void> launch() async {
    if (Platform.isIOS) {
      await channel.invokeMethod('unity#vc#create');
    }
  }
}