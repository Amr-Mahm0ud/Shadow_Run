# SHADOW//RUN Brand Kit

Official production branding for the game.

## Primary mark

- Full logo: symbol + `SHADOW//RUN` wordmark
- Symbol: twin-slash S / blade / speed mark (works at app-icon size)
- Wordmark: custom geometric path letterforms (not a stock sci-fi font)

## Files

| Asset | Use |
| --- | --- |
| `shadow_run_logo.svg` / `.png` | Full logo (transparent) |
| `shadow_run_wordmark.svg` / `.png` | Text only |
| `shadow_run_symbol.svg` / `.png` | Symbol only |
| `shadow_run_logo_white.png` | Light logo on dark UI |
| `shadow_run_logo_dark.png` | Dark logo on light UI |
| `shadow_run_logo_cyan.png` | White + cyan accent |
| `shadow_run_logo_mono.svg` / `.png` | Single-color |
| `shadow_run_app_icon.svg` / `.png` | Square app icon |

Legacy aliases (`logo.svg`, `symbol.svg`, `logo_wordmark.png`, `app_icon.png`, …) mirror the official files for older references.

## Rebuild PNGs

```bash
cd tool/brand && npm install && node render_brand.js
```

## Integration

Use `BrandLogo` from `lib/core/branding/brand_logo.dart`.
