#!/usr/bin/env python3
"""Generate SHADOW//RUN transparent character sprites, weapons, VFX, branding PNGs.

Creates mobile-optimized sprite sheets + individual key frames matching the
concept-sheet visual identity (colors, silhouettes, weapons) without baking
UI/city backgrounds into gameplay assets.
"""

from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
CURSOR_ASSETS = Path.home() / ".cursor/projects/Users-amr-mahmoud-development-flutter-apps-Shadow-Run/assets"

FW, FH = 96, 128  # frame size
COLS = 6
ANIMS = [
    "idle",
    "run",
    "jump",
    "fall",
    "land",
    "slide",
    "dodge",
    "melee",
    "ranged",
    "hit",
    "death",
    "ability",
    "ultimate",
]

CHARS = {
    "runner": {
        "accent": (0, 229, 255),
        "accent2": (46, 230, 214),
        "armor": (18, 22, 32),
        "armor2": (40, 48, 64),
        "visor": (0, 229, 255),
        "role": "balanced",
        "bulk": 0.92,
        "weapon": "blade",
    },
    "hunter": {
        "accent": (255, 183, 3),
        "accent2": (255, 140, 0),
        "armor": (22, 20, 18),
        "armor2": (48, 40, 32),
        "visor": (255, 183, 3),
        "role": "ranged",
        "bulk": 1.0,
        "weapon": "rifle",
    },
    "blade": {
        "accent": (255, 59, 59),
        "accent2": (200, 30, 40),
        "armor": (28, 16, 18),
        "armor2": (56, 28, 32),
        "visor": (255, 59, 59),
        "role": "melee",
        "bulk": 1.18,
        "weapon": "heavy",
    },
    "phantom": {
        "accent": (123, 44, 255),
        "accent2": (180, 90, 255),
        "armor": (16, 12, 28),
        "armor2": (36, 28, 56),
        "visor": (123, 44, 255),
        "role": "assassin",
        "bulk": 0.85,
        "weapon": "dual",
    },
}


def ensure_dirs() -> None:
    for c in CHARS:
        (ASSETS / "characters" / c).mkdir(parents=True, exist_ok=True)
    (ASSETS / "weapons").mkdir(parents=True, exist_ok=True)
    (ASSETS / "vfx").mkdir(parents=True, exist_ok=True)
    (ASSETS / "branding").mkdir(parents=True, exist_ok=True)


def rgba(rgb, a=255):
    return (*rgb, a)


def lerp(a, b, t):
    return a + (b - a) * t


def pose_offsets(anim: str, frame: int) -> dict:
    t = frame / max(COLS - 1, 1)
    wave = math.sin(t * math.pi * 2)
    if anim == "idle":
        return {"bob": math.sin(t * math.pi * 2) * 1.5, "lean": 0, "leg": wave * 2, "arm": wave * 3, "slide": 0, "jump": 0, "weapon_angle": -20, "scale_y": 1}
    if anim == "run":
        return {"bob": abs(wave) * 3, "lean": 8, "leg": wave * 14, "arm": -wave * 12, "slide": 0, "jump": 0, "weapon_angle": -35 + wave * 10, "scale_y": 1}
    if anim == "jump":
        return {"bob": 0, "lean": 4, "leg": -10, "arm": -18, "slide": 0, "jump": -18 - t * 4, "weapon_angle": -50, "scale_y": 1.02}
    if anim == "fall":
        return {"bob": 0, "lean": 2, "leg": 8, "arm": 10, "slide": 0, "jump": 6, "weapon_angle": -10, "scale_y": 1.04}
    if anim == "land":
        return {"bob": 4, "lean": 6, "leg": 4, "arm": 6, "slide": 0, "jump": 2, "weapon_angle": -25, "scale_y": 0.92}
    if anim == "slide":
        return {"bob": 18, "lean": 28, "leg": 22, "arm": -8, "slide": 1, "jump": 0, "weapon_angle": 10, "scale_y": 0.72}
    if anim == "dodge":
        return {"bob": 2, "lean": -12 + t * 20, "leg": wave * 8, "arm": 16, "slide": 0, "jump": -4, "weapon_angle": 0, "scale_y": 0.95}
    if anim == "melee":
        ang = -80 + t * 140
        return {"bob": 0, "lean": 10, "leg": 4, "arm": ang * 0.2, "slide": 0, "jump": 0, "weapon_angle": ang, "scale_y": 1}
    if anim == "ranged":
        return {"bob": 0, "lean": 6, "leg": 2, "arm": -20, "slide": 0, "jump": 0, "weapon_angle": 0, "scale_y": 1, "aim": 1}
    if anim == "hit":
        return {"bob": 2, "lean": -14, "leg": 2, "arm": 8, "slide": 0, "jump": 0, "weapon_angle": 20, "scale_y": 0.98}
    if anim == "death":
        return {"bob": 10 + t * 20, "lean": 40 * t, "leg": 10, "arm": 20, "slide": 0, "jump": 0, "weapon_angle": 60, "scale_y": 0.85 - t * 0.2}
    if anim == "ability":
        return {"bob": -4, "lean": 16, "leg": wave * 6, "arm": -30, "slide": 0, "jump": -6, "weapon_angle": -90 + t * 40, "scale_y": 1.05}
    if anim == "ultimate":
        return {"bob": -8, "lean": 0, "leg": 0, "arm": -40, "slide": 0, "jump": -10, "weapon_angle": -120 + t * 180, "scale_y": 1.1}
    return {"bob": 0, "lean": 0, "leg": 0, "arm": 0, "slide": 0, "jump": 0, "weapon_angle": -20, "scale_y": 1}


def draw_character(draw: ImageDraw.ImageDraw, cx: float, cy: float, spec: dict, pose: dict, glow_layer: Image.Image):
    accent = spec["accent"]
    armor = spec["armor"]
    armor2 = spec["armor2"]
    bulk = spec["bulk"]
    gdraw = ImageDraw.Draw(glow_layer)

    bob = pose["bob"]
    lean = pose["lean"]
    leg = pose["leg"]
    arm = pose["arm"]
    jump = pose.get("jump", 0)
    sy = pose["scale_y"]
    slide = pose.get("slide", 0)

    y0 = cy + bob + jump
    x0 = cx + lean * 0.15

    # shadow
    draw.ellipse([x0 - 22 * bulk, cy + 52, x0 + 22 * bulk, cy + 60], fill=(0, 0, 0, 90))

    body_h = 38 * bulk * sy
    body_w = 22 * bulk
    if slide:
        body_h *= 0.55
        body_w *= 1.15
        y0 += 12

    # legs
    lw, lh = 7 * bulk, 28 * bulk
    draw.rounded_rectangle([x0 - 12, y0 + 18, x0 - 12 + lw, y0 + 18 + lh + leg], radius=3, fill=rgba(armor))
    draw.rounded_rectangle([x0 + 4, y0 + 18, x0 + 4 + lw, y0 + 18 + lh - leg], radius=3, fill=rgba(armor2))
    # boots
    draw.rounded_rectangle([x0 - 14, y0 + 40 + leg, x0 - 3, y0 + 48 + leg], radius=2, fill=rgba(armor2))
    draw.rounded_rectangle([x0 + 2, y0 + 40 - leg, x0 + 14, y0 + 48 - leg], radius=2, fill=rgba(armor2))
    draw.rectangle([x0 - 14, y0 + 46 + leg, x0 - 3, y0 + 48 + leg], fill=rgba(accent, 180))
    draw.rectangle([x0 + 2, y0 + 46 - leg, x0 + 14, y0 + 48 - leg], fill=rgba(accent, 180))

    # torso
    torso = [x0 - body_w / 2, y0 - body_h / 2, x0 + body_w / 2, y0 + body_h / 2]
    draw.rounded_rectangle(torso, radius=6, fill=rgba(armor))
    # chest plate
    draw.rounded_rectangle(
        [x0 - body_w * 0.35, y0 - body_h * 0.35, x0 + body_w * 0.35, y0 + body_h * 0.25],
        radius=4,
        fill=rgba(armor2),
    )
    # neon seams
    draw.line([x0 - body_w * 0.25, y0 - 8, x0 + body_w * 0.25, y0 - 8], fill=rgba(accent, 200), width=2)
    draw.line([x0, y0 - 10, x0, y0 + 12], fill=rgba(accent, 160), width=1)

    if spec["role"] == "melee":
        # heavy pauldrons / horns
        draw.polygon([(x0 - body_w / 2 - 4, y0 - 8), (x0 - body_w / 2 + 4, y0 - 18), (x0 - 2, y0 - 6)], fill=rgba(armor2))
        draw.polygon([(x0 + body_w / 2 + 4, y0 - 8), (x0 + body_w / 2 - 4, y0 - 18), (x0 + 2, y0 - 6)], fill=rgba(armor2))
        draw.ellipse([x0 - 4, y0 - body_h / 2 - 14, x0 - 1, y0 - body_h / 2 - 4], fill=rgba(accent, 220))
        draw.ellipse([x0 + 1, y0 - body_h / 2 - 14, x0 + 4, y0 - body_h / 2 - 4], fill=rgba(accent, 220))
    if spec["role"] == "ranged":
        # coat tails
        draw.polygon(
            [(x0 - body_w / 2, y0 + 4), (x0 - body_w / 2 - 10, y0 + 34), (x0 - 2, y0 + 18)],
            fill=rgba(armor, 210),
        )
        draw.polygon(
            [(x0 + body_w / 2, y0 + 4), (x0 + body_w / 2 + 8, y0 + 30), (x0 + 4, y0 + 16)],
            fill=rgba(armor2, 200),
        )

    # head / helmet
    hx, hy = x0 + lean * 0.05, y0 - body_h / 2 - 10
    if spec["role"] == "assassin":
        draw.polygon(
            [(hx - 11, hy + 4), (hx + 11, hy + 4), (hx + 8, hy - 14), (hx - 4, hy - 16)],
            fill=rgba(armor),
        )
    elif spec["role"] == "balanced":
        # hood
        draw.ellipse([hx - 13, hy - 12, hx + 13, hy + 10], fill=rgba(armor))
        draw.arc([hx - 14, hy - 14, hx + 14, hy + 8], 200, 340, fill=rgba(armor2), width=4)
    else:
        draw.rounded_rectangle([hx - 12, hy - 12, hx + 12, hy + 10], radius=5, fill=rgba(armor))

    # visor
    if spec["role"] == "melee":
        draw.rectangle([hx - 8, hy - 2, hx + 8, hy + 4], fill=rgba(spec["visor"]))
        draw.rectangle([hx - 2, hy + 4, hx + 2, hy + 8], fill=rgba(spec["visor"]))
    else:
        draw.rounded_rectangle([hx - 9, hy - 1, hx + 9, hy + 5], radius=2, fill=rgba(spec["visor"]))
    gdraw.ellipse([hx - 10, hy - 2, hx + 10, hy + 6], fill=rgba(accent, 70))

    # front arm
    ax = x0 + 10 * bulk
    ay = y0 - 4
    draw.rounded_rectangle([ax, ay + arm * 0.2, ax + 7, ay + 22 + arm * 0.1], radius=3, fill=rgba(armor2))

    # weapon
    wa = math.radians(pose["weapon_angle"])
    wx, wy = ax + 4, ay + 10
    draw_weapon(draw, gdraw, spec, wx, wy, wa, pose)


def draw_weapon(draw, gdraw, spec, x, y, angle, pose):
    accent = spec["accent"]
    kind = spec["weapon"]
    c, s = math.cos(angle), math.sin(angle)

    def tip(length, width=0):
        return (x + c * length - s * width, y + s * length + c * width)

    if kind == "blade":
        hilt = [tip(-6, -2), tip(-6, 2), tip(6, 2), tip(6, -2)]
        draw.polygon(hilt, fill=(30, 34, 42, 255))
        blade = [tip(8, -3), tip(8, 3), tip(46, 1), tip(46, -1)]
        draw.polygon(blade, fill=rgba(accent))
        gdraw.line([tip(10), tip(44)], fill=rgba(accent, 120), width=6)
    elif kind == "rifle":
        body = [tip(-8, -3), tip(-8, 3), tip(38, 2), tip(38, -2)]
        draw.polygon(body, fill=(28, 24, 20, 255))
        barrel = [tip(38, -1.5), tip(38, 1.5), tip(52, 1), tip(52, -1)]
        draw.polygon(barrel, fill=rgba(accent, 230))
        draw.ellipse([tip(10)[0] - 3, tip(10)[1] - 3, tip(10)[0] + 3, tip(10)[1] + 3], fill=rgba(accent))
        if pose.get("aim"):
            gdraw.ellipse([tip(54)[0] - 6, tip(54)[1] - 6, tip(54)[0] + 6, tip(54)[1] + 6], fill=rgba(accent, 90))
    elif kind == "heavy":
        hilt = [tip(-10, -3), tip(-10, 3), tip(8, 4), tip(8, -4)]
        draw.polygon(hilt, fill=(36, 20, 22, 255))
        blade = [tip(10, -6), tip(10, 6), tip(58, 3), tip(58, -3)]
        draw.polygon(blade, fill=(40, 18, 20, 255))
        edge1 = [tip(12, -6), tip(56, -3), tip(56, -1), tip(12, -3)]
        edge2 = [tip(12, 6), tip(56, 3), tip(56, 1), tip(12, 3)]
        draw.polygon(edge1, fill=rgba(accent))
        draw.polygon(edge2, fill=rgba(accent))
        gdraw.line([tip(14), tip(54)], fill=rgba(accent, 100), width=8)
    elif kind == "dual":
        for sign in (-1, 1):
            ox = x + sign * 6
            oy = y + sign * 4
            b = [ (ox + c * 4 - s * 2, oy + s * 4 + c * 2),
                  (ox + c * 4 + s * 2, oy + s * 4 - c * 2),
                  (ox + c * 28 + s * 1, oy + s * 28 - c * 1),
                  (ox + c * 28 - s * 1, oy + s * 28 + c * 1) ]
            draw.polygon(b, fill=rgba(accent))
            gdraw.line([(ox + c * 6, oy + s * 6), (ox + c * 26, oy + s * 26)], fill=rgba(accent, 100), width=4)


def render_frame(spec: dict, anim: str, frame: int) -> Image.Image:
    img = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    glow = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    pose = pose_offsets(anim, frame)
    draw_character(draw, FW * 0.42, FH * 0.55, spec, pose, glow)
    # soft accent glow under character
    glow = glow.filter(ImageFilter.GaussianBlur(3))
    out = Image.alpha_composite(glow, img)
    return out


def make_sheet(char_id: str) -> None:
    spec = CHARS[char_id]
    sheet = Image.new("RGBA", (FW * COLS, FH * len(ANIMS)), (0, 0, 0, 0))
    out_dir = ASSETS / "characters" / char_id
    for ri, anim in enumerate(ANIMS):
        for ci in range(COLS):
            frame = render_frame(spec, anim, ci)
            sheet.paste(frame, (ci * FW, ri * FH), frame)
            if ci == 0:
                frame.save(out_dir / f"{anim}.png", optimize=True)
        # also save a mid-run frame pack for convenience
        if anim == "run":
            for ci in range(COLS):
                render_frame(spec, anim, ci).save(out_dir / f"run_{ci}.png", optimize=True)
    sheet.save(out_dir / "spritesheet.png", optimize=True)
    # portrait = idle frame 0 upscaled slightly
    portrait = render_frame(spec, "idle", 0).resize((192, 256), Image.Resampling.NEAREST)
    portrait.save(out_dir / "portrait.png", optimize=True)
    print(f"  wrote {char_id} sheet {sheet.size}")


def make_weapon_asset(char_id: str) -> None:
    spec = CHARS[char_id]
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    glow = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    pose = {"weapon_angle": -35, "aim": 0}
    draw_weapon(draw, ImageDraw.Draw(glow), spec, 40, 70, math.radians(-35), pose)
    glow = glow.filter(ImageFilter.GaussianBlur(2))
    out = Image.alpha_composite(glow, img)
    out.save(ASSETS / "weapons" / f"{char_id}_weapon.png", optimize=True)


def make_vfx() -> None:
    vfx_specs = {
        "runner_slash": ((0, 229, 255), "arc"),
        "runner_dash": ((0, 229, 255), "streak"),
        "runner_afterimage": ((0, 229, 255), "ghost"),
        "hunter_muzzle": ((255, 183, 3), "burst"),
        "hunter_projectile": ((255, 183, 3), "bolt"),
        "hunter_mark": ((255, 183, 3), "cross"),
        "hunter_impact": ((255, 183, 3), "impact"),
        "blade_slash": ((255, 59, 59), "arc_heavy"),
        "blade_wave": ((255, 59, 59), "wave"),
        "blade_impact": ((255, 59, 59), "impact"),
        "phantom_phase": ((123, 44, 255), "ghost"),
        "phantom_particles": ((123, 44, 255), "sparks"),
        "phantom_fracture": ((123, 44, 255), "fracture"),
    }
    for name, (color, kind) in vfx_specs.items():
        img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        if kind == "arc":
            d.arc([8, 18, 88, 78], -40, 80, fill=rgba(color, 230), width=6)
        elif kind == "arc_heavy":
            d.arc([4, 10, 92, 86], -50, 90, fill=rgba(color, 240), width=10)
        elif kind == "streak":
            for i in range(5):
                y = 30 + i * 8
                d.line([10, y, 86 - i * 6, y + 2], fill=rgba(color, 200 - i * 30), width=4)
        elif kind == "ghost":
            d.ellipse([28, 18, 68, 78], outline=rgba(color, 160), width=3)
            d.ellipse([34, 26, 62, 70], fill=rgba(color, 50))
        elif kind == "burst":
            cx, cy = 48, 48
            for a in range(0, 360, 30):
                rad = math.radians(a)
                d.line([cx, cy, cx + math.cos(rad) * 36, cy + math.sin(rad) * 36], fill=rgba(color, 200), width=3)
            d.ellipse([36, 36, 60, 60], fill=rgba((255, 255, 255), 220))
        elif kind == "bolt":
            d.ellipse([12, 40, 84, 56], fill=rgba(color, 200))
            d.ellipse([60, 36, 88, 60], fill=rgba((255, 255, 255), 230))
        elif kind == "cross":
            d.ellipse([18, 18, 78, 78], outline=rgba(color, 220), width=3)
            d.line([48, 12, 48, 84], fill=rgba(color, 220), width=2)
            d.line([12, 48, 84, 48], fill=rgba(color, 220), width=2)
        elif kind == "impact":
            d.ellipse([24, 24, 72, 72], outline=rgba(color, 200), width=4)
            d.ellipse([34, 34, 62, 62], fill=rgba(color, 120))
        elif kind == "wave":
            d.arc([6, 20, 90, 76], -30, 30, fill=rgba(color, 230), width=8)
            d.arc([16, 28, 80, 68], -25, 25, fill=rgba(color, 140), width=4)
        elif kind == "sparks":
            for i in range(12):
                a = i * 0.5
                x = 48 + math.cos(a) * (10 + i * 2)
                y = 48 + math.sin(a) * (8 + i * 2)
                d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=rgba(color, 200))
        elif kind == "fracture":
            d.ellipse([16, 16, 80, 80], outline=rgba(color, 200), width=3)
            d.line([48, 20, 40, 48], fill=rgba(color, 220), width=2)
            d.line([40, 48, 58, 56], fill=rgba(color, 220), width=2)
            d.line([58, 56, 44, 78], fill=rgba(color, 220), width=2)
            d.ellipse([42, 42, 54, 54], fill=rgba(color, 180))
        img = img.filter(ImageFilter.GaussianBlur(0.6))
        img.save(ASSETS / "vfx" / f"{name}.png", optimize=True)
    print("  wrote vfx set")


def remove_dark_bg(src: Path, dst: Path, threshold: int = 42) -> bool:
    if not src.exists():
        return False
    im = Image.open(src).convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            # dark bg / vignette
            if r < threshold and g < threshold and b < threshold + 8:
                px[x, y] = (r, g, b, 0)
            # keep neon accents even if dark-ish nearby handled above
    # soft edge cleanup: kill near-black fringe
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and r < threshold + 12 and g < threshold + 12 and b < threshold + 16:
                lum = (r + g + b) / 3
                if lum < threshold + 6:
                    px[x, y] = (r, g, b, 0)
    im.save(dst, optimize=True)
    return True


def import_ai_portraits() -> None:
    mapping = {
        "runner": "runner_idle.png",
        "hunter": "hunter_idle.png",
        "blade": "blade_idle.png",
        "phantom": "phantom_idle.png",
    }
    for cid, fname in mapping.items():
        src = CURSOR_ASSETS / fname
        dst = ASSETS / "characters" / cid / "portrait_art.png"
        if remove_dark_bg(src, dst, threshold=38):
            print(f"  imported portrait_art {cid}")
        else:
            print(f"  skip portrait_art {cid} (missing)")


def import_ai_weapons() -> None:
    mapping = {
        "runner": "weapon_runner.png",
        "hunter": "weapon_hunter.png",
        "blade": "weapon_blade.png",
        "phantom": "weapon_phantom.png",
    }
    for cid, fname in mapping.items():
        src = CURSOR_ASSETS / fname
        dst = ASSETS / "weapons" / f"{cid}_weapon_art.png"
        if remove_dark_bg(src, dst, threshold=36):
            print(f"  imported weapon_art {cid}")


def make_symbol_png() -> None:
    """Rasterize the S symbol for app/icon fallback without cairo."""
    size = 256
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cyan = (0, 229, 255, 255)
    metal = (230, 236, 245, 255)
    # two shards forming S
    d.polygon([(150, 28), (210, 60), (178, 96), (228, 140), (168, 188), (112, 152), (144, 116), (94, 70)], fill=metal, outline=cyan)
    d.polygon([(78, 78), (136, 116), (104, 152), (156, 198), (96, 246), (40, 208), (72, 170), (22, 124)], fill=metal, outline=cyan)
    d.line([(128, 108), (160, 128)], fill=cyan, width=6)
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.line([(128, 108), (160, 128)], fill=(0, 229, 255, 120), width=14)
    glow = glow.filter(ImageFilter.GaussianBlur(4))
    out = Image.alpha_composite(glow, img)
    out.save(ASSETS / "branding" / "symbol.png", optimize=True)
    # also write compact logo wordmark PNG
    logo = Image.new("RGBA", (640, 160), (0, 0, 0, 0))
    ld = ImageDraw.Draw(logo)
    symbol = out.resize((120, 120), Image.Resampling.LANCZOS)
    logo.paste(symbol, (8, 20), symbol)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 54)
        small = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 14)
    except OSError:
        font = ImageFont.load_default()
        small = font
    ld.text((140, 48), "SHADOW", font=font, fill=(240, 244, 250, 255))
    ld.text((390, 48), "//", font=font, fill=cyan)
    ld.text((450, 48), "RUN", font=font, fill=cyan)
    ld.text((140, 112), "RUN. FIGHT. SURVIVE.", font=small, fill=(0, 229, 255, 210))
    logo.save(ASSETS / "branding" / "logo_wordmark.png", optimize=True)
    print("  wrote branding symbol/wordmark PNGs")


def write_manifest() -> None:
    lines = [
        "# Auto-generated asset layout",
        f"frame={FW}x{FH}",
        f"cols={COLS}",
        "anims=" + ",".join(ANIMS),
        "characters=" + ",".join(CHARS.keys()),
    ]
    (ASSETS / "asset_manifest.txt").write_text("\n".join(lines) + "\n")


def main() -> None:
    ensure_dirs()
    print("Generating character sprite sheets...")
    for cid in CHARS:
        make_sheet(cid)
        make_weapon_asset(cid)
    print("Generating VFX...")
    make_vfx()
    print("Generating branding rasters...")
    make_symbol_png()
    print("Importing AI art with bg cleanup...")
    import_ai_portraits()
    import_ai_weapons()
    write_manifest()
    print("Done.")


if __name__ == "__main__":
    main()
