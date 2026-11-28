"""Generate Echoarchive's 5 ability icons, 3 stat icons, and usage medal_44."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math

OUT = Path(__file__).resolve().parent
S = 3
SIZE = 96

CYAN = (78, 224, 248, 255)
PALE = (232, 253, 255, 255)
GOLD = (248, 200, 96, 255)
GOLD_HI = (255, 238, 176, 255)
VIOLET = (176, 128, 255, 255)
CRIMSON = (255, 108, 122, 255)
EMERALD = (92, 238, 172, 255)
INK = (10, 18, 36, 255)
EDGE = (172, 146, 92, 255)


def make_ability_icon(kind: str) -> Image.Image:
    s = S
    im = Image.new("RGBA", (SIZE * s, SIZE * s), (0, 0, 0, 0))
    glow = Image.new("RGBA", im.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((16 * s, 16 * s, 80 * s, 80 * s), fill=(62, 198, 240, 42))
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(8 * s)))
    d = ImageDraw.Draw(im)

    def p(arr):
        return [(round(x * s), round(y * s)) for x, y in arr]

    def line(arr, col, w=2.2):
        d.line(p(arr), fill=col, width=max(1, round(w * s)), joint="curve")

    def circle(cx, cy, r, fill=None, outline=None, w=1.2):
        d.ellipse((round((cx - r) * s), round((cy - r) * s),
                   round((cx + r) * s), round((cy + r) * s)),
                  fill=fill, outline=outline, width=max(1, round(w * s)))

    # Enamel seal frame
    d.rounded_rectangle((8 * s, 8 * s, 88 * s, 88 * s), radius=19 * s, fill=INK, outline=EDGE, width=2 * s)
    d.rounded_rectangle((12 * s, 12 * s, 84 * s, 84 * s), radius=16 * s, outline=(62, 92, 134, 255), width=s)
    circle(48, 48, 22, (16, 30, 56, 255), (92, 138, 178, 255), 1.3)

    if kind == "echoarchive_choral_echo":
        # Central echo core splitting into main center arc (60%) + two outer arcs (20%/20%)
        circle(48, 33, 6.2, CYAN, PALE, 1.3)
        line([(48, 39), (48, 63)], PALE, 3.0)
        line([(48, 42), (31, 61)], GOLD, 2.3)
        line([(48, 42), (65, 61)], VIOLET, 2.3)
        circle(48, 64, 5.2, CYAN, PALE, 1.2)
        circle(30, 62, 4.2, GOLD, GOLD_HI, 1.0)
        circle(66, 62, 4.2, VIOLET, PALE, 1.0)
    elif kind == "echoarchive_big_binding":
        # Gilded open tome clasped inside expanded barrier ring (+25% cap)
        circle(48, 48, 19, None, GOLD, 2.2)
        d.polygon(p([(32, 37), (48, 33), (64, 37), (62, 59), (48, 63), (34, 59)]),
                  fill=(28, 52, 92, 255), outline=GOLD_HI, width=max(1, round(1.8 * s)))
        line([(48, 34), (48, 62)], GOLD_HI, 1.6)
        # Expanding upward cap arrows
        line([(48, 26), (48, 43)], CYAN, 2.4)
        d.polygon(p([(48, 22), (42, 30), (54, 30)]), fill=PALE)
    elif kind == "echoarchive_witness":
        # All-seeing archival eye + three elemental DoT droplets (poison, burn, bleed)
        d.arc((27 * s, 32 * s, 69 * s, 62 * s), 190, 350, fill=CYAN, width=round(2.6 * s))
        d.arc((27 * s, 32 * s, 69 * s, 62 * s), 10, 170, fill=GOLD, width=round(2.6 * s))
        circle(48, 47, 7.2, (24, 62, 96, 255), PALE, 1.5)
        circle(48, 47, 3.2, PALE)
        circle(33, 64, 4.0, EMERALD, PALE, 0.9)
        circle(48, 66, 4.0, GOLD, GOLD_HI, 0.9)
        circle(63, 64, 4.0, CRIMSON, PALE, 0.9)
    elif kind == "echoarchive_last_record":
        # Shattered target marker transferring a luminous 50% ink arc to the next node
        d.arc((24 * s, 35 * s, 44 * s, 55 * s), 30, 290, fill=GOLD, width=round(2.4 * s))
        line([(28, 39), (38, 49)], CRIMSON, 2.2)
        line([(38, 39), (28, 49)], CRIMSON, 2.2)
        line([(38, 43), (48, 34), (60, 44)], CYAN, 2.8)
        d.polygon(p([(63, 47), (54, 45), (59, 38)]), fill=PALE)
        circle(63, 55, 6.5, (28, 66, 98, 255), CYAN, 1.6)
        circle(63, 55, 2.8, PALE)
    elif kind == "echoarchive_synchronous_index":
        # Synchronized concentric astrolabe rings + golden index diamond (+10 pp share)
        circle(48, 48, 17.5, None, GOLD, 2.2)
        circle(48, 48, 12.0, None, CYAN, 2.0)
        d.polygon(p([(48, 34), (56, 48), (48, 62), (40, 48)]), fill=CYAN, outline=PALE, width=s)
        for ang in (0, math.pi * 0.5, math.pi, math.pi * 1.5):
            circle(48 + math.cos(ang) * 17.5, 48 + math.sin(ang) * 17.5, 2.8, GOLD_HI, INK, 0.8)

    return im.resize((SIZE, SIZE), Image.Resampling.LANCZOS)


def make_stat_icon(kind: str) -> Image.Image:
    sz = 64
    sc = 3
    im = Image.new("RGBA", (sz * sc, sz * sc), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    def c(v):
        return int(round(v * sc))

    if kind == "echo_cycle":
        d.ellipse((c(8), c(8), c(56), c(56)), fill=(16, 30, 56, 255), outline=(88, 224, 248, 255), width=c(3))
        d.arc((c(14), c(14), c(50), c(50)), -75, 215, fill=(248, 200, 96, 255), width=c(3))
        d.line([(c(32), c(32)), (c(32), c(18))], fill=(235, 253, 255, 255), width=c(3))
        d.line([(c(32), c(32)), (c(43), c(38))], fill=(248, 200, 96, 255), width=c(3))
        d.ellipse((c(29), c(29), c(35), c(35)), fill=(235, 253, 255, 255))
    elif kind == "echo_share":
        d.ellipse((c(8), c(8), c(56), c(56)), fill=(16, 30, 56, 255), outline=(248, 200, 96, 255), width=c(3))
        d.pieslice((c(15), c(15), c(49), c(49)), -90, 45, fill=(78, 224, 248, 255), outline=(235, 253, 255, 255), width=c(2))
        d.pieslice((c(15), c(15), c(49), c(49)), 45, 270, fill=(38, 66, 112, 255), outline=(248, 200, 96, 255), width=c(2))
    elif kind == "echo_cap":
        d.ellipse((c(8), c(8), c(56), c(56)), fill=(16, 30, 56, 255), outline=(176, 128, 255, 255), width=c(3))
        d.line([(c(16), c(18)), (c(48), c(18))], fill=(248, 200, 96, 255), width=c(4))
        d.line([(c(32), c(48)), (c(32), c(24))], fill=(78, 224, 248, 255), width=c(4))
        d.polygon([(c(32), c(21)), (c(22), c(33)), (c(42), c(33))], fill=(235, 253, 255, 255))

    return im.resize((sz, sz), Image.Resampling.LANCZOS)


def make_medal_44() -> Image.Image:
    # 256x256 ornate golden-laurel medallion matching medal_43.png
    W = 256
    sc = 2
    M = W * sc
    im = Image.new("RGBA", (M, M), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = M // 2, M // 2

    # Outer gold rim + inner purple royal field
    d.ellipse((14, 14, M - 14, M - 14), fill=(184, 134, 36, 255), outline=(62, 38, 12, 255), width=6)
    d.ellipse((24, 24, M - 24, M - 24), fill=(244, 198, 76, 255), outline=(255, 238, 158, 255), width=4)
    d.ellipse((46, 46, M - 46, M - 46), fill=(58, 20, 94, 255), outline=(138, 92, 24, 255), width=6)

    # Subtle purple texture rings
    for r in range(72, 200, 26):
        d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(84, 34, 128, 125), width=3)

    # Left & right golden laurel leaves along inner border
    for side in (-1, 1):
        for i in range(9):
            t = i / 8.0
            ang = math.pi * 0.5 + side * (0.28 + t * 1.95)
            lx = cx + math.cos(ang) * 194
            ly = cy + math.sin(ang) * 194
            leaf_ang = ang + side * 0.65
            dx, dy = math.cos(leaf_ang) * 20, math.sin(leaf_ang) * 20
            nx, ny = -math.sin(leaf_ang) * 9, math.cos(leaf_ang) * 9
            d.polygon([
                (lx - dx * 0.5, ly - dy * 0.5),
                (lx + nx, ly + ny),
                (lx + dx, ly + dy),
                (lx - nx, ly - ny),
            ], fill=(246, 202, 78, 255), outline=(120, 78, 16, 255), width=2)

    # Top & bottom golden fleur-de-lis crest finials
    for sgn in (-1, 1):
        py = cy + sgn * 224
        d.polygon([
            (cx, py + sgn * 24),
            (cx - 22, py - sgn * 4),
            (cx, py - sgn * 22),
            (cx + 22, py - sgn * 4),
        ], fill=(252, 212, 92, 255), outline=(108, 68, 14, 255), width=3)

    # Center glow
    glow = Image.new("RGBA", (M, M), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((cx - 110, cy - 110, cx + 110, cy + 110), fill=(255, 204, 82, 95))
    glow = glow.filter(ImageFilter.GaussianBlur(18))
    im.alpha_composite(glow)
    d = ImageDraw.Draw(im)

    # Central Golden Echoarchive Codex + Astrolabe Rings + Radiant Echo Waves
    d.arc((cx - 122, cy - 122, cx + 122, cy + 122), 205, 335, fill=(255, 224, 128, 255), width=9)
    d.arc((cx - 122, cy - 122, cx + 122, cy + 122), 25, 155, fill=(255, 224, 128, 255), width=9)
    d.ellipse((cx - 94, cy - 94, cx + 94, cy + 94), outline=(238, 184, 64, 255), width=8)
    # Open gilded book/folio
    d.polygon([
        (cx - 88, cy - 36), (cx, cy - 58), (cx + 88, cy - 36),
        (cx + 78, cy + 70), (cx, cy + 90), (cx - 78, cy + 70)
    ], fill=(224, 168, 52, 255), outline=(255, 242, 178, 255), width=4)
    d.line([(cx, cy - 58), (cx, cy + 90)], fill=(116, 72, 16, 255), width=5)
    for row in range(3):
        yy = cy - 18 + row * 24
        d.line([(cx - 64, yy), (cx - 16, yy - 6)], fill=(255, 244, 192, 255), width=5)
        d.line([(cx + 16, yy - 6), (cx + 64, yy)], fill=(255, 244, 192, 255), width=5)
    # Radiant center prism crystal
    d.polygon([(cx, cy - 108), (cx + 32, cy - 28), (cx, cy + 52), (cx - 32, cy - 28)],
              fill=(255, 236, 148, 255), outline=(146, 94, 18, 255), width=3)
    d.polygon([(cx, cy - 86), (cx + 16, cy - 28), (cx, cy + 30), (cx - 16, cy - 28)],
              fill=(255, 252, 224, 255))

    return im.resize((W, W), Image.Resampling.LANCZOS)


if __name__ == "__main__":
    for k in [
        "echoarchive_choral_echo",
        "echoarchive_big_binding",
        "echoarchive_witness",
        "echoarchive_last_record",
        "echoarchive_synchronous_index",
    ]:
        make_ability_icon(k).save(OUT / f"{k}.png")
    for k in ["echo_cycle", "echo_share", "echo_cap"]:
        make_stat_icon(k).save(OUT / f"{k}.png")
    make_medal_44().save(OUT / "medal_44.png")
    print("Generated 5 ability icons + 3 stat icons + medal_44.png")
