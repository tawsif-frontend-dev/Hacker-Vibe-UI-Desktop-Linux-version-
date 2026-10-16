#!/usr/bin/env python3
"""HackerVibe weather fetcher (Open-Meteo, free, no API key; stdlib only).

Writes  $HV_CACHE/weather.kv  (key=value lines) for the weather widget.

  weather.py --once      fetch one time and exit
  weather.py --daemon    fetch every 30 min (retry after 2 min on failure)
"""
import json
import os
import sys
import time
import urllib.parse
import urllib.request

HOME = os.path.expanduser("~")
CONFIG = os.environ.get("HV_CONFIG") or os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.join(HOME, ".config")), "hackervibe")
CACHE = os.environ.get("HV_CACHE") or os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.join(HOME, ".cache")), "hackervibe")

WMO = {
    0: "Clear sky", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
    45: "Fog", 48: "Rime fog",
    51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle", 56: "Freezing drizzle", 57: "Freezing drizzle",
    61: "Light rain", 63: "Rain", 65: "Heavy rain", 66: "Freezing rain", 67: "Freezing rain",
    71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains",
    80: "Rain showers", 81: "Rain showers", 82: "Violent showers",
    85: "Snow showers", 86: "Snow showers",
    95: "Thunderstorm", 96: "Thunderstorm, hail", 99: "Thunderstorm, hail",
}


def read_settings():
    cfg = {}
    try:
        with open(os.path.join(CONFIG, "settings.conf"), encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line[0] in "#;" or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                v = v.strip()
                if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
                    v = v[1:-1]
                cfg[k.strip()] = v
    except OSError:
        pass
    return cfg


def get_json(url, timeout=15):
    req = urllib.request.Request(url, headers={"User-Agent": "HackerVibe-Linux/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))


def write_kv(data):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, "weather.kv")
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        for k, v in data.items():
            f.write(f"{k}={str(v).replace(chr(10), ' ')}\n")
    os.replace(tmp, path)


def location(cfg):
    """(city, lat, lon). Auto-detect via ip-api.com (cached 6 h) unless WEATHER_AUTO=0."""
    fallback = (cfg.get("LOCATION_NAME", "London, UK"), cfg.get("LAT", "51.5074"), cfg.get("LON", "-0.1278"))
    if cfg.get("WEATHER_AUTO", "1") != "1":
        return fallback
    cache = os.path.join(CACHE, "location.json")
    try:
        if time.time() - os.path.getmtime(cache) < 6 * 3600:
            with open(cache, encoding="utf-8") as f:
                d = json.load(f)
            return d["city"], d["lat"], d["lon"]
    except (OSError, KeyError, ValueError):
        pass
    try:
        d = get_json("http://ip-api.com/json/?fields=status,countryCode,city,lat,lon", timeout=8)
        if d.get("status") == "success" and d.get("city"):
            loc = {"city": f'{d["city"]}, {d["countryCode"]}', "lat": str(d["lat"]), "lon": str(d["lon"])}
            os.makedirs(CACHE, exist_ok=True)
            with open(cache, "w", encoding="utf-8") as f:
                json.dump(loc, f)
            return loc["city"], loc["lat"], loc["lon"]
    except Exception:
        pass
    return fallback


def fetch_once():
    cfg = read_settings()
    city, lat, lon = location(cfg)
    imperial = cfg.get("UNITS", "metric") == "imperial"
    q = {
        "latitude": lat, "longitude": lon, "timezone": "auto", "forecast_days": 1,
        "current": "temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m,weather_code",
        "daily": "temperature_2m_max,temperature_2m_min",
        "temperature_unit": "fahrenheit" if imperial else "celsius",
        "wind_speed_unit": "mph" if imperial else "kmh",
    }
    d = get_json("https://api.open-meteo.com/v1/forecast?" + urllib.parse.urlencode(q))
    cur, day = d["current"], d["daily"]
    code = int(cur["weather_code"])
    write_kv({
        "city": city,
        "temp": round(cur["temperature_2m"]),
        "feels": round(cur["apparent_temperature"]),
        "humidity": round(cur["relative_humidity_2m"]),
        "wind": round(cur["wind_speed_10m"]),
        "code": code,
        "desc": WMO.get(code, "Unknown"),
        "hi": round(day["temperature_2m_max"][0]),
        "lo": round(day["temperature_2m_min"][0]),
        "updated": int(time.time()),
    })


def main():
    daemon = "--daemon" in sys.argv
    while True:
        ok = True
        try:
            fetch_once()
        except Exception as e:  # network down, API hiccup, bad JSON ...
            ok = False
            try:
                old = {}
                p = os.path.join(CACHE, "weather.kv")
                if os.path.exists(p):
                    with open(p, encoding="utf-8") as f:
                        for line in f:
                            if "=" in line:
                                k, v = line.rstrip("\n").split("=", 1)
                                old[k] = v
                old["error"] = type(e).__name__
                write_kv(old)
            except Exception:
                pass
            if not daemon:
                print(f"weather fetch failed: {e}", file=sys.stderr)
        if not daemon:
            sys.exit(0 if ok else 1)
        time.sleep(1800 if ok else 120)


if __name__ == "__main__":
    main()
