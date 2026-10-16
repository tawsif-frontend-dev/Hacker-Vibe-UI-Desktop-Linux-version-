# HackerVibe Desktop UI: Linux edition

The same hacker desktop as the Windows/Rainmeter version, rebuilt for Linux with
**Conky + Cairo**. Same 4 themes (Green / Blue / Red / Purple), same 9 widgets, same wallpapers
and fonts. Everything is drawn with Cairo, so it looks like the Windows screenshots.

| Widget      | What it shows |
|-------------|---------------|
| Clock       | big time (12h/24h), date, rotating motto / greeting / year progress |
| Calendar    | month grid, today highlighted, countdown to your yearly event |
| Weather     | live weather from Open-Meteo (free, no API key), auto city detection |
| System      | CPU / RAM / swap / up to 3 disks with warn/crit colours + live net graph |
| Network     | interface, IP, ping, download / upload speed with graph |
| Terminal    | neofetch-style readout of your machine |
| Quote       | rotating programmer quotes (edit `quotes.txt` to add yours) |
| Shortcuts   | circular launcher panel |
| ThemeCycler | "THEME: Green // NEXT IN 12 MIN" status line |

## Install

```bash
git clone https://github.com/tawsif-frontend-dev/HackerVibe-DesktopUI.git
cd HackerVibe-DesktopUI/linux
./install.sh
```

The installer asks your name, website link and a countdown event, installs missing packages
(apt / dnf / pacman / zypper, with your confirmation), installs the fonts for your user,
renders your name onto the 4 wallpapers, sets up autostart and starts everything.
Run it again any time to change your answers; your other settings are kept.
Non-interactive: `./install.sh --yes --name Tawsif`. Remove with `./uninstall.sh`.

**Needs:** a conky build with **Lua + Cairo** (Debian/Ubuntu: `conky-all`), Python 3, Pillow
(optional, for the name on the wallpaper), and an X11 session or Wayland with XWayland.

## Everyday use

```bash
hackervibe theme next        # Green -> Blue -> Red -> Purple (wallpaper changes too)
hackervibe theme purple      # pick one
hackervibe settings          # edit ~/.config/hackervibe/settings.conf, then: hackervibe restart
hackervibe quote             # jump to the next quote
hackervibe clock24           # toggle 12h / 24h
hackervibe weather           # refresh weather now
hackervibe open 1            # run shortcut 1 (or: hackervibe open code)
hackervibe launcher          # pop-up menu of your shortcuts (rofi/wofi/fuzzel/dmenu/zenity)
hackervibe status | stop | start | restart
hackervibe doctor            # checks dependencies and shows recent errors
```

Wallpaper switching works on GNOME-family desktops (GNOME, Ubuntu, Pop!_OS, Budgie, Zorin),
KDE Plasma, XFCE, Cinnamon, MATE, LXQt/LXDE, sway, plus `feh`/`nitrogen` on bare window managers.
Set `THEME_WALLPAPER="0"` in settings to keep your own wallpaper and only change widget colours.

## Customising

Everything lives in one file, `~/.config/hackervibe/settings.conf`, with comments for each option:
name, theme cycle time, weather city or auto-detect, units, disks, ping host, alert thresholds,
shortcuts (up to 8), which widgets to start, widget size (`UI_SCALE`) and positions (`POS_<NAME>`).
Colours and the 12h/24h clock apply within seconds; run `hackervibe restart` for the rest.

Widget size defaults to `screen height / 768`, so it fits 1080p, 1440p and 4K screens.

## How it works

One conky process per widget (`HV_WIDGET=clock conky -c conky/hackervibe.conf`), each drawing its card
with Cairo from `lib/widgets/<name>.lua`. `bin/hackervibe` starts/stops them, rotates themes with a small
background timer, and talks to your desktop to swap the wallpaper. Weather is fetched by
`libexec/weather.py` (Python standard library only) every 30 minutes into a small cache file.

```
linux/
  install.sh  uninstall.sh
  bin/hackervibe            control command
  conky/hackervibe.conf     shared conky config
  lib/hv.lua                themes, settings, Cairo helpers
  lib/widgets/*.lua         the 9 widgets
  libexec/weather.py        weather fetcher
  tools/render_wallpapers.py  puts your name on the wallpapers
  config/settings.conf      default settings template
```

## Known limits

* **Widgets aren't clickable.** Conky windows can't receive mouse clicks, so the Windows version's
  click-to-launch and right-click menus don't exist. Use `hackervibe open` / `hackervibe launcher`
  and bind them to a keyboard shortcut in your desktop settings instead.
* **Transparency needs a compositor** (every mainstream desktop has one). On a bare window manager set
  `COMPOSITOR="off"` for pseudo-transparency.
* **Wayland:** widgets run through XWayland. If they don't appear on a Wayland session, try
  `WINDOW_TYPE="normal"` in settings, or log in with the Xorg session.
* If the weather shows `fetching…`, check your internet connection; `hackervibe doctor` shows the log.

## Testing status

Developed and tested on Ubuntu 24.04 with conky 1.19.6 in a headless X server: all 9 widgets render,
live theme switching, installer / re-run / uninstall, CLI commands and `doctor` pass.
Not yet verified on real desktops: real compositor transparency, GNOME/KDE wallpaper switching, Wayland,
and the Fedora / Arch / openSUSE package names (the installer prints what it runs, and `hackervibe doctor`
tells you what's missing). If something misbehaves, send me the output of `hackervibe doctor`.

Fonts: Orbitron and JetBrains Mono (SIL Open Font License).
