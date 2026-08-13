import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Design reference: wide phone landscape (~800×360 logical).
class AppBreakpoints {
  AppBreakpoints._();

  static const double compactShortest = 500;
  static const double mediumShortest = 700;
  static const double designWidth = 800;
  static const double designHeight = 360;
}

enum DeviceSizeClass { compact, medium, expanded }

/// Responsive metrics derived from the current [MediaQuery].
class Responsive {
  Responsive._(this.context, this.size, this.padding, this.textScaler);

  factory Responsive.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Responsive._(context, mq.size, mq.padding, mq.textScaler);
  }

  final BuildContext context;
  final Size size;
  final EdgeInsets padding;
  final TextScaler textScaler;

  double get width => size.width;
  double get height => size.height;
  double get shortest => math.min(width, height);
  double get longest => math.max(width, height);
  double get aspectRatio => width / math.max(height, 1);

  bool get isLandscape => width >= height;
  bool get isPortrait => !isLandscape;
  bool get isTablet => shortest >= AppBreakpoints.compactShortest;

  DeviceSizeClass get sizeClass {
    if (shortest < AppBreakpoints.compactShortest) {
      return DeviceSizeClass.compact;
    }
    if (shortest < AppBreakpoints.mediumShortest) {
      return DeviceSizeClass.medium;
    }
    return DeviceSizeClass.expanded;
  }

  /// Scale relative to design width, clamped for tiny/huge screens.
  double scale(double value) {
    final factor = (width / AppBreakpoints.designWidth).clamp(0.72, 1.45);
    return value * factor;
  }

  double sp(double fontSize) => scale(fontSize);

  EdgeInsets get pagePadding {
    final base = scale(isTablet ? 28 : 16);
    return EdgeInsets.only(
      left: math.max(padding.left, base),
      right: math.max(padding.right, base),
      top: math.max(padding.top, base * 0.6),
      bottom: math.max(padding.bottom, base * 0.6),
    );
  }

  /// Prefer side-by-side layouts when landscape and wide enough.
  bool get useSplitHome => isLandscape && width >= 640;

  int get homeGridColumns {
    if (!isLandscape) return 2;
    if (sizeClass == DeviceSizeClass.expanded) return 3;
    return 2;
  }

  double get menuTileAspect {
    if (isPortrait) return 2.8;
    if (sizeClass == DeviceSizeClass.compact) return 2.2;
    return 2.6;
  }

  /// Clamp accessibility text so HUD/buttons stay usable in landscape.
  static TextScaler clampedTextScaler(TextScaler input) {
    return input.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.25);
  }
}

/// Applies safe, device-aware MediaQuery overrides app-wide.
class ResponsiveAppFrame extends StatelessWidget {
  const ResponsiveAppFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: Responsive.clampedTextScaler(mq.textScaler),
      ),
      child: child,
    );
  }
}
