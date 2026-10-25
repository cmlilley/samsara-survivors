#!/usr/bin/env python3
"""Generate the world's decoration layer as packed tile data.

The world is a 96x96 tile grid (768x768 px). Each tile gets a 2-bit
decoration code: 0 none, 1 grass tuft, 2 flower A (sprite 151),
3 flower B (sprite 152). 9216 tiles x 2 bits = 2304 bytes, written as
18 rows of 128 bytes into assets/world_map.txt; build_cart.py places
them in the cart's __map__ section (rows 0-17, the non-shared map
memory at 0x2000). The game reads them back with peek() and blits
sprites: no scatter math in the game code, and the world layout is
data that can be edited directly.

Clearings are kept bare around shrines, houses, and the spawn point.
Deterministic: fixed seed, same data every build.
"""
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def main():
    lua = (ROOT / "src" / "main.lua").read_text()
    clearings = []
    pl = lua.split("PL=")[1].split("}}")[0]
    for x, y in re.findall(r"x=(\d+),y=(\d+)", pl):
        clearings.append((int(x), int(y), 30))
    anc = [int(v) for v in re.search(r'ANC=split\("([^"]*)"\)', lua).group(1).split(",")]
    for i in range(0, len(anc), 2):
        clearings.append((anc[i] + 12, anc[i + 1] + 12, 34))
    clearings.append((384, 384, 28))
    rng = random.Random(20261025)
    data = bytearray(2304)
    counts = [0, 0, 0, 0]
    for gy in range(96):
        for gx in range(96):
            cx, cy = gx * 8 + 4, gy * 8 + 4
            v = 0
            if not any((cx - px) ** 2 + (cy - py) ** 2 < r * r for px, py, r in clearings):
                roll = rng.random()
                v = 1 if roll < 0.100 else 2 if roll < 0.110 else 3 if roll < 0.115 else 0
            counts[v] += 1
            n = gy * 96 + gx
            data[n // 4] |= v << ((n % 4) * 2)
    lines = ["".join("%02x" % b for b in data[r * 128:(r + 1) * 128]) for r in range(18)]
    (ROOT / "assets" / "world_map.txt").write_text("\n".join(lines) + "\n")
    print("world map written: counts none/tuft/flowerA/flowerB =", counts)

if __name__ == "__main__":
    main()
