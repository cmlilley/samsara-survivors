#!/usr/bin/env python3
"""Build samsara.p8 from src/main.lua + assets/sprite-sheet.png.

Source of truth is the Lua file and the sprite sheet PNG (authored by
the art pipeline in ~/workspace/samsara-work). This script converts
the sheet into PICO-8 __gfx__ text (one hex digit per pixel) and
assembles the cart.

Usage:
    python3 tools/build_cart.py           # writes ./samsara.p8
"""
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent

PALETTE = [
    (0, 0, 0), (29, 43, 83), (126, 37, 83), (0, 135, 81),
    (171, 82, 54), (95, 87, 79), (194, 195, 199), (255, 241, 232),
    (255, 0, 77), (255, 163, 0), (255, 236, 39), (0, 228, 54),
    (41, 173, 255), (131, 118, 156), (255, 119, 168), (255, 204, 170),
]
PAL = {rgb: i for i, rgb in enumerate(PALETTE)}


def gfx_lines():
    img = Image.open(ROOT / "assets" / "sprite-sheet.png").convert("RGB")
    assert img.size == (128, 128), img.size
    px = img.load()
    lines = []
    for y in range(128):
        lines.append("".join("%x" % PAL[px[x, y]] for x in range(128)))
    return lines


def token_estimate(lua):
    """Rough PICO-8 token count: strings count once, comments free,
    identifiers/numbers/keywords/operators count once each."""
    lua = re.sub(r"--\[\[.*?\]\]", "", lua, flags=re.S)
    lua = re.sub(r"--[^\n]*", "", lua)
    n_strings = len(re.findall(r'"(?:[^"\\]|\\.)*"', lua))
    lua = re.sub(r'"(?:[^"\\]|\\.)*"', '""', lua)
    toks = re.findall(r"[A-Za-z_][A-Za-z0-9_]*|\d+\.?\d*|==|~=|<=|>=|\.\.|[-+*/%^#=<>;:,.()\[\]{}]", lua)
    punct = sum(1 for t in toks if t in "(),;:")
    return len(toks) - punct + n_strings


def main():
    lua = (ROOT / "src" / "main.lua").read_text()
    cart = ["pico-8 cartridge // http://www.pico-8.com",
            "version 42",
            "__lua__",
            lua.rstrip("\n"),
            "__gfx__"] + gfx_lines()
    world_map = ROOT / "assets" / "world_map.txt"
    if world_map.exists():
        cart += ["__map__"] + world_map.read_text().rstrip("\n").split("\n")
    audio = ROOT / "assets" / "audio_sections.txt"
    if audio.exists():
        cart += audio.read_text().rstrip("\n").split("\n")
    out = ROOT / "samsara.p8"
    out.write_text("\n".join(cart) + "\n")
    print("wrote", out, "| lua chars:", len(lua),
          "| rough token estimate:", token_estimate(lua), "of 8192")


if __name__ == "__main__":
    main()
