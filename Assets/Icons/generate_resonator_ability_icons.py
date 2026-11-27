"""Produce the five Resonator branch/milestone icons in the game's jewel palette."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).parent
S = 3
SIZE = 96
CYAN = (87, 220, 255, 255)
PALE = (227, 250, 255, 255)
VIOLET = (180, 111, 255, 255)
GOLD = (255, 207, 126, 255)
INK = (9, 19, 36, 255)
EDGE = (75, 117, 154, 255)


def make_icon(kind):
    s = S
    im = Image.new("RGBA", (SIZE*s, SIZE*s), (0,0,0,0))
    glow = Image.new("RGBA", im.size, (0,0,0,0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((18*s, 18*s, 78*s, 78*s), fill=(50, 185, 255, 35))
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(8*s)))
    d = ImageDraw.Draw(im)
    def p(v): return [(round(x*s),round(y*s)) for x,y in v]
    def line(v,c,w=2): d.line(p(v),fill=c,width=max(1,round(w*s)),joint="curve")
    def circle(box,fill=None,outline=None,w=1):
        d.ellipse(tuple(round(x*s) for x in box),fill=fill,outline=outline,width=max(1,round(w*s)))
    # A bespoke enamel seal gives all icons a coherent family frame.
    d.rounded_rectangle((9*s,9*s,87*s,87*s),radius=19*s,fill=INK,outline=EDGE,width=2*s)
    d.rounded_rectangle((13*s,13*s,83*s,83*s),radius=16*s,outline=(53,83,116,255),width=s)
    circle((27,27,69,69), (17,34,57,255), (94,149,184,255), 1.2)
    if kind == "returning_tone":
        # An echo path folds back as a resonant ring.
        line([(30,58),(42,58),(53,47),(43,36),(35,43)], CYAN, 3)
        d.polygon(p([(32,40),(36,45),(39,38)]),fill=PALE)
        for r,c in [(8,CYAN),(14,VIOLET)]:
            d.arc((round((48-r)*s),round((49-r)*s),round((48+r)*s),round((49+r)*s)),210,35,fill=c,width=2*s)
        circle((45,46,51,52),PALE)
    elif kind == "scattered_chord":
        # One bright note splits into a clean two-target chord.
        d.polygon(p([(47,28),(52,42),(47,47),(42,42)]), fill=PALE, outline=CYAN)
        line([(47,46),(37,59)],CYAN,2.5); line([(47,46),(59,59)],VIOLET,2.5)
        circle((32,56,42,66),CYAN,PALE,1); circle((54,56,64,66),VIOLET,PALE,1)
        circle((35,59,39,63),PALE); circle((57,59,61,63),PALE)
    elif kind == "string_memory":
        # A continuous knotted string binds three notes into a loop.
        line([(34,58),(34,41),(47,33),(62,42),(62,58),(48,65),(34,58)],VIOLET,2.5)
        line([(34,49),(47,58),(62,49)],CYAN,2.5)
        for x,y,c in [(34,41,CYAN),(62,42,PALE),(48,65,GOLD)]: circle((x-3,y-3,x+3,y+3),c,INK,1)
        circle((44,45,52,53),(24,53,79,255),CYAN,1)
    elif kind == "overtone":
        # Two frequencies, one fundamental and one lilting overtone.
        line([(28,51),(34,51),(38,39),(43,63),(48,45),(53,55),(58,47),(65,47)],CYAN,2.5)
        line([(28,61),(36,61),(41,56),(46,58),(52,54),(58,56),(65,56)],VIOLET,1.6)
        circle((36,35,40,39),PALE); circle((60,43,64,47),GOLD)
    elif kind == "perfect_resonance":
        # A flawless centered crystal sends out evenly spaced harmonic rays.
        for a in range(0,360,45):
            import math
            r1,r2=13,20
            x1,y1=48+math.cos(math.radians(a))*r1,48+math.sin(math.radians(a))*r1
            x2,y2=48+math.cos(math.radians(a))*r2,48+math.sin(math.radians(a))*r2
            line([(x1,y1),(x2,y2)], GOLD if a%90==0 else CYAN,1.5)
        d.polygon(p([(48,31),(57,46),(48,65),(39,46)]),fill=(128,227,255,255),outline=PALE)
        d.polygon(p([(48,31),(48,65),(39,46)]),fill=(76,172,221,255))
        line([(48,35),(48,59)],PALE,1)
    # Small signature ticks and consistent lower glint.
    line([(31,76),(40,76)],(110,152,182,180),.7)
    line([(56,76),(65,76)],(110,152,182,180),.7)
    return im.resize((SIZE,SIZE),Image.Resampling.LANCZOS)


if __name__ == "__main__":
    for kind in ["returning_tone","scattered_chord","string_memory","overtone","perfect_resonance"]:
        make_icon(kind).save(OUT/f"resonator_{kind}.png", optimize=True)
    print("Generated five Resonator ability icons")
