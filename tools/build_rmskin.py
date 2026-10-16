#!/usr/bin/env python3
"""Build a double-click-installable HackerSuite.rmskin (default settings, no name prompts)."""
import os, zipfile
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = os.path.join(ROOT, "HackerSuite.rmskin")
ini = """[rmskin]
Name=Hacker Desktop Suite
Author=Tawsif
Version=3.0.0
LoadType=Skin
Load=HackerSuite\\Clock\\Clock.ini
MinimumRainmeter=4.4.0
MinimumWindows=10.0
"""
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("RMSKIN.ini", ini)
    base = os.path.join(ROOT, "Skins")
    for d, _, files in os.walk(base):
        for f in files:
            p = os.path.join(d, f)
            z.write(p, os.path.relpath(p, ROOT).replace(os.sep, "/"))
print("built", out, os.path.getsize(out) // 1024, "KB")
