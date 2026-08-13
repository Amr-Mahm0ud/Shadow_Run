#!/usr/bin/env python3
"""Generate SHADOW//RUN enemy sprite sheets, projectiles, and hazards (Pillow only)."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"

FW, FH = 96, 128
COLS = 4
ANIMS = ["idle", "move", "attack", "hit", "death", "ranged", "special", "fly"]

FACTIONS = {
    "omnicorp": {
        "accent": (255, 59, 59),
        "armor": (14, 16, 22),
        "armor2": (32, 36, 48),
    },
    "malfunction": {
        "accent": (123, 44, 255),
        "armor": (18, 12, 28),
        "armor2": (40, 28, 56),
    },
    "rift": {
        "accent": (0, 229, 255),
        "armor": (10, 20, 26),
        "armor2": (24, 44, 52),
    },
}

CYAN_SPARK = (0, 229, 255)

# kind drives silhouette; boss=True scales drawing
ENEMY_SPECS: dict[str, dict] = {
    "grunt": {"faction": "omnicorp", "kind": "grunt", "bulk": 1.0, "boss": False},
    "raptor": {"faction": "malfunction", "kind": "raptor", "bulk": 0.92, "boss": False},
    "sentinel": {"faction": "omnicorp", "kind": "sentinel", "bulk": 1.0, "boss": False},
    "shocker": {"faction": "omnicorp", "kind": "shocker", "bulk": 1.08, "boss": False},
    "guardian": {"faction": "omnicorp", "kind": "guardian", "bulk": 1.12, "boss": False},
    "drone_swarmer": {"faction": "malfunction", "kind": "drone_swarmer", "bulk": 0.95, "boss": False},
    "shield_maiden": {"faction": "malfunction", "kind": "shield_maiden", "bulk": 1.05, "boss": False},
    "executioner": {"faction": "omnicorp", "kind": "executioner", "bulk": 1.15, "boss": False},
    "void_stalker": {"faction": "malfunction", "kind": "void_stalker", "bulk": 0.88, "boss": False},
    "scout_drone": {"faction": "omnicorp", "kind": "scout_drone", "bulk": 0.72, "boss": False, "fly": True},
    "missile_drone": {"faction": "omnicorp", "kind": "missile_drone", "bulk": 0.78, "boss": False, "fly": True},
    "bomber_drone": {"faction": "omnicorp", "kind": "bomber_drone", "bulk": 0.85, "boss": False, "fly": True},
    "sniper_drone": {"faction": "omnicorp", "kind": "sniper_drone", "bulk": 0.75, "boss": False, "fly": True},
    "steel_brute": {"faction": "omnicorp", "kind": "steel_brute", "bulk": 1.25, "boss": False},
    "war_machine": {"faction": "omnicorp", "kind": "war_machine", "bulk": 1.2, "boss": False},
    "fortress": {"faction": "omnicorp", "kind": "fortress", "bulk": 1.35, "boss": False},
    "chaos_engineer": {"faction": "malfunction", "kind": "chaos_engineer", "bulk": 1.0, "boss": False},
    "rift_reaper": {"faction": "rift", "kind": "rift_reaper", "bulk": 1.05, "boss": False},
    "corrupted_wraith": {"faction": "rift", "kind": "corrupted_wraith", "bulk": 0.9, "boss": False, "fly": True},
    "juggernaut": {"faction": "omnicorp", "kind": "steel_brute", "bulk": 1.45, "boss": True},
    "overseer": {"faction": "malfunction", "kind": "chaos_engineer", "bulk": 1.4, "boss": True},
    "warp_behemoth": {"faction": "rift", "kind": "fortress", "bulk": 1.5, "boss": True},
    "apex_sentinel": {"faction": "omnicorp", "kind": "sentinel", "bulk": 1.42, "boss": True},
}

ENEMY_IDS = list(ENEMY_SPECS.keys())

PROJECTILES = [
    "bullet",
    "plasma",
    "electric",
    "missile",
    "laser",
    "rift",
    "energy_wave",
    "explosive",
]

HAZARDS = [
    "laser_turret",
    "spike_trap",
    "electric_floor",
    "falling_debris",
    "explosive_barrel",
]

files_created = 0


def track_save(img: Image.Image, path: Path) -> None:
    global files_created
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    files_created += 1


def rgba(rgb, a=255):
    return (*rgb, a)


def pose_offsets(anim: str, frame: int, spec: dict) -> dict:
    t = frame / max(COLS - 1, 1)
    wave = math.sin(t * math.pi * 2)
    is_fly = spec.get("fly") or spec["kind"] in {
        "scout_drone",
        "missile_drone",
        "bomber_drone",
        "sniper_drone",
        "corrupted_wraith",
    }
    base = {
        "bob": 0.0,
        "lean": 0.0,
        "leg": 0.0,
        "arm": 0.0,
        "jump": 0.0,
        "weapon_angle": -25.0,
        "scale_y": 1.0,
        "attack_swing": 0.0,
        "fly_y": -14.0 if is_fly else 0.0,
        "fly_tilt": 0.0,
        "alpha_body": 255,
    }
    if anim == "idle":
        base.update(bob=math.sin(t * math.pi * 2) * 1.5, leg=wave * 2, arm=wave * 2)
    elif anim == "move":
        base.update(bob=abs(wave) * 3, lean=10, leg=wave * 12, arm=-wave * 10, weapon_angle=-35 + wave * 8)
    elif anim == "attack":
        swing = -70 + t * 130
        base.update(lean=12, arm=swing * 0.15, weapon_angle=swing, attack_swing=t)
    elif anim == "hit":
        base.update(lean=-16, arm=10, weapon_angle=25)
    elif anim == "death":
        base.update(bob=8 + t * 22, lean=38 * t, arm=18, weapon_angle=55, scale_y=0.88 - t * 0.18, alpha_body=int(255 * (1 - t * 0.35)))
    elif anim == "ranged":
        base.update(lean=8, weapon_angle=5, arm=-12)
    elif anim == "special":
        base.update(bob=-4, lean=6, jump=-6, weapon_angle=-90 + t * 60)
    elif anim == "fly":
        base.update(
            fly_y=-18 + math.sin(t * math.pi * 2) * 6,
            fly_tilt=wave * 8,
            bob=math.sin(t * math.pi * 2) * 2,
        )
    return base


def draw_shadow(draw: ImageDraw.ImageDraw, x0: float, cy: float, bulk: float, fly_y: float):
    sy = cy + 52 - fly_y * 0.3
    w = 20 * bulk * (0.65 if fly_y < -8 else 1.0)
    draw.ellipse([x0 - w, sy, x0 + w, sy + 8], fill=(0, 0, 0, 80))


def draw_legs(draw, x0, y0, bulk, leg, armor, armor2, accent, sy=1.0):
    lw, lh = 7 * bulk, 26 * bulk * sy
    draw.rounded_rectangle([x0 - 12, y0 + 16, x0 - 12 + lw, y0 + 16 + lh + leg], radius=3, fill=rgba(armor))
    draw.rounded_rectangle([x0 + 4, y0 + 16, x0 + 4 + lw, y0 + 16 + lh - leg], radius=3, fill=rgba(armor2))
    draw.rounded_rectangle([x0 - 13, y0 + 38 + leg, x0 - 2, y0 + 46 + leg], radius=2, fill=rgba(armor2))
    draw.rounded_rectangle([x0 + 3, y0 + 38 - leg, x0 + 13, y0 + 46 - leg], radius=2, fill=rgba(armor2))
    draw.rectangle([x0 - 13, y0 + 44 + leg, x0 - 2, y0 + 46 + leg], fill=rgba(accent, 170))
    draw.rectangle([x0 + 3, y0 + 44 - leg, x0 + 13, y0 + 46 - leg], fill=rgba(accent, 170))


def draw_torso_head(draw, x0, y0, bulk, armor, armor2, accent, lean_kind: str, alpha: int):
    body_h = 36 * bulk
    body_w = 22 * bulk
    fill_a = lambda c: (*c[:3], int(c[3] * alpha / 255) if len(c) == 4 else int(alpha))

    torso = [x0 - body_w / 2, y0 - body_h / 2, x0 + body_w / 2, y0 + body_h / 2]
    draw.rounded_rectangle(torso, radius=5, fill=fill_a(rgba(armor)))
    draw.rounded_rectangle(
        [x0 - body_w * 0.32, y0 - body_h * 0.3, x0 + body_w * 0.32, y0 + body_h * 0.22],
        radius=4,
        fill=fill_a(rgba(armor2)),
    )
    draw.line([x0 - body_w * 0.2, y0 - 6, x0 + body_w * 0.2, y0 - 6], fill=fill_a(rgba(accent, 190)), width=2)

    if lean_kind == "hunched":
        draw.rounded_rectangle(
            [x0 - body_w * 0.55, y0 - body_h * 0.15, x0 + body_w * 0.45, y0 + body_h * 0.55],
            radius=6,
            fill=fill_a(rgba(armor)),
        )
        hx, hy = x0 + 8, y0 - body_h * 0.35
    elif lean_kind == "hood":
        hx, hy = x0, y0 - body_h * 0.55
        draw.polygon(
            [(hx, hy - 14 * bulk), (hx - 16 * bulk, hy + 8), (hx + 16 * bulk, hy + 8)],
            fill=fill_a(rgba(armor)),
        )
        draw.polygon(
            [(hx, hy - 10 * bulk), (hx - 10 * bulk, hy + 4), (hx + 10 * bulk, hy + 4)],
            fill=fill_a(rgba(armor2, 200)),
        )
    else:
        hx, hy = x0, y0 - body_h * 0.62
        draw.rounded_rectangle(
            [hx - 9 * bulk, hy - 10 * bulk, hx + 9 * bulk, hy + 8 * bulk],
            radius=5,
            fill=fill_a(rgba(armor2)),
        )
        draw.rectangle([hx - 7 * bulk, hy - 2, hx + 7 * bulk, hy + 2], fill=fill_a(rgba(accent, 220)))

    return body_w, body_h, hx, hy


def draw_blade(draw, x0, y0, angle_deg, length, accent, width=5):
    ang = math.radians(angle_deg)
    ex = x0 + math.cos(ang) * length
    ey = y0 + math.sin(ang) * length
    draw.line([x0, y0, ex, ey], fill=rgba(accent), width=width)
    draw.polygon(
        [
            (ex, ey),
            (ex - math.cos(ang + 0.4) * 10, ey - math.sin(ang + 0.4) * 10),
            (ex - math.cos(ang - 0.4) * 10, ey - math.sin(ang - 0.4) * 10),
        ],
        fill=rgba((255, 255, 255)),
    )


def draw_rifle(draw, x0, y0, accent, armor2, aim: bool):
    bx, by = x0 + 14, y0 - 2
    draw.rounded_rectangle([bx, by - 3, bx + 34, by + 3], radius=2, fill=rgba(armor2))
    draw.rounded_rectangle([bx + 28, by - 5, bx + 38, by + 5], radius=2, fill=rgba(armor2))
    draw.rectangle([bx + 4, by - 1, bx + 20, by + 1], fill=rgba(accent, 200))
    if aim:
        draw.line([bx + 38, by, bx + 48, by - 4], fill=rgba(accent, 180), width=2)


def draw_mace_sparks(draw, glow, x0, y0, angle_deg, accent, armor2):
    ang = math.radians(angle_deg)
    ex = x0 + math.cos(ang) * 28
    ey = y0 + math.sin(ang) * 28
    draw.line([x0, y0, ex, ey], fill=rgba(accent), width=4)
    draw.ellipse([ex - 8, ey - 8, ex + 8, ey + 8], fill=rgba(armor2))
    gd = ImageDraw.Draw(glow)
    for i in range(6):
        a = ang + (i - 2.5) * 0.35
        sx = ex + math.cos(a) * 14
        sy = ey + math.sin(a) * 14
        gd.line([ex, ey, sx, sy], fill=rgba(CYAN_SPARK, 200), width=2)
        gd.ellipse([sx - 3, sy - 3, sx + 3, sy + 3], fill=rgba(CYAN_SPARK, 220))


def draw_tall_shield(draw, x0, y0, bulk, accent, armor2):
    draw.polygon(
        [
            (x0 - 22 * bulk, y0 - 28),
            (x0 - 26 * bulk, y0 + 30),
            (x0 - 8 * bulk, y0 + 34),
            (x0 - 4 * bulk, y0 - 24),
        ],
        fill=rgba(armor2),
    )
    draw.line([(x0 - 18 * bulk, y0 - 20), (x0 - 14 * bulk, y0 + 22)], fill=rgba(accent, 200), width=3)


def draw_orbs(draw, glow, x0, y0, accent, t: float):
    gd = ImageDraw.Draw(glow)
    for i, ox in enumerate([-18, -8, 6]):
        oy = y0 - 10 + math.sin(t * math.pi * 2 + i) * 4
        r = 5
        draw.ellipse([x0 + ox - r, oy - r, x0 + ox + r, oy + r], fill=rgba(accent, 180))
        gd.ellipse([x0 + ox - r - 2, oy - r - 2, x0 + ox + r + 2, oy + r + 2], fill=rgba(accent, 80))


def draw_energy_shield(draw, glow, x0, y0, accent):
    pts = [(x0 + 18, y0 - 26), (x0 + 34, y0), (x0 + 28, y0 + 32), (x0 + 12, y0 + 28)]
    draw.polygon(pts, fill=rgba((40, 28, 56), 200))
    gd = ImageDraw.Draw(glow)
    gd.polygon(pts, outline=rgba(accent, 180))


def draw_claymore(draw, x0, y0, angle_deg, accent):
    ang = math.radians(angle_deg)
    length = 42
    ex = x0 + math.cos(ang) * length
    ey = y0 + math.sin(ang) * length
    draw.line([x0, y0, ex, ey], fill=rgba((180, 180, 190)), width=7)
    draw.polygon(
        [(ex, ey), (ex - math.cos(ang + 0.5) * 16, ey - math.sin(ang + 0.5) * 16), (ex - math.cos(ang - 0.5) * 16, ey - math.sin(ang - 0.5) * 16)],
        fill=rgba(accent),
    )


def draw_wispy_trail(draw, glow, x0, y0, accent, alpha: int):
    gd = ImageDraw.Draw(glow)
    for i in range(5):
        ox = -8 - i * 6
        oy = 8 + i * 4
        draw.ellipse([x0 + ox - 6, y0 + oy - 4, x0 + ox + 6, y0 + oy + 4], fill=rgba(accent, int(60 * alpha / 255)))
        gd.ellipse([x0 + ox - 8, y0 + oy - 6, x0 + ox + 8, y0 + oy + 6], fill=rgba(accent, 40))


def draw_scout_drone(draw, glow, cx, cy, bulk, accent, armor2, tilt):
    w, h = 28 * bulk, 12 * bulk
    pts = [
        (cx - w, cy),
        (cx - w * 0.3, cy - h - tilt),
        (cx + w * 0.3, cy - h + tilt),
        (cx + w, cy),
        (cx + w * 0.3, cy + h - tilt),
        (cx - w * 0.3, cy + h + tilt),
    ]
    draw.polygon(pts, fill=rgba(armor2))
    draw.ellipse([cx - 6, cy - 4, cx + 6, cy + 4], fill=rgba(accent, 220))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([cx - 10, cy - 8, cx + 10, cy + 8], fill=rgba(accent, 60))


def draw_missile_drone(draw, cx, cy, bulk, accent, armor2):
    draw.ellipse([cx - 14 * bulk, cy - 10 * bulk, cx + 14 * bulk, cy + 10 * bulk], fill=rgba(armor2))
    draw.polygon([(cx + 14 * bulk, cy), (cx + 32 * bulk, cy - 4), (cx + 32 * bulk, cy + 4)], fill=rgba(accent))
    draw.rounded_rectangle([cx - 22 * bulk, cy - 3, cx - 10 * bulk, cy + 3], radius=2, fill=rgba(armor2))


def draw_bomber_drone(draw, cx, cy, bulk, accent, armor2):
    draw.rounded_rectangle([cx - 18 * bulk, cy - 12 * bulk, cx + 10 * bulk, cy + 12 * bulk], radius=4, fill=rgba(armor2))
    draw.ellipse([cx + 8 * bulk, cy - 14 * bulk, cx + 22 * bulk, cy + 2 * bulk], fill=rgba(accent, 200))
    draw.line([cx - 18 * bulk, cy - 12 * bulk, cx - 26 * bulk, cy - 20 * bulk], fill=rgba(armor2), width=3)
    draw.line([cx - 18 * bulk, cy + 12 * bulk, cx - 26 * bulk, cy + 20 * bulk], fill=rgba(armor2), width=3)


def draw_sniper_drone(draw, cx, cy, bulk, accent, armor2):
    draw.ellipse([cx - 12 * bulk, cy - 8 * bulk, cx + 8 * bulk, cy + 8 * bulk], fill=rgba(armor2))
    draw.rounded_rectangle([cx + 4 * bulk, cy - 2, cx + 36 * bulk, cy + 2], radius=1, fill=rgba(armor2))
    draw.ellipse([cx + 30 * bulk, cy - 5, cx + 38 * bulk, cy + 5], fill=rgba(accent, 220))


def draw_hammer(draw, x0, y0, angle_deg, accent, armor2):
    ang = math.radians(angle_deg)
    ex = x0 + math.cos(ang) * 30
    ey = y0 + math.sin(ang) * 30
    draw.line([x0, y0, ex, ey], fill=rgba(armor2), width=5)
    hx = ex + math.cos(ang) * 8
    hy = ey + math.sin(ang) * 8
    draw.rounded_rectangle(
        [hx - 14, hy - 10, hx + 14, hy + 10],
        radius=3,
        fill=rgba(armor2),
    )
    draw.rectangle([hx - 12, hy - 2, hx + 12, hy + 2], fill=rgba(accent, 200))


def draw_war_machine(draw, x0, y0, bulk, accent, armor, armor2):
    draw.rounded_rectangle([x0 - 24 * bulk, y0 - 8, x0 + 24 * bulk, y0 + 28], radius=4, fill=rgba(armor))
    for gx in (-16, -4, 8):
        draw.rounded_rectangle([x0 + gx * bulk - 4, y0 - 18, x0 + gx * bulk + 4, y0 - 6], radius=2, fill=rgba(armor2))
        draw.ellipse([x0 + gx * bulk - 3, y0 - 16, x0 + gx * bulk + 3, y0 - 10], fill=rgba(accent, 200))
    draw.rounded_rectangle([x0 - 8, y0 + 28, x0 - 4, y0 + 38], radius=1, fill=rgba(armor2))
    draw.rounded_rectangle([x0 + 4, y0 + 28, x0 + 8, y0 + 38], radius=1, fill=rgba(armor2))


def draw_crab_fortress(draw, x0, y0, bulk, accent, armor, armor2):
    draw.rounded_rectangle([x0 - 28 * bulk, y0 - 6, x0 + 28 * bulk, y0 + 22], radius=6, fill=rgba(armor))
    draw.ellipse([x0 - 8, y0 - 2, x0 + 8, y0 + 10], fill=rgba(accent, 180))
    for leg_x in (-26, -12, 12, 26):
        draw.line([x0 + leg_x * bulk, y0 + 22, x0 + leg_x * bulk + (6 if leg_x < 0 else -6), y0 + 36], fill=rgba(armor2), width=4)
    draw.polygon([(x0 - 20 * bulk, y0 - 6), (x0, y0 - 22 * bulk), (x0 + 20 * bulk, y0 - 6)], fill=rgba(armor2))


def draw_coat_turret(draw, x0, y0, bulk, accent, armor, armor2):
    draw.polygon([(x0 - 14, y0 + 4), (x0 - 20, y0 + 32), (x0 + 6, y0 + 18)], fill=rgba(armor, 210))
    draw.polygon([(x0 + 14, y0 + 4), (x0 + 18, y0 + 30), (x0 + 2, y0 + 16)], fill=rgba(armor2, 200))
    draw.rounded_rectangle([x0 + 10, y0 - 22, x0 + 26, y0 - 8], radius=3, fill=rgba(armor2))
    draw.ellipse([x0 + 24, y0 - 16, x0 + 30, y0 - 10], fill=rgba(accent, 220))


def draw_staff(draw, glow, x0, y0, angle_deg, accent):
    ang = math.radians(angle_deg)
    ex = x0 + math.cos(ang) * 38
    ey = y0 + math.sin(ang) * 38
    draw.line([x0, y0, ex, ey], fill=rgba((80, 60, 90)), width=4)
    gd = ImageDraw.Draw(glow)
    gd.ellipse([ex - 10, ey - 10, ex + 10, ey + 10], fill=rgba(accent, 120))
    draw.ellipse([ex - 6, ey - 6, ex + 6, ey + 6], fill=rgba(accent, 230))


def draw_spectral(draw, glow, cx, cy, bulk, accent, alpha: int):
    gd = ImageDraw.Draw(glow)
    body = [
        (cx, cy - 22 * bulk),
        (cx + 18 * bulk, cy + 8),
        (cx + 8 * bulk, cy + 28 * bulk),
        (cx - 8 * bulk, cy + 28 * bulk),
        (cx - 18 * bulk, cy + 8),
    ]
    fill = rgba(accent, int(140 * alpha / 255))
    draw.polygon(body, fill=fill)
    gd.polygon(body, outline=rgba(accent, 80))
    for i in range(3):
        y = cy + 28 * bulk + i * 8
        draw.arc([cx - 20 + i * 4, y, cx + 20 - i * 4, y + 14], 0, 180, fill=rgba(accent, int(100 * alpha / 255)), width=2)


def draw_enemy_kind(
    draw: ImageDraw.ImageDraw,
    glow: Image.Image,
    kind: str,
    cx: float,
    cy: float,
    spec: dict,
    fac: dict,
    pose: dict,
    anim: str,
):
    accent = fac["accent"]
    armor = fac["armor"]
    armor2 = fac["armor2"]
    bulk = spec["bulk"] * (1.12 if spec.get("boss") else 1.0)
    fly_y = pose["fly_y"]
    y_base = cy + pose["bob"] + pose["jump"] + fly_y
    x0 = cx + pose["lean"] * 0.2
    wa = pose["weapon_angle"]
    alpha = pose["alpha_body"]
    t = pose.get("attack_swing", 0)

    mechanical = kind in {
        "scout_drone",
        "missile_drone",
        "bomber_drone",
        "sniper_drone",
        "war_machine",
        "fortress",
    }
    if not mechanical or kind in {"war_machine", "fortress"}:
        draw_shadow(draw, x0, cy, bulk, fly_y)

    if kind == "scout_drone":
        draw_scout_drone(draw, glow, x0, y_base - 8, bulk, accent, armor2, pose["fly_tilt"])
        return
    if kind == "missile_drone":
        draw_missile_drone(draw, x0, y_base - 6, bulk, accent, armor2)
        return
    if kind == "bomber_drone":
        draw_bomber_drone(draw, x0, y_base - 4, bulk, accent, armor2)
        return
    if kind == "sniper_drone":
        draw_sniper_drone(draw, x0, y_base - 10, bulk, accent, armor2)
        return
    if kind == "corrupted_wraith":
        draw_spectral(draw, glow, x0, y_base - 6, bulk, accent, alpha)
        return
    if kind == "fortress":
        draw_crab_fortress(draw, x0, y_base + 8, bulk, accent, armor, armor2)
        return
    if kind == "war_machine":
        draw_war_machine(draw, x0, y_base + 4, bulk, accent, armor, armor2)
        return

    lean_kind = "normal"
    if kind == "raptor":
        lean_kind = "hunched"
    elif kind == "void_stalker":
        lean_kind = "hood"

    if kind != "void_stalker":
        draw_legs(draw, x0, y_base, bulk, pose["leg"], armor, armor2, accent, pose["scale_y"])

    body_w, body_h, hx, hy = draw_torso_head(
        draw, x0, y_base, bulk, armor, armor2, accent, lean_kind, alpha
    )

    arm_y = y_base - 4
    if kind == "grunt":
        draw_blade(draw, x0 + 10, arm_y, wa, 32, accent)
    elif kind == "raptor":
        draw_blade(draw, x0 - 12, arm_y + 6, wa - 40, 22, accent, 3)
        draw_blade(draw, x0 + 14, arm_y + 4, wa + 30, 22, accent, 3)
    elif kind == "sentinel":
        draw_rifle(draw, x0 - 4, arm_y, accent, armor2, anim in {"ranged", "attack"})
    elif kind == "shocker":
        draw_mace_sparks(draw, glow, x0 + 12, arm_y, wa, accent, armor2)
    elif kind == "guardian":
        draw_tall_shield(draw, x0 - 18, y_base, bulk, accent, armor2)
        draw_blade(draw, x0 + 14, arm_y, wa, 24, accent, 4)
    elif kind == "drone_swarmer":
        draw.polygon([(x0 - 14, y_base + 4), (x0 - 18, y_base + 28), (x0 + 4, y_base + 14)], fill=rgba(armor, 210))
        draw_orbs(draw, glow, x0, y_base - 8, accent, t if anim == "special" else 0)
    elif kind == "shield_maiden":
        draw_energy_shield(draw, glow, x0, y_base, accent)
        draw.line([x0 + 20, arm_y, x0 + 20, arm_y + 36], fill=rgba(armor2), width=3)
        draw.polygon([(x0 + 20, arm_y - 8), (x0 + 28, arm_y), (x0 + 20, arm_y + 8)], fill=rgba(accent))
    elif kind == "executioner":
        draw_claymore(draw, x0 + 8, arm_y - 8, wa, accent)
    elif kind == "void_stalker":
        draw_wispy_trail(draw, glow, x0, y_base, accent, alpha)
        draw_torso_head(draw, x0, y_base, bulk * 0.9, armor, armor2, accent, "hood", alpha)
    elif kind == "steel_brute":
        draw_hammer(draw, x0 + 10, arm_y, wa, accent, armor2)
    elif kind == "chaos_engineer":
        draw_coat_turret(draw, x0, y_base, bulk, accent, armor, armor2)
    elif kind == "rift_reaper":
        draw_staff(draw, glow, x0 + 14, arm_y - 10, wa - 20, accent)
    else:
        draw_blade(draw, x0 + 10, arm_y, wa, 28, accent)

    if spec.get("boss"):
        draw.polygon(
            [(x0 - body_w, y_base - body_h - 6), (x0, y_base - body_h - 18), (x0 + body_w, y_base - body_h - 6)],
            fill=rgba(accent, 160),
        )


def render_frame(enemy_id: str, anim: str, frame: int) -> Image.Image:
    spec = dict(ENEMY_SPECS[enemy_id])
    fac = FACTIONS[spec["faction"]]
    kind = spec["kind"]
    img = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    glow = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    pose = pose_offsets(anim, frame, spec)
    draw_enemy_kind(draw, glow, kind, FW / 2, FH / 2 + 8, spec, fac, pose, anim)
    glow = glow.filter(ImageFilter.GaussianBlur(1.2))
    return Image.alpha_composite(glow, img)


def make_enemy_assets(enemy_id: str) -> None:
    out_dir = ASSETS / "enemies" / enemy_id
    sheet = Image.new("RGBA", (FW * COLS, FH * len(ANIMS)), (0, 0, 0, 0))
    for ri, anim in enumerate(ANIMS):
        for ci in range(COLS):
            frame = render_frame(enemy_id, anim, ci)
            sheet.paste(frame, (ci * FW, ri * FH), frame)
    track_save(sheet, out_dir / "spritesheet.png")
    idle = render_frame(enemy_id, "idle", 0)
    track_save(idle, out_dir / "idle.png")
    portrait = idle.resize((192, 256), Image.Resampling.NEAREST)
    track_save(portrait, out_dir / "portrait.png")


def draw_projectile(kind: str) -> Image.Image:
    w, h = 96, 48
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    gd = ImageDraw.Draw(glow)
    cx, cy = 24, h // 2
    colors = {
        "bullet": (200, 200, 210),
        "plasma": (255, 120, 40),
        "electric": CYAN_SPARK,
        "missile": (255, 59, 59),
        "laser": (255, 59, 59),
        "rift": (0, 229, 255),
        "energy_wave": (123, 44, 255),
        "explosive": (255, 180, 40),
    }
    c = colors.get(kind, (255, 255, 255))

    if kind == "bullet":
        d.ellipse([cx - 6, cy - 4, cx + 6, cy + 4], fill=rgba(c))
        d.line([cx + 6, cy, cx + 40, cy], fill=rgba(c), width=2)
    elif kind == "plasma":
        d.ellipse([cx - 10, cy - 10, cx + 14, cy + 10], fill=rgba(c, 200))
        gd.ellipse([cx - 14, cy - 14, cx + 18, cy + 14], fill=rgba(c, 80))
    elif kind == "electric":
        pts = [(cx, cy), (cx + 12, cy - 8), (cx + 20, cy + 6), (cx + 32, cy - 4), (cx + 44, cy)]
        d.line(pts, fill=rgba(c), width=3)
        gd.line(pts, fill=rgba(c, 100), width=6)
    elif kind == "missile":
        d.polygon([(cx - 8, cy), (cx + 20, cy - 6), (cx + 20, cy + 6)], fill=rgba(c))
        d.rectangle([cx + 20, cy - 4, cx + 36, cy + 4], fill=rgba((60, 60, 70)))
        d.polygon([(cx + 36, cy - 8), (cx + 44, cy), (cx + 36, cy + 8)], fill=rgba((255, 200, 80)))
    elif kind == "laser":
        d.rectangle([cx - 4, cy - 2, cx + 56, cy + 2], fill=rgba(c, 230))
        gd.rectangle([cx - 6, cy - 6, cx + 58, cy + 6], fill=rgba(c, 60))
    elif kind == "rift":
        d.arc([cx - 8, cy - 16, cx + 40, cy + 16], -40, 40, fill=rgba(c), width=5)
        d.arc([cx, cy - 12, cx + 48, cy + 12], -35, 35, fill=rgba(c, 140), width=3)
    elif kind == "energy_wave":
        for i in range(3):
            d.arc([cx + i * 8, cy - 14 + i * 2, cx + 36 + i * 8, cy + 14 - i * 2], -30, 30, fill=rgba(c, 220 - i * 40), width=4)
    elif kind == "explosive":
        d.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], fill=rgba(c))
        d.line([cx - 8, cy - 14, cx - 4, cy - 20], fill=rgba((80, 50, 30)), width=2)
        gd.ellipse([cx - 16, cy - 16, cx + 16, cy + 16], fill=rgba(c, 70))
    else:
        d.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=rgba(c))
    glow = glow.filter(ImageFilter.GaussianBlur(1.5))
    return Image.alpha_composite(glow, img)


def draw_hazard(kind: str) -> Image.Image:
    size = 96
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    gd = ImageDraw.Draw(glow)
    cx, cy = size // 2, size // 2 + 8

    if kind == "laser_turret":
        d.rounded_rectangle([cx - 20, cy - 8, cx + 20, cy + 16], radius=4, fill=rgba((32, 36, 48)))
        d.polygon([(cx - 6, cy - 8), (cx + 6, cy - 8), (cx + 4, cy - 22), (cx - 4, cy - 22)], fill=rgba((48, 52, 64)))
        d.line([cx, cy - 22, cx + 28, cy - 28], fill=rgba((255, 59, 59)), width=4)
        gd.line([cx + 8, cy - 24, cx + 40, cy - 30], fill=rgba((255, 59, 59), 80), width=8)
    elif kind == "spike_trap":
        for i in range(-3, 4):
            x = cx + i * 10
            d.polygon([(x - 5, cy + 16), (x, cy - 20), (x + 5, cy + 16)], fill=rgba((120, 125, 135)))
        d.rectangle([cx - 34, cy + 16, cx + 34, cy + 24], fill=rgba((60, 64, 72)))
    elif kind == "electric_floor":
        d.rectangle([cx - 36, cy + 8, cx + 36, cy + 20], fill=rgba((40, 44, 52)))
        for i in range(-2, 3):
            pts = [(cx + i * 14 - 6, cy + 14), (cx + i * 14, cy - 8), (cx + i * 14 + 6, cy + 14)]
            d.line(pts, fill=rgba(CYAN_SPARK), width=3)
            gd.line(pts, fill=rgba(CYAN_SPARK, 90), width=6)
    elif kind == "falling_debris":
        d.polygon([(cx - 24, cy + 20), (cx - 8, cy - 18), (cx + 20, cy + 8)], fill=rgba((90, 85, 80)))
        d.polygon([(cx + 8, cy - 22), (cx + 28, cy - 4), (cx + 12, cy + 18)], fill=rgba((70, 68, 65)))
        gd.line([cx, cy - 28, cx, cy - 40], fill=rgba((255, 200, 80), 120), width=2)
    elif kind == "explosive_barrel":
        d.rounded_rectangle([cx - 18, cy - 22, cx + 18, cy + 22], radius=6, fill=rgba((100, 70, 40)))
        d.rectangle([cx - 18, cy - 6, cx + 18, cy - 2], fill=rgba((255, 59, 59)))
        d.text((cx - 6, cy - 4), "!", fill=rgba((255, 255, 255)))
        gd.ellipse([cx - 22, cy - 26, cx + 22, cy + 26], fill=rgba((255, 120, 40), 50))
    else:
        d.ellipse([cx - 20, cy - 20, cx + 20, cy + 20], outline=rgba((200, 200, 200)), width=2)

    glow = glow.filter(ImageFilter.GaussianBlur(1.2))
    return Image.alpha_composite(glow, img)


def write_manifest() -> None:
    path = ASSETS / "enemies" / "manifest.txt"
    lines = [
        "# SHADOW//RUN enemy assets",
        f"frame={FW}x{FH}",
        f"cols={COLS}",
        "anims=" + ",".join(ANIMS),
        "enemies=" + ",".join(ENEMY_IDS),
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n")
    global files_created
    files_created += 1


def main() -> None:
    global files_created
    files_created = 0
    print("Generating enemy sprite sheets...")
    for eid in ENEMY_IDS:
        make_enemy_assets(eid)
        print(f"  {eid}")

    print("Generating projectiles...")
    proj_dir = ASSETS / "projectiles"
    for pk in PROJECTILES:
        track_save(draw_projectile(pk), proj_dir / f"{pk}.png")

    print("Generating hazards...")
    haz_dir = ASSETS / "hazards"
    for hk in HAZARDS:
        frame = draw_hazard(hk)
        track_save(frame, haz_dir / f"{hk}.png")
        track_save(frame.copy(), haz_dir / f"{hk}_idle.png")

    write_manifest()
    print(f"Done. Files created: {files_created}")


if __name__ == "__main__":
    main()
