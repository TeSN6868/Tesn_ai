from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import os

SIZE = 1024

img = Image.new("RGBA", (SIZE, SIZE))
px = img.load()

# ============================================================
# PREMIUM BLUE GRADIENT
# ============================================================
top = (5, 28, 78)
bottom = (82, 190, 245)

for y in range(SIZE):
    t = y / (SIZE - 1)
    t = t * t * (3 - 2 * t)

    for x in range(SIZE):
        dx = x - SIZE * 0.5
        dy = y - SIZE * 0.35
        glow = max(0, 1 - math.sqrt(dx*dx + dy*dy) / 720)

        r = int(top[0] * (1-t) + bottom[0] * t + glow * 16)
        g = int(top[1] * (1-t) + bottom[1] * t + glow * 18)
        b = int(top[2] * (1-t) + bottom[2] * t + glow * 20)

        px[x, y] = (
            min(255, r),
            min(255, g),
            min(255, b),
            255
        )

# ============================================================
# CENTRAL LIGHT
# ============================================================
glow = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
gd = ImageDraw.Draw(glow)

gd.ellipse(
    (170, 110, 854, 794),
    fill=(255,255,255,28)
)

glow = glow.filter(ImageFilter.GaussianBlur(80))
img = Image.alpha_composite(img, glow)

draw = ImageDraw.Draw(img)

# ============================================================
# FONTS
# ============================================================
font_candidates = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf",
]

font_path = next(
    (p for p in font_candidates if os.path.exists(p)),
    None
)

if font_path is None:
    raise SystemExit("Font tidak ditemukan.")

font_bjo = ImageFont.truetype(font_path, 185)
font_ultimate = ImageFont.truetype(font_path, 82)
font_slogan = ImageFont.truetype(font_path, 38)

# ============================================================
# CENTER TEXT FUNCTION
# ============================================================
def center_text(text, font, y, fill, stroke_width=0, stroke_fill=None):
    box = draw.textbbox(
        (0,0),
        text,
        font=font,
        stroke_width=stroke_width
    )

    width = box[2] - box[0]
    x = (SIZE - width) // 2

    draw.text(
        (x, y),
        text,
        font=font,
        fill=fill,
        stroke_width=stroke_width,
        stroke_fill=stroke_fill or fill
    )

# ============================================================
# PREMIUM EMBLEM
# ============================================================
cx = SIZE // 2
cy = 365

# Outer glow rings
for radius, alpha in [
    (245, 35),
    (235, 45),
    (225, 60),
]:
    draw.ellipse(
        (
            cx-radius,
            cy-radius,
            cx+radius,
            cy+radius
        ),
        outline=(220,245,255,alpha),
        width=4
    )

# Main elegant ring
draw.ellipse(
    (
        cx-205,
        cy-205,
        cx+205,
        cy+205
    ),
    outline=(245,252,255,220),
    width=6
)

# Inner ring
draw.ellipse(
    (
        cx-178,
        cy-178,
        cx+178,
        cy+178
    ),
    outline=(210,240,255,120),
    width=3
)

# ============================================================
# B'JO
# ============================================================
text = "B'Jo"

box = draw.textbbox((0,0), text, font=font_bjo)
tw = box[2] - box[0]
x = (SIZE - tw) // 2
y = 265

# Soft shadow
draw.text(
    (x+7, y+9),
    text,
    font=font_bjo,
    fill=(0,18,55,150)
)

# Main pearl-white text
draw.text(
    (x, y),
    text,
    font=font_bjo,
    fill=(248,253,255,255),
    stroke_width=3,
    stroke_fill=(170,225,250,230)
)

# ============================================================
# ULTIMATE
# ============================================================
center_text(
    "Ultimate",
    font_ultimate,
    475,
    (245,252,255,255),
    2,
    (145,215,245,210)
)

# ============================================================
# DIVIDER
# ============================================================
draw.rounded_rectangle(
    (310, 585, 714, 591),
    radius=3,
    fill=(235,250,255,200)
)

# ============================================================
# SLOGAN
# ============================================================
center_text(
    "Connect. Share. Belong.",
    font_slogan,
    620,
    (240,250,255,245)
)

# ============================================================
# LOWER SHINE
# ============================================================
shine = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
sd = ImageDraw.Draw(shine)

sd.ellipse(
    (100, 700, 924, 1180),
    fill=(255,255,255,25)
)

shine = shine.filter(ImageFilter.GaussianBlur(70))
img = Image.alpha_composite(img, shine)

# ============================================================
# ROUNDED CORNERS
# ============================================================
mask = Image.new("L", (SIZE, SIZE), 0)
md = ImageDraw.Draw(mask)

md.rounded_rectangle(
    (0,0,SIZE-1,SIZE-1),
    radius=145,
    fill=255
)

final = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
final.paste(img, (0,0), mask)

# ============================================================
# SAVE
# ============================================================
os.makedirs("assets", exist_ok=True)

output = "assets/bjo_ultimate.png"
final.save(output, "PNG", optimize=True)

print()
print("======================================")
print(" B'JO ULTIMATE BERHASIL DIBUAT")
print("======================================")
print(output)
print(f"Ukuran: {SIZE} x {SIZE}")
