# HackerVibe for Linux

An independent Linux desktop-widget suite using **Conky + Lua + Cairo**. It is not compatible with Rainmeter skins. It includes four themes (Green / Blue / Red / Purple) and the widgets below.

| Widget      | What it shows |
|-------------|---------------|
| Clock       | big time (12h/24h), date, rotating motto / greeting / year progress |
| Calendar    | month grid, today highlighted, countdown to your yearly event |
| Weather     | live weather from Open-Meteo (free, no API key); manual location by default |
| System      | CPU / RAM / swap / up to 3 disks with warn/crit colours + live net graph |
| Network     | interface, IP, ping, download / upload speed with graph |
| Terminal    | neofetch-style readout of your machine |
| Quote       | rotating programmer quotes (edit `quotes.txt` to add yours) |
| Shortcuts   | circular launcher panel |
| ThemeCycler | "THEME: Green // NEXT IN 12 MIN" status line |

## Install

```bash
cd linux
bash install.sh
```

The installer asks your name, website link and a countdown event. It offers package installation through apt, dnf, pacman, or zypper only after confirmation. It installs fonts for your user, renders personalized wallpapers into its data directory, sets up autostart, and starts widgets when a supported graphical session is available. Re-running updates program files while retaining the settings file and quotes.
Non-interactive: `bash install.sh --yes --name Hacker`. Remove with `bash uninstall.sh`.

**Requirements:** Conky with Lua and Cairo support (Debian/Ubuntu package: `conky-all`), Python 3, and a graphical session. Pillow is optional and is needed to render personalized wallpapers. The installer cannot add support for unavailable desktop services or Conky features.

### Update, recovery, and removal

To update, obtain the new project files and run `bash install.sh` again from `linux/`; the user's settings and quotes remain under `~/.config/hackervibe/`. If installation is interrupted, rerun the installer. To remove program files while keeping settings, run `bash uninstall.sh`; `bash uninstall.sh --purge` also removes settings, quotes, and HackerVibe's named font files without prompting. Personalized wallpapers and unrelated font-directory files are preserved. The uninstaller leaves the current desktop wallpaper unchanged.

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

Wallpaper switching has desktop-specific paths for GNOME-family desktops, KDE Plasma, XFCE, Cinnamon, MATE, LXQt/LXDE, sway, plus `feh`/`nitrogen` on bare window managers.
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

## Privacy and network access

Weather forecasts are requested from `api.open-meteo.com` with the configured coordinates. IP-based city detection contacts `ip-api.com` over HTTP and can reveal the public IP address to that service; it is disabled by default. Enable it only by setting `WEATHER_AUTO="1"` in `~/.config/hackervibe/settings.conf`. Weather requests have timeouts and retain the last cached result when a request fails. Network widgets also ping the configured `PING_HOST`.

## Known limits

* Widgets are not clickable; use `hackervibe open` or `hackervibe launcher`.
* Conky window placement, transparency, and desktop wallpaper integration vary by desktop environment and session. A Conky build with both Lua and Cairo support is required.
* Wayland runs Conky through XWayland where available; behavior is not verified on all compositors.
* The installer package names and desktop integrations have not been verified across all listed distributions and desktop environments.
* This source tree was inspected in a Windows environment; actual Linux desktop rendering and lifecycle behavior remain unverified here.

The Linux runtime uses Orbitron and JetBrains Mono under the SIL Open Font License. Legacy Open Sans/Roboto files are not installed by Linux; their Apache-2.0 license and historical version notes are in `Skins/HackerSuite/@Resources/Fonts/`. Project code is MIT-licensed; see the repository `LICENSE`.
