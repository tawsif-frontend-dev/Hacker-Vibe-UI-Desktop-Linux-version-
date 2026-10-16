#!/usr/bin/env python3
"""Render a name onto the 4 HackerVibe wallpapers (Linux edition of tools/make_wallpapers.py).

Usage:  render_wallpapers.py --name "YOUR NAME" --base DIR_WITH_BASE_PNGS --out OUTPUT_DIR
Needs:  Pillow (python3-pil / python3-pillow / pip install pillow)
"""
import argparse
import glob
import os
import sys

try:
    from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont
except ImportError:
    sys.exit("Pillow is not installed (apt: python3-pil, dnf: python3-pillow, pacman: python-pillow)")

ACCENT = {"Blue": (153, 213, 255), "Green": (168, 255, 206), "Red": (255, 146, 146), "Purple": (206, 168, 255)}
CENTER_X, CENTER_Y = 958, 742   # middle of the name area on the 1920x1080 art
MAX_W, BASE_SIZE = 440, 110     # the name must fit inside the dark cloak


def font_candidates():
    here = os.path.dirname(os.path.abspath(__file__))
    bundled = os.path.join(os.path.dirname(os.path.dirname(here)), "Skins", "HackerSuite", "@Resources", "Fonts", "JetBrainsMono-Bold.ttf")
    found = glob.glob("/usr/share/fonts/**/DejaVuSansMono-Bold.ttf", recursive=True)
    return [bundled, os.path.expanduser("~/.local/share/fonts/hackervibe/JetBrainsMono-Bold.ttf"),
            "DejaVuSansMono-Bold.ttf", *found, "LiberationMono-Bold.ttf"]


def load_font(size):
    for f in font_candidates():
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            continue
    return ImageFont.load_default()


def render(name, theme, base_dir, out_dir):
    src = os.path.join(base_dir, f"Hacker_Wallpaper_{theme}_1920x1080.png")
    base = Image.open(src).convert("RGB")
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
    out.save(os.path.join(out_dir, f"Hacker_Wallpaper_{theme}_1920x1080.png"), optimize=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--name", default="YOUR NAME")
    ap.add_argument("--base", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    for theme in ACCENT:
        render(a.name, theme, a.base, a.out)
        print("wrote", theme)


if __name__ == "__main__":
    main()
