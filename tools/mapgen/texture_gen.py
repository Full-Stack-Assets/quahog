#!/usr/bin/env python3
"""Procedural Godot texture + material generator for the Mount Hope map.

Emits tileable PNG textures and matching Godot 4 StandardMaterial3D .tres files,
fully procedurally (no network, no API keys, no Google Maps imagery — so output
is always shippable and ToS-clean). Surfaces are authored to read like the
South Coast: red-brick mills, painted wooden triple-deckers, granite/glass
downtown, plus ground surfaces (asphalt, concrete, cobblestone, grass, dirt,
water, wood, metal).

Two texture families:
  * facade_* — luminance-driven (near-greyscale). The map tints each building by
    vertex colour, so the facade texture supplies grain + window rows only and
    must stay neutral. These regenerate the in-game nb_* wall textures.
  * ground/prop surfaces — full colour, used directly.

Usage:
  python3 texture_gen.py surface brick --size 512 --out ./out
  python3 texture_gen.py facades          # regen the 3 in-game wall textures
  python3 texture_gen.py all --out ./lib  # the full reference library
  python3 texture_gen.py list

Materials reference the PNG at <res-prefix>/<name>.png (default res://assets/
textures/surfaces). Pass --res-prefix to match wherever the PNGs land in-project.
"""
import argparse, math, os, random
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.normpath(os.path.join(HERE, "..", "..", "QUAHOG_GODOT1"))
WALLS = os.path.join(PROJECT, "assets", "textures", "walls")

WARM = (240, 205, 140)   # a lit window at dusk (further tinted by vertex colour)
DARK = (40, 44, 52)      # an unlit window


# ---------------------------------------------------------------- helpers -----
def _noise(img, amt, seed=0):
    rnd = random.Random(seed)
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b = px[x, y][:3]
            n = rnd.randint(-amt, amt)
            px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)))


def _window(d, x0, y0, x1, y1, lit, frame):
    d.rectangle([x0 - 2, y0 - 2, x1 + 2, y1 + 2], fill=frame)
    d.rectangle([x0, y0, x1, y1], fill=WARM if lit else DARK)
    mx, my = (x0 + x1) // 2, (y0 + y1) // 2
    d.line([(mx, y0), (mx, y1)], fill=frame)
    d.line([(x0, my), (x1, my)], fill=frame)
    if not lit:
        d.line([(x0 + 2, y0 + 3), (mx - 2, my - 2)], fill=(70, 78, 90))


def _scale(fn, size):
    """Author at 256 then scale, so tuned pixel constants stay consistent."""
    img = fn(256)
    if size != 256:
        img = img.resize((size, size), Image.LANCZOS)
    return img


# --------------------------------------------------------------- surfaces -----
def facade_brick(S=256):
    rnd = random.Random(7)
    img = Image.new("RGB", (S, S), (150, 150, 150)); d = ImageDraw.Draw(img)
    ch, bw = 16, 34
    for row, y in enumerate(range(0, S, ch)):
        off = (bw // 2) if row % 2 else 0
        for x in range(-bw, S + bw, bw):
            v = 150 + rnd.randint(-14, 14)
            d.rectangle([x + off, y, x + off + bw - 2, y + ch - 2], fill=(v, v - 2, v - 4))
        d.line([(0, y), (S, y)], fill=(118, 116, 116))
    for x in range(0, S, bw):
        d.line([(x, 0), (x, S)], fill=(120, 118, 118))
    _noise(img, 8, 7)
    for bx in (40, 168):
        _window(d, bx, 54, bx + 48, 180, rnd.random() < 0.30, (175, 172, 168))
    return img


def facade_clapboard(S=256):
    rnd = random.Random(11)
    img = Image.new("RGB", (S, S), (196, 196, 192)); d = ImageDraw.Draw(img)
    lap = 14
    for y in range(0, S, lap):
        d.rectangle([0, y, S, y + lap - 1], fill=(196 + rnd.randint(-6, 6),) * 3)
        d.line([(0, y + lap - 1), (S, y + lap - 1)], fill=(150, 150, 148))
    _noise(img, 5, 11)
    d.rectangle([0, 0, 6, S], fill=(232, 232, 228))
    d.rectangle([S - 6, 0, S, S], fill=(232, 232, 228))
    _window(d, 96, 48, 160, 186, rnd.random() < 0.35, (236, 236, 230))
    return img


def facade_downtown(S=256):
    img = Image.new("RGB", (S, S), (140, 144, 150)); d = ImageDraw.Draw(img)
    _noise(img, 6, 5); rnd = random.Random(5)
    for cx in (10, 69, 128, 187):
        _window(d, cx, 16, cx + 49, 150, rnd.random() < 0.25, (172, 176, 182))
    d.rectangle([0, 150, S, 176], fill=(120, 124, 130))
    d.rectangle([0, 176, S, S], fill=(150, 154, 160))
    return img


def asphalt(S=256):
    img = Image.new("RGB", (S, S), (46, 47, 50)); d = ImageDraw.Draw(img)
    rnd = random.Random(3)
    for _ in range(S * 12):                       # aggregate speckle
        x, y = rnd.randrange(S), rnd.randrange(S)
        g = rnd.randint(60, 110)
        d.point((x, y), fill=(g, g, g + 4))
    for _ in range(5):                            # hairline cracks
        x, y = rnd.randrange(S), rnd.randrange(S)
        for _ in range(rnd.randint(20, 60)):
            d.point((x % S, y % S), fill=(28, 28, 30))
            x += rnd.randint(-2, 2); y += rnd.randint(-1, 3)
    _noise(img, 6, 3)
    return img


def concrete(S=256):
    img = Image.new("RGB", (S, S), (176, 176, 172)); d = ImageDraw.Draw(img)
    _noise(img, 10, 9); rnd = random.Random(9)
    for _ in range(6):                            # faint stains
        x, y = rnd.randrange(S), rnd.randrange(S); r = rnd.randint(14, 40)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(160, 160, 156))
    d.line([(0, S // 2), (S, S // 2)], fill=(150, 150, 147))   # control joints
    d.line([(S // 2, 0), (S // 2, S)], fill=(150, 150, 147))
    return img.filter(ImageFilter.SMOOTH)


def cobblestone(S=256):
    img = Image.new("RGB", (S, S), (96, 92, 88)); d = ImageDraw.Draw(img)
    rnd = random.Random(13); step = 32
    for row, y in enumerate(range(0, S, step)):
        off = (step // 2) if row % 2 else 0
        for x in range(-step, S + step, step):
            cx, cy = x + off + step // 2, y + step // 2
            r = step // 2 - 3
            g = rnd.randint(90, 150)
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(g, g - 6, g - 12))
    _noise(img, 7, 13)
    return img.filter(ImageFilter.SMOOTH)


def grass(S=256):
    img = Image.new("RGB", (S, S), (58, 96, 44)); d = ImageDraw.Draw(img)
    rnd = random.Random(21)
    for _ in range(S * 18):                        # blades
        x, y = rnd.randrange(S), rnd.randrange(S)
        g = rnd.randint(70, 140)
        d.line([(x, y), (x + rnd.randint(-1, 1), y - rnd.randint(2, 5))], fill=(40, g, 38))
    _noise(img, 10, 21)
    return img


def dirt(S=256):
    img = Image.new("RGB", (S, S), (104, 80, 56)); d = ImageDraw.Draw(img)
    rnd = random.Random(31)
    for _ in range(S * 8):                          # pebbles / clods
        x, y = rnd.randrange(S), rnd.randrange(S); v = rnd.randint(-26, 26)
        d.point((x, y), fill=(104 + v, 80 + v, 56 + v))
    _noise(img, 12, 31)
    return img.filter(ImageFilter.SMOOTH)


def water(S=256):
    img = Image.new("RGB", (S, S), (28, 64, 92)); d = ImageDraw.Draw(img)
    for y in range(0, S, 6):                         # wave lines (tileable in x)
        amp = 2 + (y % 12) * 0.2
        pts = [(x, int(y + amp * math.sin(x * 0.08 + y * 0.3))) for x in range(0, S + 1, 4)]
        d.line(pts, fill=(54, 104, 140), width=1)
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    _noise(img, 5, 41)
    return img


def wood(S=256):
    img = Image.new("RGB", (S, S), (120, 84, 50)); d = ImageDraw.Draw(img)
    rnd = random.Random(51); plank = 42
    for px_ in range(0, S, plank):
        base = 120 + rnd.randint(-18, 18)
        d.rectangle([px_, 0, px_ + plank - 2, S], fill=(base, int(base * 0.7), int(base * 0.42)))
        for _ in range(rnd.randint(3, 6)):          # grain streaks
            gx = px_ + rnd.randint(2, plank - 3)
            d.line([(gx, 0), (gx + rnd.randint(-2, 2), S)], fill=(base - 24, int(base * 0.6) - 18, int(base * 0.35)))
        d.line([(px_, 0), (px_, S)], fill=(70, 48, 28))   # plank gap
    _noise(img, 6, 51)
    return img


def metal(S=256):
    img = Image.new("RGB", (S, S), (150, 152, 156)); d = ImageDraw.Draw(img)
    rnd = random.Random(61)
    for y in range(S):                               # brushed horizontal grain
        v = 150 + int(10 * math.sin(y * 0.5)) + rnd.randint(-6, 6)
        d.line([(0, y), (S, y)], fill=(v, v + 2, v + 6))
    for _ in range(40):                              # scratches
        x, y = rnd.randrange(S), rnd.randrange(S); ln = rnd.randint(8, 40)
        d.line([(x, y), (x + ln, y + rnd.randint(-2, 2))], fill=(190, 192, 196))
    return img


SURFACES = {
    "facade_brick": facade_brick, "facade_clapboard": facade_clapboard,
    "facade_downtown": facade_downtown, "asphalt": asphalt, "concrete": concrete,
    "cobblestone": cobblestone, "grass": grass, "dirt": dirt, "water": water,
    "wood": wood, "metal": metal,
}

# Per-surface PBR (roughness, metallic, uses vertex-colour tint?).
PBR = {
    "facade_brick": (0.95, 0.0, True), "facade_clapboard": (0.9, 0.0, True),
    "facade_downtown": (0.6, 0.0, True), "asphalt": (0.95, 0.0, False),
    "concrete": (0.92, 0.0, False), "cobblestone": (0.9, 0.0, False),
    "grass": (1.0, 0.0, False), "dirt": (1.0, 0.0, False),
    "water": (0.12, 0.2, False), "wood": (0.8, 0.0, False),
    "metal": (0.35, 0.9, False),
}


def write_material(name, out_dir, res_prefix):
    rough, metal_v, vtint = PBR.get(name, (0.9, 0.0, False))
    tres = (
        '[gd_resource type="StandardMaterial3D" load_steps=2 format=3]\n\n'
        f'[ext_resource type="Texture2D" path="{res_prefix}/{name}.png" id="1"]\n\n'
        '[resource]\n'
        f'resource_name = "{name}"\n'
        'albedo_texture = ExtResource("1")\n'
        f'roughness = {rough}\n'
        f'metallic = {metal_v}\n'
        'uv1_triplanar = false\n'
        + ('vertex_color_use_as_albedo = true\n' if vtint else '')
    )
    with open(os.path.join(out_dir, name + ".tres"), "w") as f:
        f.write(tres)


def emit(name, size, out_dir, materials, res_prefix):
    os.makedirs(out_dir, exist_ok=True)
    img = _scale(SURFACES[name], size).filter(ImageFilter.SMOOTH)
    img.save(os.path.join(out_dir, name + ".png"))
    if materials:
        write_material(name, out_dir, res_prefix)
    return os.path.join(out_dir, name + ".png")


def main():
    ap = argparse.ArgumentParser(description="Procedural Godot texture/material generator")
    sub = ap.add_subparsers(dest="cmd", required=True)
    for c in ("surface",):
        p = sub.add_parser(c); p.add_argument("name", choices=sorted(SURFACES))
    sub.add_parser("all"); sub.add_parser("facades"); sub.add_parser("list")
    for p in ap._subparsers._group_actions[0].choices.values():
        p.add_argument("--size", type=int, default=512)
        p.add_argument("--out", default=os.path.join(HERE, "texture_library"))
        p.add_argument("--no-materials", action="store_true")
        p.add_argument("--res-prefix", default="res://assets/textures/surfaces")
    args = ap.parse_args()

    if args.cmd == "list":
        for n in sorted(SURFACES):
            r, m, t = PBR[n]
            print(f"  {n:18} roughness={r} metallic={m} vertex_tint={t}")
        return

    mats = not args.no_materials
    if args.cmd == "facades":
        # Regenerate the three in-game wall textures in place (luminance, used by
        # MapLoader). Keep nb_* filenames so the map keeps loading them.
        names = {"facade_brick": "nb_brick", "facade_clapboard": "nb_clapboard",
                 "facade_downtown": "nb_downtown"}
        for src, dst in names.items():
            img = _scale(SURFACES[src], args.size).filter(ImageFilter.SMOOTH)
            img.save(os.path.join(WALLS, dst + ".png"))
            print("wrote", os.path.join(WALLS, dst + ".png"))
        return

    targets = sorted(SURFACES) if args.cmd == "all" else [args.name]
    for n in targets:
        print("wrote", emit(n, args.size, args.out, mats, args.res_prefix))


if __name__ == "__main__":
    main()
