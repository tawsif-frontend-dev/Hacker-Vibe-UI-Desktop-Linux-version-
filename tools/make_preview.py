#!/usr/bin/env python3
"""Render an accurate full-desktop mockup preview per theme, from Theme-*.inc colors."""
import os, random, textwrap
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES  = os.path.join(ROOT, "Skins", "HackerSuite", "@Resources")
FONTS = os.path.join(RES, "Fonts")
mono   = lambda s: ImageFont.truetype(f"{FONTS}/JetBrainsMono-Regular.ttf", s)
mono_b = lambda s: ImageFont.truetype(f"{FONTS}/JetBrainsMono-Bold.ttf", s)
orb    = lambda s: ImageFont.truetype(f"{FONTS}/Orbitron.ttf", s)

W, H = 1366, 768

def read_theme(name):
    p = os.path.join(RES, "Themes", f"Theme-{name}.inc")
    out = {}
    for line in open(p, encoding="utf-8"):
        line = line.strip()
        if "=" in line and not line.startswith("["):
            k, v = line.split("=", 1)
            if "," in v:
                out[k] = tuple(int(x) for x in v.split(",")[:3])
    return out

def render(theme_name, outfile):
    T = read_theme(theme_name)
    ACCENT, HOVER, DIM = T["Accent"], T["Hover"], T["Dim"]
    BARBG, WARN = T["BarBG"], T["Warn"]

    import numpy as np
    t = np.linspace(0, 1, H).reshape(H, 1)
    base = np.array(ACCENT)
    r = (3 + base[0]*0.05*t); g = (5 + base[1]*0.05*t); b = (8 + base[2]*0.07*t)
    grad = np.zeros((H, W, 3), dtype=np.uint8)
    grad[..., 0] = r; grad[..., 1] = g; grad[..., 2] = b
    canvas = Image.fromarray(grad, "RGB")
    d = ImageDraw.Draw(canvas, "RGBA")

    random.seed(hash(theme_name) % 1000)
    for i in range(26):
        bw = random.randint(30, 70); bh = random.randint(60, 260)
        bx = random.randint(0, W-bw); by = H-bh-40
        shade = random.randint(10, 22)
        d.rectangle((bx, by, bx+bw, by+bh), fill=(shade, shade+4, shade+8, 255))
        for wy in range(by+8, H-40, 14):
            for wx in range(bx+6, bx+bw-6, 12):
                if random.random() < 0.35:
                    d.rectangle((wx, wy, wx+4, wy+7), fill=ACCENT+(140,))
    horizon = H-40
    d.line((0, horizon, W, horizon), fill=ACCENT+(60,))
    for i in range(-10, 11):
        d.line((W/2, horizon-2, W/2+i*140, H), fill=ACCENT+(35,))
    for k in range(1, 6):
        yy = horizon + (H-horizon)*k/6
        d.line((0, yy, W, yy), fill=ACCENT+(22,))
    glyphs = "01{}[]<>#$%&/\\"
    f_small = mono(11)
    for i in range(130):
        gx, gy = random.randint(0, W), random.randint(0, int(H*0.6))
        d.text((gx, gy), random.choice(glyphs), font=f_small, fill=ACCENT+(random.randint(20, 85),))

    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    def panel(xy, radius=8, fill=(0, 0, 0, 150)):
        d.rounded_rectangle(xy, radius=radius, fill=fill, outline=ACCENT+(255,), width=1)
    def text(pos, s, font, fill=ACCENT, anchor="la"):
        fc = fill+(255,) if len(fill) == 3 else fill
        d.text(pos, s, font=font, fill=fc, anchor=anchor)

    # Terminal
    tx, ty, tw, th = 14, 14, 384, 300
    panel((tx, ty, tx+tw, ty+th))
    d.line([(tx, ty+34), (tx+tw, ty+34)], fill=ACCENT+(120,))
    text((tx+14, ty+9), "TERMINAL", mono_b(13), DIM)
    for i, c in enumerate((ACCENT, (255, 120, 120), (255, 200, 80))):
        d.ellipse((tx+tw-70+i*22, ty+9, tx+tw-70+i*22+12, ty+21), fill=c+(255,))
    rows = [("user@desktop:~$ neofetch", DIM, mono(13)),
            ("OS      Windows 10/11", ACCENT, mono(12)),
            ("CPU     Your CPU model", ACCENT, mono(12)),
            ("GPU     Your GPU model", ACCENT, mono(12)),
            ("MEMORY  2.7 GB / 4.0 GB", ACCENT, mono(12)),
            ("UPTIME  0d 9h 12m", ACCENT, mono(12)),
            ("SCREEN  1366x768", ACCENT, mono(12)),
            (f"THEME   {theme_name}", ACCENT, mono(12))]
    yy = ty+46
    for s, c, f in rows:
        text((tx+14, yy), s, f, c); yy += 21
    sw = [ACCENT, (80, 80, 80), (80, 120, 160), (120, 80, 160), (255, 190, 60), (255, 70, 70), (220, 220, 220)]
    xx = tx+14
    for c in sw:
        d.rectangle((xx, yy+6, xx+34, yy+18), fill=c+(255,)); xx += 40
    yy += 34
    text((tx+14, yy), "user@desktop:~$", mono(13), DIM)

    # System status
    sx, sy, sw2, sh = 14, 332, 384, 360
    panel((sx, sy, sx+sw2, sy+sh))
    text((sx+14, sy+10), "user@desktop  07:42:41", mono(13), DIM)
    text((sx+sw2-14, sy+10), "UP 0d 9h 12m", mono(11), DIM, anchor="ra")
    def stat(y, label, pct, val, color=ACCENT, barcolor=None):
        text((sx+14, y), label, mono(13), color)
        if pct is not None:
            bx0, bx1 = sx+14, sx+sw2-14
            d.rounded_rectangle((bx0, y+22, bx1, y+28), radius=3, fill=BARBG+(220,))
            bw_ = int((bx1-bx0)*pct/100)
            d.rounded_rectangle((bx0, y+22, bx0+max(bw_, 6), y+28), radius=3, fill=(barcolor or ACCENT)+(255,))
        if val: text((sx+sw2-14, y), val, mono(12), color, anchor="ra")
    stat(sy+40, "CPU  32%", 32, None, ACCENT)
    stat(sy+70, "RAM  69%", 69, "2.7 GB / 4.0 GB", WARN, WARN)
    stat(sy+108, "SWAP 56%", 56, "3.8 GB / 6.8 GB", ACCENT)
    stat(sy+150, "DISK C: 71%", 71, "50.7 GB / 71.0 GB", ACCENT)
    stat(sy+188, "DISK D: 12%", 12, "4.5 GB / 38.2 GB", ACCENT)
    stat(sy+226, "DISK E: 52%", 52, "5.2 GB / 10.0 GB", ACCENT)
    text((sx+14, sy+264), "NET   DN 54.0 B/s   UP 55.0 B/s", mono(12), ACCENT)
    random.seed(3)
    pts = [(sx+14+i*4, sy+310-random.randint(0, 26)) for i in range(90)]
    d.line(pts, fill=ACCENT+(200,), width=1)
    text((sx+14, sy+sh-26), "your-portfolio.example", mono(12), DIM)

    # Quote
    qx, qy, qw, qh = W-380, 14, 366, 140
    panel((qx, qy, qx+qw, qy+qh))
    text((qx+16, qy+6), "\u201c", orb(28), DIM)
    qtext = "There are only two hard things in Computer Science: cache invalidation and naming things."
    for i, line in enumerate(textwrap.wrap(qtext, 34)):
        text((qx+24, qy+42+i*20), line, mono(13), HOVER)
    text((qx+qw-24, qy+qh-26), "- Phil Karlton", mono(12), ACCENT, anchor="ra")

    mx, my = W-150, 180
    for i, w in enumerate(["WORK", "HARD", "IN", "SILENCE"]):
        text((mx, my+i*30), w, mono_b(19), HOVER)

    cx = W//2
    text((cx, 22), "07:42", orb(56), ACCENT, anchor="ma")
    text((cx, 84), "Tuesday, 29 September 2026", mono(15), HOVER, anchor="ma")
    text((cx, 108), "GOOD MORNING", mono(12), DIM, anchor="ma")

    scx0, scy0, scx1, scy1 = cx-172, 148, cx+172, 478
    d.ellipse((scx0, scy0, scx1, scy1), outline=ACCENT+(255,), width=2)
    text((cx, 164), "SHORTCUTS", mono_b(14), HOVER, anchor="ma")
    items = ["> Code Editor", "> Terminal", "> Website", "> Chat App", "> Video", "> Mail"]
    yy = 208
    for it in items:
        text((cx-115, yy), it, mono(17), ACCENT); yy += 35

    name_text = "YOUR NAME"
    f = orb(56)
    l, t2, r, b = f.getbbox(name_text)
    tw_ = r-l
    tx0 = cx - tw_//2
    ty0 = 520
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.text((tx0, ty0), name_text, font=f, fill=ACCENT+(255,))
    glow = glow.filter(ImageFilter.GaussianBlur(7))
    overlay.alpha_composite(Image.eval(glow, lambda v: int(v*0.8)))
    d = ImageDraw.Draw(overlay)
    text((tx0, ty0), name_text, f, ACCENT)
    text((cx, ty0+68), "THINK   |   CODE   |   EXECUTE", mono(17), ACCENT, anchor="ma")
    text((cx, ty0+96), "</>", mono(15), DIM, anchor="ma")
    text((cx, ty0+150), "Downloads Folder", mono(14), ACCENT, anchor="ma")

    text((W-300, 500), f"THEME: {theme_name}  //  NEXT IN 16 MIN", mono(11), DIM)

    kx, ky, kw, kh = W-300, 520, 286, 235
    panel((kx, ky, kx+kw, ky+kh), radius=10)
    text((kx+16, ky+12), "SEPTEMBER 2026", mono_b(15), HOVER)
    text((kx+16, ky+34), "TUESDAY 29", mono(11), DIM)
    days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    for i, dn in enumerate(days):
        text((kx+16+i*36, ky+58), dn, mono(10), DIM)
    weeks = [["30", "31", "1", "2", "3", "4", "5"],
             ["6", "7", "8", "9", "10", "11", "12"],
             ["13", "14", "15", "16", "17", "18", "19"],
             ["20", "21", "22", "23", "24", "25", "26"]]
    for wi, week in enumerate(weeks):
        for di, dnum in enumerate(week):
            px_, pyy = kx+16+di*36, ky+80+wi*30
            col = ACCENT
            if dnum == "29" and wi == 2:
                d.ellipse((px_-4, pyy-4, px_+22, pyy+22), fill=ACCENT+(255,)); col = (0, 0, 0)
            text((px_+9, pyy+9), dnum, mono(12), col, anchor="mm")
    text((kx+16, ky+kh-40), "165 Days until", mono(12), ACCENT)
    text((kx+16, ky+kh-22), "> Your Event", mono(11), DIM)

    canvas = canvas.convert("RGBA")
    canvas.alpha_composite(overlay)
    canvas.convert("RGB").save(outfile, optimize=True)

if __name__ == "__main__":
    out_dir = os.path.join(ROOT, "docs", "themes")
    os.makedirs(out_dir, exist_ok=True)
    for th in ["Green", "Blue", "Red", "Purple"]:
        path = os.path.join(out_dir, f"preview-{th.lower()}.png")
        render(th, path)
        print("wrote", path)
    # main README image = Blue
    render("Blue", os.path.join(ROOT, "docs", "preview.png"))
    print("wrote docs/preview.png (Blue, default)")
