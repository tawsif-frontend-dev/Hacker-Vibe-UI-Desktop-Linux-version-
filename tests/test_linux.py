import hashlib
import importlib.util
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LINUX = ROOT / "linux"


def load_weather_module():
    path = LINUX / "libexec" / "weather.py"
    spec = importlib.util.spec_from_file_location("hackervibe_weather", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class LinuxProductTests(unittest.TestCase):
    def test_legacy_font_license_notices_are_present(self):
        fonts = ROOT / "Skins" / "HackerSuite" / "@Resources" / "Fonts"
        license_text = (fonts / "LICENSE-Apache-2.0.txt").read_text(encoding="utf-8")
        notices = (fonts / "FONT-NOTICES.txt").read_text(encoding="utf-8")
        self.assertIn("Apache License", license_text)
        self.assertIn("Open Sans Light.ttf", notices)
        self.assertIn("Roboto.ttf and Roboto Light.ttf", notices)

    def test_ip_location_lookup_is_opt_in(self):
        weather = load_weather_module()
        with tempfile.TemporaryDirectory() as cache:
            weather.CACHE = cache
            calls = []
            weather.get_json = lambda url, timeout=15: calls.append(url) or {}

            self.assertEqual(
                weather.location({}),
                ("London, UK", "51.5074", "-0.1278"),
            )
            self.assertEqual(calls, [])

            weather.location({"WEATHER_AUTO": "1"})
            self.assertEqual(len(calls), 1)
            self.assertIn("ip-api.com", calls[0])

        settings = (LINUX / "config" / "settings.conf").read_text(encoding="utf-8")
        lua = (LINUX / "lib" / "hv.lua").read_text(encoding="utf-8")
        self.assertIn('WEATHER_AUTO="0"', settings)
        self.assertIn("WEATHER_AUTO = '0'", lua)

    def test_renderer_writes_to_output_without_changing_base_assets(self):
        source_base = ROOT / "Skins" / "HackerSuite" / "@Resources" / "Wallpaper" / "Base"
        renderer = LINUX / "tools" / "render_wallpapers.py"
        themes = ("Blue", "Green", "Red", "Purple")
        with tempfile.TemporaryDirectory() as temporary_directory:
            temporary = Path(temporary_directory)
            base = temporary / "base"
            output = temporary / "output"
            base.mkdir()
            for theme in themes:
                filename = f"Hacker_Wallpaper_{theme}_1920x1080.png"
                shutil.copy2(source_base / filename, base / filename)
            original = {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in base.iterdir()}

            subprocess.run(
                [sys.executable, str(renderer), "--name", "Test User", "--base", str(base), "--out", str(output)],
                check=True,
                capture_output=True,
                text=True,
            )

            self.assertEqual(set(original), {path.name for path in output.glob("*.png")})
            self.assertEqual(original, {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in base.iterdir()})

    def test_installer_uses_linux_renderer_and_quotes_shortcut_url(self):
        installer = (LINUX / "install.sh").read_text(encoding="utf-8")
        self.assertIn('"$HERE/tools/render_wallpapers.py"', installer)
        self.assertIn('--base "$RES/Wallpaper/Base"', installer)
        self.assertIn('--out "$DATA_DIR/wallpapers"', installer)
        self.assertIn('SHORTCUT3_CMD "xdg-open $(shell_quote "$URL")"', installer)


if __name__ == "__main__":
    unittest.main()
