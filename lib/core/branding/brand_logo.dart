import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'brand_assets.dart';

export 'brand_assets.dart' show BrandAssets, BrandLogoVariant;

/// Responsive SHADOW//RUN logo mark for menus, splash, and overlays.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.variant = BrandLogoVariant.full,
    this.height,
    this.width,
    this.alignment = Alignment.centerLeft,
    this.fit = BoxFit.contain,
  });

  final BrandLogoVariant variant;
  final double? height;
  final double? width;
  final Alignment alignment;
  final BoxFit fit;

  String get _png => switch (variant) {
        BrandLogoVariant.full => BrandAssets.logoPng,
        BrandLogoVariant.wordmark => BrandAssets.wordmarkPng,
        BrandLogoVariant.symbol => BrandAssets.symbolPng,
        BrandLogoVariant.white => BrandAssets.logoWhite,
        BrandLogoVariant.dark => BrandAssets.logoDark,
        BrandLogoVariant.cyan => BrandAssets.logoCyan,
        BrandLogoVariant.mono => BrandAssets.logoMono,
      };

  String? get _svg => switch (variant) {
        BrandLogoVariant.full => BrandAssets.logoSvg,
        BrandLogoVariant.wordmark => BrandAssets.wordmarkSvg,
        BrandLogoVariant.symbol => BrandAssets.symbolSvg,
        BrandLogoVariant.mono => BrandAssets.logoMonoSvg,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final h = height;
    final w = width;
    final svg = _svg;
    if (svg != null) {
      return SvgPicture.asset(
        svg,
        height: h,
        width: w,
        fit: fit,
        alignment: alignment,
        placeholderBuilder: (_) => Image.asset(
          _png,
          height: h,
          width: w,
          fit: fit,
          alignment: alignment,
          filterQuality: FilterQuality.high,
        ),
      );
    }
    return Image.asset(
      _png,
      height: h,
      width: w,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
    );
  }
}
