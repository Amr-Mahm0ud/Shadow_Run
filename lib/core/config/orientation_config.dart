import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Landscape-first arcade orientation for phones, tablets, and foldables.
class OrientationConfig {
  OrientationConfig._();

  static const List<DeviceOrientation> preferred = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  static Future<void> lockLandscape() async {
    await SystemChrome.setPreferredOrientations(preferred);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
}
