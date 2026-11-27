"""Draw the Resonator's six distinct art families (8 battle stages each)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math, random

ROOT = Path(__file__).parent
SCALE = 3
SIZE = 384

# Every family has its own silhouette and construction language; themed skins
# are drawn from scratch, never made by hue-shifting the default sprite.
PALETTES = {
    "default": {
        "ink": (12, 22, 42, 255), "metal": (77, 119, 158, 255),
        "silver": (190, 224, 238, 255), "light": (236, 253, 255, 255),
        "a": (75, 220, 255, 255), "b": (176, 111, 255, 255), "trim": (255, 211, 126, 255),
        "glow": (48, 193, 255, 58),
    },
    "skin_01": { # Cinder Resonance — an angular volcanic kiln
        "ink": (29, 18, 26, 255), "metal": (109, 49, 50, 255),
        "silver": (225, 133, 98, 255), "light": (255, 232, 190, 255),
        "a": (255, 92, 54, 255), "b": (255, 172, 68, 255), "trim": (255, 220, 126, 255),
        "glow": (255, 83, 40, 66),
    },
    "skin_02": { # Living Verdigris — a bioglass bloom / botanical resonator
        "ink": (13, 34, 35, 255), "metal": (39, 104, 89, 255),
        "silver": (137, 211, 166, 255), "light": (224, 255, 220, 255),
        "a": (71, 226, 164, 255), "b": (120, 204, 255, 255), "trim": (224, 207, 132, 255),
        "glow": (54, 238, 162, 55),
    },
    "skin_03": { # Solstice — a ceremonial solar instrument
        "ink": (41, 27, 23, 255), "metal": (148, 91, 47, 255),
        "silver": (239, 192, 112, 255), "light": (255, 249, 214, 255),
        "a": (255, 190, 72, 255), "b": (255, 113, 66, 255), "trim": (255, 238, 174, 255),
        "glow": (255, 177, 58, 57),
    },
    "xp1": { # Eclipse — crescent-shaped obsidian relic
        "ink": (20, 17, 42, 255), "metal": (71, 55, 111, 255),
        "silver": (161, 139, 222, 255), "light": (244, 230, 255, 255),
        "a": (176, 111, 255, 255), "b": (255, 108, 206, 255), "trim": (255, 207, 156, 255),
        "glow": (156, 81, 255, 58),
    },
    "xp2": { # Borealis — a crystalline tuning-fork / ice chime
        "ink": (13, 29, 47, 255), "metal": (49, 106, 143, 255),
        "silver": (147, 216, 237, 255), "light": (239, 255, 255, 255),
        "a": (81, 205, 255, 255), "b": (110, 255, 211, 255), "trim": (204, 164, 255, 255),
        "glow": (69, 192, 255, 62),
    },
}


def Q(v): return int(round(v * SCALE))
def P(points): return [(Q(x), Q(y)) for x, y in points]

class Canvas:
    def __init__(self, skin, stage):
        self.skin, self.stage = skin, stage
        self.c = PALETTES[skin]
        self.im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        # tightly cropped, soft energy aura remains transparent at the edge
        glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.ellipse((Q(22), Q(12), Q(106), Q(101)), fill=self.c["glow"])
        glow = glow.filter(ImageFilter.GaussianBlur(Q(9)))
        self.im.alpha_composite(glow)
        self.d = ImageDraw.Draw(self.im)
        self.shadow()

    def poly(self, pts, fill, edge=None, w=.9):
        pp=P(pts); self.d.polygon(pp, fill=fill)
        if edge: self.d.line(pp+[pp[0]], fill=edge, width=max(1,Q(w)), joint="curve")
    def line(self, pts, color, w=1, joint="curve"):
        self.d.line(P(pts), fill=color, width=max(1,Q(w)), joint=joint)
    def ell(self, box, fill=None, edge=None, w=.8):
        b=tuple(Q(x) for x in box); self.d.ellipse(b, fill=fill, outline=edge, width=max(1,Q(w)) if edge else 1)
    def arc(self, box, start, end, color, w=1):
        self.d.arc(tuple(Q(x) for x in box), start, end, fill=color, width=max(1,Q(w)))
    def round(self, box, r, fill, edge=None, w=.8):
        self.d.rounded_rectangle(tuple(Q(x) for x in box), radius=Q(r), fill=fill, outline=edge, width=max(1,Q(w)) if edge else 1)
    def shadow(self):
        sh=Image.new("RGBA", (SIZE,SIZE), (0,0,0,0)); d=ImageDraw.Draw(sh)
        d.ellipse((Q(22),Q(105),Q(106),Q(119)), fill=(0,0,0,108))
        sh=sh.filter(ImageFilter.GaussianBlur(Q(3))); self.im.alpha_composite(sh); self.d=ImageDraw.Draw(self.im)
    def stud(self,x,y,color=None,r=1.15):
        color = color or self.c["a"]
        self.ell((x-r,y-r,x+r,y+r),color,self.c["light"],.35)
        self.ell((x-r*.45,y-r*.55,x-r*.05,y-r*.15),(255,255,255,230))
    def pedestal(self, style="fine"):
        c=self.c
        if style=="kiln":
            self.poly([(25,103),(33,92),(46,96),(53,103),(75,103),(83,96),(97,92),(105,103),(100,115),(30,115)],c["ink"],c["metal"],2)
            self.poly([(31,104),(45,101),(53,106),(75,106),(83,101),(99,104),(96,111),(34,111)],c["metal"],c["silver"],.8)
            for x in (39,53,75,89): self.line([(x,106),(x+2,109)],c["a"],1)
        elif style=="organic":
            self.poly([(23,107),(34,100),(49,103),(58,108),(70,108),(79,103),(94,100),(105,107),(98,114),(30,114)],c["ink"],c["metal"],1.5)
            self.poly([(30,107),(45,105),(57,110),(71,110),(83,105),(98,107),(93,112),(35,112)],c["metal"],c["silver"],.8)
            for x in (39,51,77,89): self.ell((x-1,107,x+1,110),c["a"])
        elif style=="solar":
            self.poly([(20,106),(29,99),(43,99),(49,105),(79,105),(85,99),(99,99),(108,106),(102,115),(26,115)],c["ink"],c["trim"],1.8)
            self.poly([(27,106),(37,102),(48,104),(53,109),(75,109),(80,104),(92,102),(101,106),(97,112),(31,112)],c["metal"],c["light"],.9)
            self.arc((40,101,88,117),180,360,c["a"],1)
        elif style=="relic":
            self.poly([(24,108),(33,99),(48,102),(55,108),(73,108),(81,102),(96,99),(105,108),(96,115),(32,115)],c["ink"],c["b"],1.7)
            self.poly([(31,108),(42,103),(51,106),(58,111),(70,111),(78,106),(88,103),(99,108),(93,112),(36,112)],c["metal"],c["silver"],.8)
            self.line([(39,108),(56,110),(72,110),(89,108)],c["a"],.65)
        elif style=="ice":
            self.poly([(23,108),(32,97),(44,103),(52,108),(77,108),(85,103),(98,97),(106,108),(99,115),(29,115)],c["ink"],c["silver"],1.4)
            self.poly([(29,108),(39,103),(51,109),(76,109),(89,103),(100,108),(95,112),(34,112)],c["metal"],c["light"],.8)
            self.line([(39,108),(51,111),(76,111),(89,108)],c["b"],1)
        else:
            self.poly([(19,105),(27,94),(43,92),(54,99),(74,99),(85,92),(101,94),(109,105),(102,115),(26,115)],c["ink"],c["metal"],2)
            self.poly([(24,104),(32,97),(46,96),(55,101),(73,101),(82,96),(96,97),(104,104),(100,111),(28,111)],c["metal"],c["silver"],.9)
            for x in (36,50,64,78,92): self.stud(x,103,c["a"] if x%2 else c["b"],.8)


def draw_default(stage):
    x=Canvas("default",stage); c=x.c; s=stage
    x.pedestal()
    # Twin swept yoke, open strings, and precise orbital resonator rings.
    x.line([(46,98),(45,80),(52,69),(55,54)],c["metal"],4)
    x.line([(82,98),(83,80),(76,69),(73,54)],c["metal"],4)
    x.line([(47,94),(48,80),(54,68),(57,54)],c["silver"],1)
    x.line([(81,94),(80,80),(74,68),(71,54)],c["silver"],1)
    for i in range(2+s):
        px=54+i*(20/max(1,1+s))
        x.line([(px,78),(px,59)],c["a"] if i%2==0 else c["b"],.5)
    x.ell((39,31,89,82),None,c["metal"],2)
    x.arc((37,29,91,84),202,340,c["a"],2.3); x.arc((37,29,91,84),20,158,c["b"],2.3)
    if s>=2:
        x.arc((32,25,96,89),204,327,c["silver"],1.2); x.arc((32,25,96,89),30,151,c["metal"],1.2)
    if s>=4:
        x.arc((26,21,102,93),205,278,c["trim"],.85); x.arc((26,21,102,93),15,84,c["a"],.85)
    x.ell((47,40,81,75),(17,39,62,255),c["silver"],1)
    x.ell((52,44,76,71),(48,112,152,255),c["a"],1)
    x.ell((57,49,71,66),(198,246,255,255),c["light"],.8)
    h=11+min(5,s)*1.4
    x.poly([(64,55-h),(69,53),(66,69),(64,73),(61,68),(59,53)],(150,229,255,255),c["light"],.65)
    if s>=3:
        for i in range(min(8,s+1)):
            a=2*math.pi*i/min(8,s+1); px=64+31*math.cos(a); py=56+29*math.sin(a)
            x.stud(px,py,c["trim"] if i%3==0 else c["a"],.9)
    for side in (-1,1):
        ext=min(6,s)*.75
        x.line([(64+side*7,47),(64+side*7,36-ext),(64+side*11,32-ext)],c["silver"],1.5)
        x.stud(64+side*11,32-ext,c["trim"],1)
    if s>=7:
        x.poly([(64,101),(66,104),(64,107),(62,104)],c["trim"],c["light"],.5)
    return x.im.resize((SIZE,SIZE),Image.Resampling.LANCZOS)


def draw_cinder(stage):
    x=Canvas("skin_01",stage); c=x.c; s=stage; x.pedestal("kiln")
    # Broad asymmetric basalt shoulders: a squat forge, not a circular instrument.
    x.poly([(47,94),(37,81),(27,70),(32,48),(45,58),(50,43),(64,35),(78,43),(84,58),(97,48),(102,70),(91,81),(81,94)],c["ink"],c["silver"],1.5)
    x.poly([(49,88),(42,77),(35,68),(39,55),(49,65),(54,48),(64,41),(74,48),(79,65),(89,55),(93,68),(86,77),(79,88)],c["metal"],c["b"],.9)
    # A hot furnace slit with layered magma glass.
    x.poly([(64,42),(76,56),(73,76),(64,86),(55,76),(52,56)],(48,23,29,255),c["a"],1.1)
    x.ell((55,52,73,76),(177,48,35,255),c["b"],1)
    x.ell((59,56,69,72),(255,151,61,255),c["trim"],.8)
    x.poly([(64,53),(68,64),(64,76),(60,65)],c["light"],c["trim"],.45)
    # Distinct crenellated horns evolve into a crown; glowing cracks climb the shell.
    horn=4+min(s,6)*1.5
    for side in (-1,1):
        x.poly([(64+side*19,56),(64+side*28,44-horn),(64+side*37,49),(64+side*30,67)],c["ink"],c["b"],1)
        x.line([(64+side*23,58),(64+side*29,51-horn*.45),(64+side*33,51)],c["trim"],.8)
    for i in range(2+min(s,5)):
        y=78-i*5
        x.line([(48-i*.6,y),(53,y-3),(55,y-6)],c["a"],.8)
        x.line([(80+i*.6,y),(75,y-3),(73,y-6)],c["a"],.8)
    # Ember sparks form a rising plume only on developed stages.
    for i in range(max(0,s-1)):
        xx=47+(i*13)%35; yy=36-(i*7)%18
        x.stud(xx,yy,c["trim"] if i%2 else c["a"],.75)
    if s>=6:
        x.arc((20,24,108,105),205,335,c["a"],1.6)
        x.arc((24,28,104,101),20,160,c["b"],1)
    return x.im.resize((SIZE,SIZE),Image.Resampling.LANCZOS)


def draw_verdigris(stage):
    x=Canvas("skin_02",stage); c=x.c; s=stage; x.pedestal("organic")
    # Central living stem and split bioglass seed pod.
    x.line([(64,103),(63,84),(65,68),(64,50)],c["silver"],4)
    x.line([(64,101),(64,81),(64,59)],c["a"],1.1)
    x.ell((48,40,80,75),(17,47,44,255),c["silver"],1.2)
    x.poly([(64,39),(75,51),(72,67),(64,78),(56,67),(53,51)],(28,95,78,255),c["a"],1)
    x.poly([(64,43),(70,53),(66,70),(64,75),(61,62)],(148,255,197,255),c["light"],.6)
    x.line([(64,47),(64,69)],c["light"],.65)
    # Large paired leaves create a botanical silhouette; leaves multiply by stage.
    leaves=2+min(5,s)
    for i in range(leaves):
        side=-1 if i%2==0 else 1
        row=i//2
        y=79-row*8
        startx=64+side*(2+row*.4)
        tipx=64+side*(18+min(s,5)*1.6-row*1.2)
        tipy=y-10+(row%2)*2
        midx=(startx+tipx)/2
        x.poly([(startx,y+4),(startx+side*5,y-1),(midx,tipy+1),(tipx,tipy-2),(tipx-side*2,tipy+7),(midx,y+5)],(23,88+row*5,72,245),c["silver"],.75)
        x.line([(startx,y+3),(midx,tipy+2),(tipx-1,tipy+2)],c["light"],.55)
        if s>=4:
            x.line([(midx,tipy+2),(midx+side*2,y+2)],c["b"],.5)
    # Dew-like seed lights and a delicate halo-vine on mature stages.
    for i in range(1+min(s,5)):
        x.stud(46+i*7,45+(i%2)*3,c["b"] if i%2 else c["a"],.8)
    if s>=5:
        x.arc((24,25,104,96),203,316,c["a"],1.2)
        x.arc((27,29,101,93),22,150,c["b"],.8)
    if s>=6:
        # A new jade blossom grows beneath the seed pod at mastery stage six.
        x.poly([(64,84),(70,91),(67,98),(64,94),(61,98),(58,91)],(83,196,128,245),c["light"],.7)
        x.line([(64,87),(64,94)],c["a"],.7)
    if s>=7:
        for side in (-1,1):
            x.poly([(64+side*15,49),(64+side*31,35),(64+side*26,55),(64+side*16,62)],(57,173,121,235),c["light"],.7)
    if s>=8:
        for side in (-1,1):
            x.stud(64+side*39,77,c["trim"],1.2)
        x.arc((19,20,109,103),205,261,c["light"],.7)
    return x.im.resize((SIZE,SIZE),Image.Resampling.LANCZOS)


def draw_solstice(stage):
    x=Canvas("skin_03",stage); c=x.c; s=stage; x.pedestal("solar")
    # Monumental sun-dial silhouette with eight-point rays.
    ray_count=8+min(s,8)
    for i in range(ray_count):
        a=2*math.pi*i/ray_count-math.pi/2
        inner=29 if i%2==0 else 34
        outer=48+min(s,5)*1.2 if i%2==0 else 41+min(s,5)*1.2
        p1=(64+math.cos(a)*inner,57+math.sin(a)*inner)
        p2=(64+math.cos(a+.065)*outer,57+math.sin(a+.065)*outer)
        p3=(64+math.cos(a-.065)*outer,57+math.sin(a-.065)*outer)
        x.poly([p1,p2,p3],c["trim"] if i%2==0 else c["metal"],c["light"],.45)
    x.ell((39,32,89,82),c["ink"],c["trim"],2)
    x.ell((44,37,84,77),(107,58,31,255),c["a"],1.3)
    x.ell((50,43,78,71),(255,190,72,255),c["trim"],1)
    x.ell((56,49,72,65),c["light"],(255,255,245,255),.5)
    # Fluted column ties the solar disc to a carved ceremonial base.
    x.poly([(54,80),(74,80),(78,100),(50,100)],c["ink"],c["trim"],1)
    x.poly([(58,82),(70,82),(73,98),(55,98)],c["metal"],c["light"],.7)
    for xx in (59,64,69): x.line([(xx,84),(xx,96)],c["a"] if xx==64 else c["trim"],.75)
    # Graduated crown ornaments and orbiting sunstones.
    for i in range(1+min(s,6)):
        a=-math.pi/2+(i-(min(s,6)/2))*.34
        rr=45+min(s,4)*1.1
        x.stud(64+math.cos(a)*rr,57+math.sin(a)*rr,c["light"] if i%2 else c["trim"],1)
    if s>=3:
        x.arc((31,25,97,91),204,336,c["a"],1.2)
        x.arc((27,21,101,95),20,160,c["trim"],.75)
    if s>=6:
        for xx in (39,89):
            x.line([(xx,71),(xx-3,83),(xx,88)],c["trim"],1.2)
            x.stud(xx-1,87,c["b"],1)
    return x.im.resize((SIZE,SIZE),Image.Resampling.LANCZOS)


def draw_eclipse(stage):
    x=Canvas("xp1",stage); c=x.c; s=stage; x.pedestal("relic")
    # Obsidian crescent is intentionally off-axis: no shared circular-frame silhouette.
    # Draw the crescent as a masked silhouette, leaving its inner curve open.
    # A separate layer preserves the soft aura beneath the crescent.
    cres=Image.new("RGBA",(SIZE,SIZE),(0,0,0,0)); d=ImageDraw.Draw(cres)
    d.ellipse((Q(34),Q(23),Q(91),Q(82)),fill=c["ink"],outline=c["b"],width=Q(1.2))
    # remove inner disc using a mask subtraction
    mask=Image.new("L",(SIZE,SIZE),0); md=ImageDraw.Draw(mask)
    md.ellipse((Q(34),Q(23),Q(91),Q(82)),fill=255)
    md.ellipse((Q(51),Q(18),Q(100),Q(72)),fill=0)
    cres.putalpha(mask); x.im.alpha_composite(cres); x.d=ImageDraw.Draw(x.im)
    # Violet orbit lines and a small displaced singularity core.
    x.arc((28,18,100,91),207,346,c["a"],1.25)
    x.arc((23,15,105,97),20,154,c["b"],.9)
    x.ell((54,43,77,70),(31,20,58,255),c["silver"],1)
    x.ell((59,48,73,65),(132,69,214,255),c["a"],.9)
    x.poly([(66,45),(71,55),(65,70),(60,61)],c["light"],c["b"],.45)
    # Floating black-glass shards orbit at staggered heights, increasing with mastery.
    for side in (-1,1):
        n=1+min(s,4)
        for i in range(n):
            yy=37+i*10
            xx=64+side*(31+(i%2)*5+min(s,3))
            x.poly([(xx,yy-5),(xx+side*4,yy),(xx,yy+6),(xx-side*2,yy+1)],c["metal"] if i%2 else c["ink"],c["b"],.7)
            x.line([(xx,yy-3),(xx,yy+3)],c["a"],.45)
    for i in range(max(1,s)):
        ang=2*math.pi*i/max(1,s)-math.pi/2
        x.stud(64+math.cos(ang)*38,53+math.sin(ang)*32,c["trim"] if i%3==0 else c["b"],.8)
    if s>=6:
        x.arc((18,12,110,103),202,332,c["light"],.8)
    return x.im.resize((SIZE,SIZE),Image.Resampling.LANCZOS)


def draw_borealis(stage):
    x=Canvas("xp2",stage); c=x.c; s=stage; x.pedestal("ice")
    # A towering split tuning fork of translucent ice, with unequal crystal fins.
    x.poly([(48,98),(45,78),(39,54),(42,37),(52,48),(57,65),(61,42),(64,23),(68,42),(72,64),(81,45),(91,35),(94,53),(84,78),(80,98)],c["ink"],c["silver"],1.25)
    x.poly([(53,94),(51,77),(46,55),(49,45),(56,62),(61,78),(64,35),(67,78),(76,58),(86,43),(88,54),(78,80),(75,94)],c["metal"],c["light"],.9)
    # Crystal facets catch separate teal, glacial-blue and violet lights.
    x.poly([(64,29),(68,50),(65,76),(63,82),(61,57)],(177,246,255,255),c["light"],.55)
    x.poly([(48,49),(54,66),(60,79),(52,72)],c["a"],c["light"],.45)
    x.poly([(84,47),(77,66),(69,79),(77,72)],c["b"],c["light"],.45)
    x.line([(64,37),(64,76)],c["light"],.7)
    # Floating aurora arcs and hanging tuning chimes make this a sound instrument.
    for i in range(1+min(s,5)):
        y=27+i*5
        x.arc((30-i*2,y,98+i*2,93),203+i*2,337-i*2,c["a"] if i%2==0 else c["b"],.85)
    chimes=1+min(s,5)
    for i in range(chimes):
        xx=48+i*(32/max(1,chimes-1)) if chimes>1 else 64
        top=72+(i%2)*6
        x.line([(xx,top),(xx,top+10)],c["silver"],.65)
        x.poly([(xx,top+9),(xx+2.6,top+12),(xx,top+19),(xx-2.6,top+12)],c["a"] if i%2==0 else c["b"],c["light"],.45)
        x.line([(xx-1,top+12),(xx,top+17)],c["light"],.4)
    # Small star-frost nodes unfold across the silhouette in later stages.
    for i in range(min(s+1,7)):
        xx=36+(i*13)%56; yy=34+(i*17)%43
        x.stud(xx,yy,c["light"] if i%2 else c["b"],.75)
    if s>=6:
        for side in (-1,1):
            x.poly([(64+side*21,48),(64+side*39,29),(64+side*32,57),(64+side*21,68)],(50,154,190,230),c["light"],.8)
        x.arc((23,16,105,98),205,337,c["b"],.9)
    if s>=7:
        x.poly([(64,18),(67,28),(64,34),(61,28)],c["a"],c["light"],.6)
    if s>=8:
        x.stud(31,49,c["b"],1.15)
        x.stud(97,49,c["a"],1.15)
        x.arc((18,12,110,104),22,158,c["light"],.7)
    return x.im.resize((SIZE,SIZE),Image.Resampling.LANCZOS)

DRAWERS={"default":draw_default,"skin_01":draw_cinder,"skin_02":draw_verdigris,"skin_03":draw_solstice,"xp1":draw_eclipse,"xp2":draw_borealis}


def make_portrait(stage_image):
    size=512
    bg=Image.new("RGBA",(size,size),(5,10,22,255)); px=bg.load()
    for y in range(size):
        for xx in range(size):
            d=math.sqrt(((xx-size/2)/(size*.73))**2+((y-size*.43)/(size*.75))**2)
            bloom=max(0,1-d); px[xx,y]=(int(5+10*bloom),int(10+25*bloom),int(23+50*bloom),255)
    d=ImageDraw.Draw(bg); rng=random.Random(1908)
    for _ in range(88):
        xx,yy=rng.randrange(18,size-18),rng.randrange(18,size-18); r=rng.choice([1,1,2])
        d.ellipse((xx-r,yy-r,xx+r,yy+r),fill=(119,206,240,rng.randrange(45,145)))
    d.rounded_rectangle((12,12,size-12,size-12),radius=42,outline=(91,143,181,210),width=3)
    d.rounded_rectangle((21,21,size-21,size-21),radius=36,outline=(180,115,255,140),width=1)
    art=stage_image.resize((458,458),Image.Resampling.LANCZOS); bg.alpha_composite(art,(27,24))
    return bg

if __name__=="__main__":
    ROOT.mkdir(parents=True,exist_ok=True)
    for sid,drawer in DRAWERS.items():
        folder=ROOT/sid; folder.mkdir(parents=True,exist_ok=True)
        for stage in range(1,9):
            drawer(stage).save(folder/f"stage_{stage:02d}.png",optimize=True)
    make_portrait(draw_default(8)).save(ROOT/"portrait.png",optimize=True)
    print("Drawn 6 distinct Resonator art families × 8 stages = 48 sprites, plus portrait.")
