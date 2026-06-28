#!/usr/bin/env python3
"""Generate tileable facade textures matched to New Bedford / Fall River
architecture (red-brick textile mills & rowhouses, painted wooden triple-deckers,
downtown granite/glass). Authored from the documented look of these buildings —
luminance-based so the per-building vertex tint in map_loader still drives the
hue (brick-red / granite-grey / painted), while the texture adds the material
grain + window rows. One tile = ~one floor (WALL_TILE_U 4 m x WALL_TILE_V 3.2 m).
"""
import os, random
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..",
      "QUAHOG_GODOT1", "assets", "textures", "walls"))
W = H = 256
WARM = (240, 205, 140)   # a lit window at dusk (tinted by vertex colour)
DARK = (40, 44, 52)      # an unlit window


def _noise(img, amt):
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b = px[x, y][:3]
            n = random.randint(-amt, amt)
            px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)))


def _window(d, x0, y0, x1, y1, lit, frame):
    d.rectangle([x0 - 2, y0 - 2, x1 + 2, y1 + 2], fill=frame)              # trim/lintel
    col = WARM if lit else DARK
    d.rectangle([x0, y0, x1, y1], fill=col)
    # panes (mullions)
    mx = (x0 + x1) // 2
    my = (y0 + y1) // 2
    d.line([(mx, y0), (mx, y1)], fill=frame)
    d.line([(x0, my), (x1, my)], fill=frame)
    if not lit:  # faint sky reflection on glass
        d.line([(x0 + 2, y0 + 3), (mx - 2, my - 2)], fill=(70, 78, 90))


def brick():
    random.seed(7)
    img = Image.new("RGB", (W, H), (150, 150, 150))
    d = ImageDraw.Draw(img)
    ch, bw = 16, 34
    for row, y in enumerate(range(0, H, ch)):
        off = (bw // 2) if row % 2 else 0
        for x in range(-bw, W + bw, bw):
            xb = x + off
            v = 150 + random.randint(-14, 14)
            d.rectangle([xb, y, xb + bw - 2, y + ch - 2], fill=(v, v - 2, v - 4))
        d.line([(0, y), (W, y)], fill=(118, 116, 116))            # bed mortar
    for x in range(0, W, bw):
        d.line([(x, 0), (x, H)], fill=(120, 118, 118))
    _noise(img, 8)
    # two window bays per tile (mills are mostly glass); granite lintels lighter
    for bx in (40, 168):
        lit = random.random() < 0.30
        _window(d, bx, 54, bx + 48, 180, lit, (175, 172, 168))
    return img


def clapboard():
    random.seed(11)
    img = Image.new("RGB", (W, H), (196, 196, 192))
    d = ImageDraw.Draw(img)
    lap = 14
    for y in range(0, H, lap):
        d.rectangle([0, y, W, y + lap - 1], fill=(196 + random.randint(-6, 6),) * 3)
        d.line([(0, y + lap - 1), (W, y + lap - 1)], fill=(150, 150, 148))  # lap shadow
    _noise(img, 5)
    # one tall 6-over-6 window with white trim, centred; corner boards at edges
    d.rectangle([0, 0, 6, H], fill=(232, 232, 228))
    d.rectangle([W - 6, 0, W, H], fill=(232, 232, 228))
    lit = random.random() < 0.35
    _window(d, 96, 48, 160, 186, lit, (236, 236, 230))
    return img


def downtown():
    random.seed(5)
    img = Image.new("RGB", (W, H), (140, 144, 150))
    d = ImageDraw.Draw(img)
    _noise(img, 6)
    # curtain-wall grid: big windows, light mullions, spandrel band
    cols = [10, 69, 128, 187]
    for cx in cols:
        lit = random.random() < 0.25
        _window(d, cx, 16, cx + 49, 150, lit, (172, 176, 182))
    d.rectangle([0, 150, W, 176], fill=(120, 124, 130))   # spandrel band
    d.rectangle([0, 176, W, H], fill=(150, 154, 160))
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in [("nb_brick", brick), ("nb_clapboard", clapboard), ("nb_downtown", downtown)]:
        img = fn().filter(ImageFilter.SMOOTH)
        img.save(os.path.join(OUT, name + ".png"))
        print("wrote", name + ".png")


if __name__ == "__main__":
    main()
