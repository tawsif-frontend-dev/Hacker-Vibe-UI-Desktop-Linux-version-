; =====================================================================
;  HACKER SUITE - SETTINGS (the only file you ever need to edit)
;  Right-click any widget > "Edit settings" opens this file.
;  Save, then right-click > "Refresh all" to apply.
;  Theme switching never overwrites this file.
;  (install.ps1 fills the first block in for you.)
; =====================================================================
[Variables]

; ---- Who are you? ---------------------------------------------------
; Shown in the Terminal widget and as the author of your own quotes.
; For the wallpaper text run install.ps1 again (or tools/make_wallpapers.py).
UserName=Hacker

; ---- Theme ----------------------------------------------------------
; Minutes between automatic theme changes (ThemeCycler widget)
ThemeCycleMinutes=30
; 1 = also change the desktop wallpaper when the theme changes
ThemeWallpaper=1

; ---- Clock ----------------------------------------------------------
; 0 = 12-hour, 1 = 24-hour (or just click the clock)
Clock24=0
Motto=FOCUS / PLAN / EXECUTE / SUCCEED

; ---- Calendar event countdown (rolls over to next year by itself) ---
EventName=New Year
EventDay=1
EventMonth=1

; ---- Quote ----------------------------------------------------------
; Minutes between random quotes (click the quote for a new one)
; Add your own quotes in @Resources\Quotes.txt   (use {USER} for your name)
QuoteMinutes=60

; ---- Weather --------------------------------------------------------
; 1 = detect city automatically from your internet connection
;     (sends a request to ip-api.com - set to 0 if you prefer not to)
; 0 = always use the Lat / Lon / LocationName below
WeatherAuto=1
Lat=51.5074
Lon=-0.1278
LocationName=London, UK

; ---- System Status alerts (percent) ---------------------------------
WarnAt=60
CritAt=85

; ---- Network --------------------------------------------------------
PingHost=1.1.1.1

; ---- Shortcuts ------------------------------------------------------
; install.ps1 detects these automatically. Use full paths, no % variables.
VSCodePath=C:\Program Files\Microsoft VS Code\Code.exe
DownloadsPath=C:\Users\Public\Downloads
PortfolioLabel=My Website
PortfolioURL=https://github.com
