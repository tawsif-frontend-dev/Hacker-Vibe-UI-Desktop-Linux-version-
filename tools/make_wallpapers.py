#!/usr/bin/env python3
"""Render your own name onto the Hacker Suite wallpapers.

Usage:   python tools/make_wallpapers.py "YOUR NAME"
Needs:   pip install pillow
Reads:   Skins/HackerSuite/@Resources/Wallpaper/Base/*.png   (no name on them)
Writes:  Skins/HackerSuite/@Resources/Wallpaper/*.png        (with your name)
"""
import sys, os, glob
from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WP = os.path.join(ROOT, "Skins", "HackerSuite", "@Resources", "Wallpaper")
ACCENT = {"Blue": (153, 213, 255), "Green": (168, 255, 206),
          "Red": (255, 146, 146), "Purple": (206, 168, 255)}
CENTER_X, CENTER_Y = 958, 742          # middle of the name area on the 1920x1080 art
MAX_W, BASE_SIZE = 440, 110            # the name must fit inside the dark cloak

FONTS = ["DejaVuSansMono-Bold.ttf", "consolab.ttf", "Menlo-Bold.ttf",
         "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
         "C:/Windows/Fonts/consolab.ttf", "/System/Library/Fonts/Menlo.ttc"]

def load_font(size):
    for f in FONTS:
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            pass
    return ImageFont.load_default()

def render(name, theme):
    base = Image.open(os.path.join(WP, "Base", f"Hacker_Wallpaper_{theme}_1920x1080.png")).convert("RGB")
    name = name.strip().upper()[:14] or "YOUR NAME"
    size = BASE_SIZE
    font = load_font(size)
    while size > 30 and font.getbbox(name)[2] - font.getbbox(name)[0] > MAX_W:
        size -= 4
        font = load_font(size)
    l, t, r, b = font.getbbox(name)
    pos = (CENTER_X - (l + r) // 2, CENTER_Y - (t + b) // 2)
    col = ACCENT[theme]
    glow = Image.new("RGB", base.size, (0, 0, 0))
    ImageDraw.Draw(glow).text(pos, name, font=font, fill=col)
    glow = glow.filter(ImageFilter.GaussianBlur(9))
    out = ImageChops.add(base, Image.eval(glow, lambda v: int(v * 0.7)))
    ImageDraw.Draw(out).text(pos, name, font=font, fill=col)
    out.save(os.path.join(WP, f"Hacker_Wallpaper_{theme}_1920x1080.png"), optimize=True)

if __name__ == "__main__":
    who = sys.argv[1] if len(sys.argv) > 1 else "YOUR NAME"
    for th in ACCENT:
        render(who, th)
        print("wrote", th)
