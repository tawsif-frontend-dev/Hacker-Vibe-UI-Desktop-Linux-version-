========================================
 HACKER DESKTOP SUITE - v3
========================================

Prefer the easy way? Run install.bat from the repo root instead — it
does everything below automatically and asks you a couple of quick
questions. This file is for people who want to do it by hand.


CONTENTS
--------
@Resources/
    Settings.inc        <- the only file you ever need to edit
                            (your name, links, weather location, etc.)
    Wallpaper/Base/      <- nameless wallpaper art (4 colors)
    Wallpaper/           <- generated wallpapers with your name
                            (run: python tools/make_wallpapers.py "NAME")
    Themes/Theme.inc     <- the ACTIVE theme (all widgets read this)
    Variables.inc        <- ACTIVE calendar colors
    Fonts/                <- bundled fonts, open-licensed (see OFL-*.txt)

Clock/, Calendar/, Weather/, SystemStatus/, Network/, Terminal/,
Quote/, Shortcuts/, ThemeCycler/   <- one .ini per widget


FIRST-TIME MANUAL INSTALL
--------------------------
1. Install the fonts in @Resources/Fonts/ (right-click each -> Install).
2. Generate your wallpaper: `python tools/make_wallpapers.py "YOUR NAME"`
   (needs `pip install pillow`), or use the plain Base/ art as-is.
3. Set one of @Resources/Wallpaper/*.png as your desktop background.
4. Copy this whole "HackerSuite" folder into Documents\Rainmeter\Skins\
5. Open @Resources/Settings.inc in Notepad and fill in your name, links,
   VS Code path, downloads folder, and weather location.
6. Rainmeter -> Manage -> find "HackerSuite" -> select all the .ini
   files (Ctrl+click) -> Load.
7. Drag each widget into place, then Layouts tab -> Save layout.


HOW TO SWITCH THEMES BY HAND
------------------------------
1. Set the wallpaper: pick the matching PNG from @Resources/Wallpaper/
   and right-click -> "Set as desktop background".
2. In @Resources/Themes/, copy the theme you want (e.g. Theme-Blue.inc),
   rename the copy to "Theme.inc", overwrite the existing one.
3. In @Resources/, do the same with Variables-X.inc -> Variables.inc
   (this one only affects the Calendar widget's colors).
4. Rainmeter -> Manage -> "Refresh all".

Easier: just right-click any widget -> Theme > (color). It does all of
the above for you instantly, including the wallpaper.


AUTO-CYCLE THEMES
------------------
Load "ThemeCycler.ini" (Rainmeter -> Manage -> HackerSuite) and it will
rotate Green -> Blue -> Red -> Purple -> Green... on a timer, changing
the wallpaper AND every widget's colors at the same moment. Interval is
ThemeCycleMinutes in Settings.inc. Turn off Windows' own wallpaper
slideshow first (Settings -> Personalization -> Background -> "Picture"),
or the two will fight each other. Don't run manual switching and the
cycler at the same time - the cycler will overwrite manual choices on
its next tick.


NOTES
-----
- Weather.ini needs internet to update (Open-Meteo, free, no API key).
  Set WeatherAuto=0 and fill in Lat/Lon/LocationName in Settings.inc for
  a fixed city, or leave WeatherAuto=1 to auto-detect from your IP.
- Shortcuts.ini: edit VSCodePath, DownloadsPath, PortfolioLabel and
  PortfolioURL in Settings.inc for your own machine and links.
- Add your own quotes to @Resources/Quotes.txt, one per line as
  `text|author`. Use `{USER}` as the author to credit yourself.
