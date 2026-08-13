/// Official SHADOW//RUN brand asset paths.
class BrandAssets {
  BrandAssets._();

  static const String logoSvg = 'assets/branding/shadow_run_logo.svg';
  static const String logoPng = 'assets/branding/shadow_run_logo.png';
  static const String logoTransparent =
      'assets/branding/shadow_run_logo.png';
  static const String logoWhite = 'assets/branding/shadow_run_logo_white.png';
  static const String logoDark = 'assets/branding/shadow_run_logo_dark.png';
  static const String logoCyan = 'assets/branding/shadow_run_logo_cyan.png';
  static const String logoMono = 'assets/branding/shadow_run_logo_mono.png';
  static const String logoMonoSvg = 'assets/branding/shadow_run_logo_mono.svg';

  static const String wordmarkSvg = 'assets/branding/shadow_run_wordmark.svg';
  static const String wordmarkPng = 'assets/branding/shadow_run_wordmark.png';

  static const String symbolSvg = 'assets/branding/shadow_run_symbol.svg';
  static const String symbolPng = 'assets/branding/shadow_run_symbol.png';

  static const String appIcon = 'assets/branding/shadow_run_app_icon.png';
  static const String appIconSvg = 'assets/branding/shadow_run_app_icon.svg';

  /// Legacy aliases still referenced by older painters / preloads.
  static const String legacyWordmark = 'assets/branding/logo_wordmark.png';
  static const String legacySymbol = 'assets/branding/symbol.png';
  static const String legacySymbolSvg = 'assets/branding/symbol.svg';
  static const String legacyTransparent =
      'assets/branding/logo_transparent.png';
  static const String legacyAppIcon = 'assets/branding/app_icon.png';
}

enum BrandLogoVariant {
  full,
  wordmark,
  symbol,
  white,
  dark,
  cyan,
  mono,
}
