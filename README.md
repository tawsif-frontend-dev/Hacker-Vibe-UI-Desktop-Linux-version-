# HackerVibe Desktop UI for Linux

HackerVibe for Linux is a separate desktop-widget product built with Conky, Lua, and Cairo. It is not a Rainmeter port. The top-level Windows installers and Rainmeter `.ini` skins are legacy assets in this extracted tree; they are not used or supported by the Linux installer. See [the Linux guide](linux/README.md) for requirements, installation, configuration, privacy, troubleshooting, and removal.

## Quick install

From the extracted repository root, run:

```bash
cd linux
bash install.sh
```

The installer can offer to install dependencies through a supported system package manager after asking first. For a non-interactive install with defaults, use `bash install.sh --yes`; use `bash install.sh --help` to see options.

## Features

The Linux edition includes clock, calendar, weather, system and network status, terminal information, quotes, shortcuts, four themes, and optional theme-driven wallpaper changes. Desktop integration depends on the installed Conky build and desktop environment; see the [known limitations](linux/README.md#known-limits).

## Privacy

Weather forecasts use Open-Meteo. IP-based location lookup through ip-api.com is optional and disabled by default; set `WEATHER_AUTO="1"` in `~/.config/hackervibe/settings.conf` to enable it. This sends the public IP address to that service over HTTP. Forecast requests send the configured coordinates to Open-Meteo. The network widget also pings `PING_HOST` (default `1.1.1.1`).

## License

Project code is licensed under [MIT](LICENSE). The Linux installer installs JetBrains Mono and Orbitron, with their OFL license texts in `Skins/HackerSuite/@Resources/Fonts/`. Other legacy font files in the extracted tree are not used by the Linux runtime.
