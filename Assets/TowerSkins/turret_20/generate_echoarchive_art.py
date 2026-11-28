"""Generate Echoarchive's 48 tower stage sprites, 1 portrait, and 4 FX graphics (53 files)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math

ROOT = Path(__file__).resolve().parent
SIZE = 384
S = 3  # 128 logical units -> 384 px

# Each skin family represents a completely distinct archival monument with its own geometry & palette.
FAMILIES = {
    "default": {
        "ink": (10, 18, 36, 255),
        "base": (42, 62, 102, 255),
        "plate": (74, 106, 156, 255),
        "trim": (224, 178, 86, 255),
        "trim_hi": (255, 228, 148, 255),
        "pri": (78, 224, 245, 255),
        "sec": (244, 198, 92, 255),
        "core": (235, 253, 255, 255),
        "glow": (62, 205, 245, 62),
    },
    "skin_01": {  # Astral Scriptorium — ivory marble & celestial gold astrolabe
        "ink": (24, 24, 48, 255),
        "base": (166, 178, 206, 255),
        "plate": (222, 228, 242, 255),
        "trim": (225, 175, 72, 255),
        "trim_hi": (255, 240, 175, 255),
        "pri": (86, 172, 255, 255),
        "sec": (255, 212, 108, 255),
        "core": (246, 252, 255, 255),
        "glow": (96, 174, 255, 60),
    },
    "skin_02": {  # Crimson Codex — obsidian ironbound lacquer & molten ruby wax-seal
        "ink": (28, 12, 18, 255),
        "base": (66, 28, 36, 255),
        "plate": (118, 42, 52, 255),
        "trim": (212, 134, 62, 255),
        "trim_hi": (255, 208, 124, 255),
        "pri": (255, 76, 86, 255),
        "sec": (255, 168, 66, 255),
        "core": (255, 232, 205, 255),
        "glow": (255, 74, 64, 66),
    },
    "skin_03": {  # Jade Chronicle — carved celadon jade dais & bronze calipers
        "ink": (12, 30, 26, 255),
        "base": (38, 92, 78, 255),
        "plate": (82, 164, 132, 255),
        "trim": (196, 152, 84, 255),
        "trim_hi": (242, 214, 146, 255),
        "pri": (72, 244, 172, 255),
        "sec": (182, 255, 212, 255),
        "core": (235, 255, 245, 255),
        "glow": (58, 236, 164, 62),
    },
    "xp1": {  # Clockwork Oracle — midnight brass & rose-gold astronomical gearworks
        "ink": (24, 18, 18, 255),
        "base": (88, 60, 52, 255),
        "plate": (148, 102, 78, 255),
        "trim": (232, 168, 128, 255),
        "trim_hi": (255, 224, 188, 255),
        "pri": (255, 186, 82, 255),
        "sec": (255, 118, 146, 255),
        "core": (255, 246, 220, 255),
        "glow": (255, 172, 72, 65),
    },
    "xp2": {  # Eternal Grimoire — transcendent astral amethyst & gold hyper-sanctum
        "ink": (18, 12, 38, 255),
        "base": (58, 36, 106, 255),
        "plate": (112, 74, 182, 255),
        "trim": (244, 202, 102, 255),
        "trim_hi": (255, 246, 198, 255),
        "pri": (122, 238, 255, 255),
        "sec": (232, 124, 255, 255),
        "core": (250, 254, 255, 255),
        "glow": (162, 148, 255, 72),
    },
}


def q(v):
    return int(round(v * S))


def pts(arr):
    return [(q(x), q(y)) for x, y in arr]


def rot(cx, cy, dx, dy, ang):
    ca, sa = math.cos(ang), math.sin(ang)
    return (cx + dx * ca - dy * sa, cy + dx * sa + dy * ca)


def reg_poly(cx, cy, r, sides, angle_off=0.0):
    return [
        (cx + math.cos(angle_off + i * math.tau / sides) * r,
         cy + math.sin(angle_off + i * math.tau / sides) * r)
        for i in range(sides)
    ]


class ArtCanvas:
    def __init__(self, fam, stage):
        self.fam = fam
        self.stage = stage
        self.c = FAMILIES[fam]
        self.im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        r = 34 + stage * 1.9
        gd.ellipse((q(64 - r), q(64 - r), q(64 + r), q(64 + r)), fill=self.c["glow"])
        glow = glow.filter(ImageFilter.GaussianBlur(q(9)))
        self.im.alpha_composite(glow)
        self.d = ImageDraw.Draw(self.im)

    def poly(self, p, fill, edge=None, w=1.0):
        pp = pts(p)
        self.d.polygon(pp, fill=fill)
        if edge:
            self.d.line(pp + [pp[0]], fill=edge, width=max(1, q(w)), joint="curve")

    def ell(self, cx, cy, rx, ry=None, fill=None, edge=None, w=1.0):
        if ry is None:
            ry = rx
        box = (q(cx - rx), q(cy - ry), q(cx + rx), q(cy + ry))
        self.d.ellipse(box, fill=fill, outline=edge, width=max(1, q(w)) if edge else 1)

    def arc(self, cx, cy, r, a0, a1, color, w=1.5):
        box = (q(cx - r), q(cy - r), q(cx + r), q(cy + r))
        self.d.arc(box, a0, a1, fill=color, width=max(1, q(w)))

    def line(self, p, color, w=1.2):
        self.d.line(pts(p), fill=color, width=max(1, q(w)), joint="curve")

    def rrect(self, x0, y0, x1, y1, rad, fill, edge=None, w=1.0):
        self.d.rounded_rectangle((q(x0), q(y0), q(x1), q(y1)), radius=q(rad),
                                 fill=fill, outline=edge, width=max(1, q(w)) if edge else 1)


def draw_stage(fam, stage):
    # Top-down turret oriented pointing RIGHT (+X toward (114, 64))
    cv = ArtCanvas(fam, stage)
    c = cv.c
    cx, cy = 62.0, 64.0

    # Soft ground shadow
    cv.ell(cx, cy + 3, 40 + stage * 0.6, 36 + stage * 0.5, fill=(0, 0, 0, 72))

    # 1. Family-distinct architectural base chassis
    if fam == "default":
        # Octagonal bronze-rimmed chrono-dais with rear archive spines
        cv.poly(reg_poly(cx, cy, 35 + stage * 0.6, 8, math.pi / 8), c["base"], c["ink"], 1.3)
        cv.poly(reg_poly(cx, cy, 29 + stage * 0.4, 8, math.pi / 8), c["plate"], c["trim"], 0.9)
        if stage >= 3:
            for sgn in (-1, 1):
                cv.poly([(cx - 12, cy + sgn * 24), (cx - 28 - stage * 0.9, cy + sgn * (31 + stage * 0.6)),
                         (cx - 22, cy + sgn * 15)], c["plate"], c["ink"], 1.0)
                cv.ell(cx - 22 - stage * 0.5, cy + sgn * (25 + stage * 0.4), 2.5, fill=c["pri"], edge=c["ink"], w=0.6)
    elif fam == "skin_01":
        # Star-temple 12-point marble medallion + corner pillars
        cv.ell(cx, cy, 36 + stage * 0.5, fill=c["base"], edge=c["ink"], w=1.3)
        cv.poly(reg_poly(cx, cy, 32 + stage * 0.4, 6, 0.0), c["plate"], c["trim"], 1.0)
        for i in range(4 if stage < 5 else 6):
            ang = i * math.tau / (4 if stage < 5 else 6) + math.pi / 4
            px, py = cx + math.cos(ang) * 32, cy + math.sin(ang) * 32
            cv.ell(px, py, 4.4, fill=c["trim"], edge=c["ink"], w=0.8)
            cv.ell(px, py, 1.9, fill=c["pri"])
    elif fam == "skin_02":
        # Ironbound diamond tome-vault with crimson notched armor wings
        cv.poly([(cx - 38, cy - 18), (cx - 8, cy - 35), (cx + 26, cy - 22), (cx + 30, cy),
                 (cx + 26, cy + 22), (cx - 8, cy + 35), (cx - 38, cy + 18)], c["base"], c["ink"], 1.4)
        cv.poly([(cx - 30, cy - 13), (cx - 6, cy - 27), (cx + 19, cy - 15),
                 (cx + 19, cy + 15), (cx - 6, cy + 27), (cx - 30, cy + 13)], c["plate"], c["trim"], 0.9)
        if stage >= 4:
            for sgn in (-1, 1):
                cv.poly([(cx - 6, cy + sgn * 25), (cx - 18, cy + sgn * 41), (cx + 6, cy + sgn * 34)],
                        c["trim"], c["ink"], 0.9)
    elif fam == "skin_03":
        # Jade pagoda octagon + curved bronze dragon caliper flanks
        cv.poly(reg_poly(cx, cy, 36 + stage * 0.5, 4, 0.0), c["base"], c["ink"], 1.3)
        cv.poly(reg_poly(cx, cy, 31 + stage * 0.4, 8, math.pi / 8), c["plate"], c["trim"], 1.0)
        for sgn in (-1, 1):
            cv.arc(cx, cy + sgn * 4, 34, 25 if sgn > 0 else 205, 155 if sgn > 0 else 335, c["trim"], 2.3)
    elif fam == "xp1":
        # Clockwork gear chassis with precision escapement teeth
        teeth = 12
        gear = []
        r_in, r_out = 31 + stage * 0.4, 37 + stage * 0.6
        for i in range(teeth * 2):
            ang = i * math.tau / (teeth * 2)
            rr = r_out if (i % 2 == 0) else r_in
            gear.append((cx + math.cos(ang) * rr, cy + math.sin(ang) * rr))
        cv.poly(gear, c["base"], c["ink"], 1.2)
        cv.ell(cx, cy, 28, fill=c["plate"], edge=c["trim"], w=1.0)
        for i in range(4):
            ang = i * math.pi / 2 + math.pi / 4
            cv.ell(cx + math.cos(ang) * 19, cy + math.sin(ang) * 19, 6.2, fill=c["trim"], edge=c["ink"], w=0.8)
    elif fam == "xp2":
        # Radiant astral-amethyst sanctum with sweeping prismatic rear wings
        wing_span = 34 + stage * 1.4
        for sgn in (-1, 1):
            cv.poly([(cx - 10, cy + sgn * 16), (cx - 34, cy + sgn * wing_span),
                     (cx - 44, cy + sgn * (wing_span * 0.65)), (cx - 24, cy + sgn * 10)],
                    c["plate"], c["ink"], 1.1)
            cv.line([(cx - 14, cy + sgn * 18), (cx - 34, cy + sgn * (wing_span - 4))], c["pri"], 1.4)
        cv.poly(reg_poly(cx, cy, 31 + stage * 0.5, 6, 0.0), c["base"], c["trim"], 1.2)
        cv.poly(reg_poly(cx, cy, 24 + stage * 0.4, 6, math.pi / 6), c["plate"], c["trim_hi"], 0.9)

    # 2. Astrolabe / Chronometer Ring System (evolves sharply across stages 1..8)
    ring_r = 22.0 + min(4, stage // 2) * 1.1
    cv.ell(cx, cy, ring_r, fill=c["ink"], edge=c["trim"], w=1.4)
    cv.arc(cx, cy, ring_r - 3.5, -55, 55, c["pri"], 1.8)
    cv.arc(cx, cy, ring_r - 3.5, 125, 235, c["sec"], 1.8)
    if stage >= 2:
        # Cardinal calibration ticks
        tick_cnt = 4 + (stage // 2) * 2
        for i in range(tick_cnt):
            ang = i * math.tau / tick_cnt
            p0 = (cx + math.cos(ang) * (ring_r - 1.5), cy + math.sin(ang) * (ring_r - 1.5))
            p1 = (cx + math.cos(ang) * (ring_r + 2.6), cy + math.sin(ang) * (ring_r + 2.6))
            cv.line([p0, p1], c["trim_hi"], 1.0)
    if stage >= 5:
        # Outer orbital archive halo
        orad = ring_r + 6.5
        cv.arc(cx, cy, orad, -42, 42, c["pri"], 1.4)
        cv.arc(cx, cy, orad, 138, 222, c["pri"], 1.4)
        cv.ell(cx, cy - orad, 2.3, fill=c["core"], edge=c["pri"], w=0.5)
        cv.ell(cx, cy + orad, 2.3, fill=c["core"], edge=c["pri"], w=0.5)

    # 3. Twin Archival Emitter Arms / Quill Rails pointing RIGHT (+X toward Muzzle!)
    rail_len = 34.0 + stage * 2.1
    rail_spread = 11.5 - (stage * 0.25 if stage <= 4 else 1.0)
    if fam in ("skin_02", "xp2"):
        # Swept bladed tuning-prongs
        for sgn in (-1, 1):
            cv.poly([
                (cx + 6, cy + sgn * 13),
                (cx + rail_len - 4, cy + sgn * (rail_spread * 0.55)),
                (cx + rail_len + 6, cy + sgn * 2.8),
                (cx + 12, cy + sgn * 6.5),
            ], c["plate"], c["ink"], 1.1)
            cv.line([(cx + 14, cy + sgn * 8.0), (cx + rail_len + 2, cy + sgn * 3.5)], c["pri"], 1.3)
    else:
        # Precision astrolabe rails + brass tip conductors
        for sgn in (-1, 1):
            cv.poly([
                (cx + 5, cy + sgn * 12),
                (cx + rail_len, cy + sgn * (rail_spread * 0.65)),
                (cx + rail_len + 3, cy + sgn * (rail_spread * 0.35)),
                (cx + 10, cy + sgn * 5.2),
            ], c["trim"], c["ink"], 1.0)
            cv.line([(cx + 14, cy + sgn * 7.5), (cx + rail_len + 1, cy + sgn * (rail_spread * 0.42))],
                    c["trim_hi"], 1.0)

    # Center archival focus needle / barrel spire pointing +X
    spire_tip = cx + rail_len + 8.5
    cv.poly([
        (cx + 4, cy - 6.0),
        (spire_tip, cy),
        (cx + 4, cy + 6.0),
        (cx - 8, cy),
    ], c["plate"], c["ink"], 1.1)
    cv.line([(cx + 8, cy), (spire_tip - 2, cy)], c["core"], 1.7)
    # Glowing emitter crystal at muzzle tip
    cv.ell(spire_tip - 2, cy, 3.8 + stage * 0.25, fill=c["pri"], edge=c["core"], w=0.9)
    cv.ell(spire_tip - 2, cy, 1.8, fill=c["core"])

    # 4. Central Archival Codex / Folio Prism Core (grows in intricacy across stages 1..8)
    core_r = 11.0 + stage * 0.55
    # Open luminous folio pages inside the astrolabe cradle
    cv.poly([
        (cx - core_r * 0.85, cy - core_r * 0.65),
        (cx, cy - core_r * 0.92),
        (cx + core_r * 0.85, cy - core_r * 0.65),
        (cx + core_r * 0.85, cy + core_r * 0.65),
        (cx, cy + core_r * 0.92),
        (cx - core_r * 0.85, cy + core_r * 0.65),
    ], c["base"], c["trim"], 1.1)
    # Glowing recorded glyphs inside folio
    for dy in (-4.5, 0.0, 4.5):
        cv.line([(cx - core_r * 0.48, cy + dy), (cx - 1.8, cy + dy * 0.7)], c["sec"], 1.0)
        cv.line([(cx + 1.8, cy + dy * 0.7), (cx + core_r * 0.48, cy + dy)], c["pri"], 1.0)
    # Central luminous diamond/orb
    cv.poly([(cx - 6.5, cy), (cx, cy - 6.5), (cx + 6.5, cy), (cx, cy + 6.5)], c["pri"], c["core"], 0.9)
    cv.ell(cx, cy, 3.0 + stage * 0.2, fill=c["core"])

    if stage >= 7:
        # High-stage radiant archival crest rings & floating rune nodes
        for idx in range(stage - 4):
            ang = math.pi + (idx - (stage - 5) * 0.5) * 0.55
            nx, ny = cx + math.cos(ang) * (ring_r + 11.5), cy + math.sin(ang) * (ring_r + 11.5)
            cv.ell(nx, ny, 3.4, fill=c["sec"], edge=c["ink"], w=0.8)
            cv.ell(nx, ny, 1.5, fill=c["core"])

    return cv.im


def draw_portrait():
    # 512x512 bespoke Legendary Archival Astrolabe & Folio Portrait
    W = 512
    im = Image.new("RGBA", (W, W), (10, 17, 34, 255))
    d = ImageDraw.Draw(im)

    # Rich deep astral indigo gradient background
    for y in range(W):
        t = y / (W - 1)
        r = int(10 + 14 * math.sin(t * math.pi))
        g = int(17 + 26 * math.sin(t * math.pi))
        b = int(38 + 38 * math.sin(t * math.pi))
        d.line([(0, y), (W, y)], fill=(r, g, b, 255))

    # Subtle radial cyan-gold aura
    glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((106, 90, 406, 390), fill=(52, 198, 240, 88))
    gd.ellipse((156, 140, 356, 340), fill=(248, 200, 96, 68))
    glow = glow.filter(ImageFilter.GaussianBlur(28))
    im.alpha_composite(glow)
    d = ImageDraw.Draw(im)

    # Fine star-chart background rings & constellation dots
    cx, cy = 256, 236
    for rr, col in [(178, (72, 112, 162, 120)), (152, (98, 210, 238, 130)), (120, (232, 184, 92, 150))]:
        d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=col, width=2)
    for i in range(18):
        ang = i * math.tau / 18.0
        px = cx + math.cos(ang) * (165 + (i % 3) * 14)
        py = cy + math.sin(ang) * (165 + (i % 3) * 14)
        d.ellipse((px - 2.5, py - 2.5, px + 2.5, py + 2.5), fill=(210, 244, 255, 190))

    # Ornate pedestals & archival wings
    d.polygon([(128, 376), (384, 376), (424, 412), (88, 412)], fill=(38, 58, 98, 255), outline=(228, 182, 92, 255), width=3)
    d.polygon([(156, 356), (356, 356), (380, 378), (132, 378)], fill=(64, 96, 146, 255), outline=(255, 224, 144, 255), width=2)

    # Outer gimbal astrolabe arcs
    d.arc((cx - 134, cy - 134, cx + 134, cy + 134), 195, 345, fill=(78, 228, 248, 255), width=7)
    d.arc((cx - 134, cy - 134, cx + 134, cy + 134), 15, 165, fill=(238, 188, 92, 255), width=7)
    d.arc((cx - 104, cy - 104, cx + 104, cy + 104), 0, 360, fill=(228, 182, 86, 255), width=5)

    # Open floating luminous Codex / Folio at heart
    d.polygon([(176, 178), (256, 158), (336, 178), (324, 294), (256, 314), (188, 294)],
              fill=(24, 40, 74, 255), outline=(244, 202, 108, 255), width=4)
    d.line([(256, 160), (256, 312)], fill=(255, 228, 152, 255), width=3)
    for row in range(4):
        yy = 198 + row * 21
        d.line([(198, yy), (242, yy - 5)], fill=(96, 232, 255, 240), width=4)
        d.line([(270, yy - 5), (314, yy)], fill=(255, 206, 104, 240), width=4)

    # Floating radiant Echo Crystal above center spine
    d.polygon([(256, 114), (288, 198), (256, 282), (224, 198)], fill=(84, 232, 255, 255), outline=(240, 254, 255, 255), width=3)
    d.polygon([(256, 138), (272, 198), (256, 258), (240, 198)], fill=(232, 254, 255, 255))

    # Card border frame matching Turret_19 portrait
    d.rounded_rectangle((12, 12, W - 12, W - 12), radius=34, outline=(228, 184, 92, 255), width=4)
    d.rounded_rectangle((22, 22, W - 22, W - 22), radius=26, outline=(86, 212, 240, 190), width=2)
    im.save(ROOT / "portrait.png")


def draw_fx_textures():
    fx_dir = ROOT / "fx"
    fx_dir.mkdir(parents=True, exist_ok=True)

    # 1. projectile.png (64x32 glowing archival glyph bolt)
    p = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
    pg = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
    pgd = ImageDraw.Draw(pg)
    pgd.ellipse((6, 6, 58, 26), fill=(72, 224, 248, 165))
    pg = pg.filter(ImageFilter.GaussianBlur(4))
    p.alpha_composite(pg)
    pd = ImageDraw.Draw(p)
    pd.polygon([(8, 16), (38, 7), (58, 16), (38, 25)], fill=(78, 228, 248, 255), outline=(255, 228, 148, 255), width=2)
    pd.polygon([(20, 16), (40, 11), (53, 16), (40, 21)], fill=(238, 254, 255, 255))
    p.save(fx_dir / "projectile.png")

    # 2. hit_impact.png (96x96 archival starburst sigil impact)
    hi = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    hg = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    hgd = ImageDraw.Draw(hg)
    hgd.ellipse((14, 14, 82, 82), fill=(82, 226, 250, 140))
    hg = hg.filter(ImageFilter.GaussianBlur(7))
    hi.alpha_composite(hg)
    hd = ImageDraw.Draw(hi)
    hd.ellipse((18, 18, 78, 78), outline=(244, 198, 92, 255), width=3)
    hd.ellipse((28, 28, 68, 68), outline=(88, 232, 252, 255), width=3)
    for i in range(8):
        ang = i * math.tau / 8.0
        r0, r1 = (16, 44) if i % 2 == 0 else (20, 36)
        hd.line([(48 + math.cos(ang) * r0, 48 + math.sin(ang) * r0),
                 (48 + math.cos(ang) * r1, 48 + math.sin(ang) * r1)],
                fill=(238, 254, 255, 255), width=3)
    hd.ellipse((39, 39, 57, 57), fill=(238, 254, 255, 255))
    hi.save(fx_dir / "hit_impact.png")

    # 3. record_gauge.png (96x96 ornate chrono-dial bezel for recording gauge)
    rg = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rg)
    rd.ellipse((8, 8, 88, 88), fill=(10, 18, 36, 175), outline=(228, 180, 86, 255), width=4)
    rd.ellipse((16, 16, 80, 80), outline=(78, 224, 245, 210), width=2)
    for i in range(12):
        ang = i * math.tau / 12.0
        r_in = 33 if i % 3 == 0 else 36
        rd.line([(48 + math.cos(ang) * r_in, 48 + math.sin(ang) * r_in),
                 (48 + math.cos(ang) * 40, 48 + math.sin(ang) * 40)],
                fill=(255, 224, 144, 240), width=2 if i % 3 == 0 else 1)
    rg.save(fx_dir / "record_gauge.png")

    # 4. target_marker.png (96x96 rotating archival lock reticle)
    tm = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    td = ImageDraw.Draw(tm)
    for a0, a1 in [(18, 72), (108, 162), (198, 252), (288, 342)]:
        td.arc((10, 10, 86, 86), a0, a1, fill=(78, 228, 250, 255), width=5)
        td.arc((20, 20, 76, 76), a0 + 6, a1 - 6, fill=(244, 198, 92, 245), width=3)
    for ang in (0, math.pi * 0.5, math.pi, math.pi * 1.5):
        td.polygon([
            (48 + math.cos(ang) * 46, 48 + math.sin(ang) * 46),
            (48 + math.cos(ang - 0.14) * 35, 48 + math.sin(ang - 0.14) * 35),
            (48 + math.cos(ang + 0.14) * 35, 48 + math.sin(ang + 0.14) * 35),
        ], fill=(255, 228, 148, 255))
    tm.save(fx_dir / "target_marker.png")


if __name__ == "__main__":
    count = 0
    for fam in FAMILIES:
        out_dir = ROOT / fam
        out_dir.mkdir(parents=True, exist_ok=True)
        for st in range(1, 9):
            draw_stage(fam, st).save(out_dir / f"stage_{st:02d}.png")
            count += 1
    draw_portrait()
    draw_fx_textures()
    print(f"Generated {count} stages + 1 portrait + 4 fx textures = {count + 5} graphics")
