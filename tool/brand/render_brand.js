#!/usr/bin/env node
/**
 * Rasterize SHADOW//RUN brand SVGs into production PNGs via @resvg/resvg-js.
 */
const fs = require('fs');
const path = require('path');
const { Resvg } = require('@resvg/resvg-js');

const branding = path.resolve(__dirname, '../../assets/branding');

function render(svgText, outFile, width) {
  const resvg = new Resvg(svgText, {
    fitTo: { mode: 'width', value: width },
    background: 'rgba(0,0,0,0)',
  });
  const png = resvg.render().asPng();
  fs.writeFileSync(outFile, png);
  console.log('wrote', path.basename(outFile), `(${width}px)`);
}

function read(name) {
  return fs.readFileSync(path.join(branding, name), 'utf8');
}

function recolor(svg, replacements) {
  let out = svg;
  for (const [from, to] of replacements) {
    out = out.split(from).join(to);
  }
  return out;
}

const logo = read('shadow_run_logo.svg');
const wordmark = read('shadow_run_wordmark.svg');
const symbol = read('shadow_run_symbol.svg');
const mono = read('shadow_run_logo_mono.svg');
const appIcon = read('shadow_run_app_icon.svg');
const cyanLogo = read('shadow_run_logo_cyan.svg');

// Primary transparent assets
render(logo, path.join(branding, 'shadow_run_logo.png'), 1840);
render(logo, path.join(branding, 'logo_transparent.png'), 1840);
render(wordmark, path.join(branding, 'shadow_run_wordmark.png'), 1520);
render(wordmark, path.join(branding, 'logo_wordmark.png'), 1520);
render(symbol, path.join(branding, 'shadow_run_symbol.png'), 1024);
render(symbol, path.join(branding, 'symbol.png'), 512);
render(mono, path.join(branding, 'shadow_run_logo_mono.png'), 1840);
render(appIcon, path.join(branding, 'shadow_run_app_icon.png'), 1024);
render(appIcon, path.join(branding, 'app_icon.png'), 1024);
render(appIcon, path.join(branding, 'app_icon_192.png'), 192);

// White version (pure light on transparent)
render(mono, path.join(branding, 'shadow_run_logo_white.png'), 1840);

// Dark version for light backgrounds
const darkLogo = recolor(mono, [['#FFFFFF', '#0A0E17']]);
render(darkLogo, path.join(branding, 'shadow_run_logo_dark.png'), 1840);

// Cyan accent version
render(cyanLogo, path.join(branding, 'shadow_run_logo_cyan.png'), 1840);

// Legacy aliases
render(logo, path.join(branding, 'logo.png'), 1840);
fs.copyFileSync(
  path.join(branding, 'shadow_run_logo.svg'),
  path.join(branding, 'logo.svg'),
);
fs.copyFileSync(
  path.join(branding, 'shadow_run_symbol.svg'),
  path.join(branding, 'symbol.svg'),
);

console.log('Brand export complete.');
