"""
Power Thief — thumbnail generator (star arc edition)
Player sprite centred in front; 10 core stars in a clean arc behind.
Spacing is mathematically guaranteed — no overlaps.
Run from project root: python assets/make_thumbnail.py
"""
from PIL import Image, ImageDraw, ImageFont
import math, os

BASE = os.path.dirname(__file__)
W, H = 1280, 720

# ── Core star colours (matches in-game element colours) ───────────────────────
CORES = [
    ("Fire",      (242,  89,  26)),   # orange-red   — far left
    ("Dash",      (128,  38, 166)),   # purple
    ("Clone",     ( 77, 204,  77)),   # green
    ("Phase",     (179, 217, 255)),   # ice-blue
    ("Explosion", (230, 140,  26)),   # amber
    ("Ice",       ( 77, 184, 242)),   # cyan
    ("Lightning", (242, 230,  51)),   # yellow
    ("Shield",    (158, 148, 122)),   # stone-grey
    ("Summon",    (133,  51, 184)),   # violet
    ("Poison",    (102, 225,  89)),   # lime         — far right
]

# ── Star geometry ─────────────────────────────────────────────────────────────
STAR_OUTER = 42    # outer point radius  (star bounding circle = 84 px diameter)
STAR_INNER = 17    # inner notch radius

# ── Arc layout ────────────────────────────────────────────────────────────────
# 10 stars, evenly spaced horizontally across the canvas.
# Step = (x_end - x_start) / 9 = 113 px  >  84 px star diameter → guaranteed gap.
X_START = 125
X_END   = 1155
N       = len(CORES)
X_STEP  = (X_END - X_START) / (N - 1)   # 113.3 px between centres

# Gentle sinusoidal lift: edges sit lower, centre stars peak highest.
Y_EDGE   = 390    # y at both ends of the arc
Y_PEAK   = 250    # y at the centre of the arc  (clear of title text)

# ── Canvas ────────────────────────────────────────────────────────────────────
canvas = Image.new("RGBA", (W, H), (12, 10, 20, 255))

# ── Draw each star ────────────────────────────────────────────────────────────
overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(overlay)

def star_polygon(cx, cy, outer, inner):
    pts = []
    for i in range(10):
        a = math.radians(-90.0 + i * 36.0)
        r = outer if i % 2 == 0 else inner
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts

for i, (name, col) in enumerate(CORES):
    t   = i / (N - 1)
    cx  = X_START + t * (X_END - X_START)
    # sin(π·t) rises from 0 → 1 → 0, giving the arc lift
    cy  = Y_EDGE - math.sin(math.pi * t) * (Y_EDGE - Y_PEAK)

    # Soft glow (larger star, low opacity)
    glow_pts = star_polygon(cx, cy, STAR_OUTER + 18, STAR_INNER + 8)
    glow_col = (min(255, col[0] + 40), min(255, col[1] + 40), min(255, col[2] + 40), 55)
    d.polygon(glow_pts, fill=glow_col)

    # Outer glow ring
    glow_pts2 = star_polygon(cx, cy, STAR_OUTER + 8, STAR_INNER + 4)
    glow_col2 = (min(255, col[0] + 20), min(255, col[1] + 20), min(255, col[2] + 20), 110)
    d.polygon(glow_pts2, fill=glow_col2)

    # Main star
    pts = star_polygon(cx, cy, STAR_OUTER, STAR_INNER)
    d.polygon(pts, fill=col + (255,))

canvas = Image.alpha_composite(canvas, overlay)

# ── Player sprite ─────────────────────────────────────────────────────────────
PLAYER_SCALE = 9
player_path  = os.path.join(BASE, "sprites/player_sprite.png")
sheet  = Image.open(player_path).convert("RGBA")
frame  = sheet.crop((0, 0, 32, 32))
player = frame.resize((32 * PLAYER_SCALE, 32 * PLAYER_SCALE), Image.NEAREST)

px = (W - player.width)  // 2
py = H // 2 + 40          # slightly below canvas centre
canvas.alpha_composite(player, (px, py))

# ── Text ──────────────────────────────────────────────────────────────────────
draw = ImageDraw.Draw(canvas)

font_big = font_sub = None
for candidate in [
    "C:/Windows/Fonts/arialbd.ttf",
    "C:/Windows/Fonts/arial.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
]:
    if os.path.exists(candidate):
        font_big = ImageFont.truetype(candidate, 92)
        font_sub = ImageFont.truetype(candidate, 30)
        break

if font_big is None:
    font_big = ImageFont.load_default()
    font_sub  = font_big

tx = W // 2
draw.text((tx + 4, 32 + 4), "POWER THIEF", font=font_big, fill=(0, 0, 0, 200),     anchor="mt")
draw.text((tx,     32),      "POWER THIEF", font=font_big, fill=(220, 200, 255, 255), anchor="mt")
draw.text((tx, H - 50),     "steal their power. survive.", font=font_sub, fill=(130, 110, 170, 210), anchor="mt")

# ── Save ──────────────────────────────────────────────────────────────────────
out = os.path.join(BASE, "thumbnail.png")
canvas.convert("RGB").save(out)
print(f"Saved: {out}")
