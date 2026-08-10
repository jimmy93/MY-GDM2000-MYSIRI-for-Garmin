#!/usr/bin/env python3
"""make_launcher_icon.py -- dependency-free 4-bit indexed PNG launcher icon.

Generates resources/icons/launcher_icon.png (48x48) with a simple "E/N"
cross-hair grid glyph for the Connect IQ launcher icon resource, using a
hand-rolled minimal PNG writer (no Pillow needed).

Usage: python tools/make_launcher_icon.py
"""
import os
import struct
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "resources", "icons", "launcher_icon.png")

SIZE = 40
# f?nix 3-style palette (index 0 = background black).
PALETTE = [
    (0x00, 0x00, 0x00),   # 0 black (bg)
    (0xFF, 0xFF, 0xFF),   # 1 white
    (0x55, 0x55, 0x55),   # 2 dark gray
    (0x00, 0xAA, 0x00),   # 3 green
    (0xFF, 0xAA, 0x00),   # 4 yellow
    (0xFF, 0x55, 0x00),   # 5 orange
    (0xAA, 0x00, 0x00),   # 6 dark red
    (0x00, 0x00, 0xFF),   # 7 dark blue
] + [(0, 0, 0)] * 8       # pad to 16 entries


def build_indexed_rows():
    """Return list of byte rows, each = filter byte + packed 4-bit indices."""
    rows = []
    for y in range(SIZE):
        row = [0]  # filter byte 0 (None) for each scanline
        for x in range(SIZE):
            # Default: background (0)
            idx = 0
            # Thin border
            if x in (1, SIZE - 2) or y in (1, SIZE - 2):
                idx = 1
            # Cross-hair grid lines
            if x == SIZE // 2 and 6 <= y <= SIZE - 6:
                idx = 2
            if y == SIZE // 2 and 8 <= x <= SIZE - 8:
                idx = 2
            # Green position dot
            if (SIZE // 2 - 3 <= x <= SIZE // 2 + 3 and
                    SIZE // 2 - 3 <= y <= SIZE // 2 + 3):
                idx = 3
            # "E" and "N" hints (blocky letters)
            if 10 <= x <= 14 and 8 <= y <= 14:
                if y == 8 or y == 14 or x == 10:
                    idx = 1
            if 10 <= x <= 14 and SIZE - 16 <= y <= SIZE - 10:
                if y == SIZE - 16 or y == SIZE - 10 or x == 10:
                    idx = 1
            # pack two 4-bit pixels per byte
            if x % 2 == 0:
                row.append(idx << 4)
            else:
                row[-1] |= idx
        rows.append(bytes(row))
    return b"".join(rows)


def chunk(tag, data):
    c = struct.pack(">I", len(data)) + tag + data
    c += struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    return c


def main():
    raw = build_indexed_rows()

    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 4, 4, 0, 0, 0)  # 4-bit, color type 3
    plte = b"".join(struct.pack("BBB", *rgb) for rgb in PALETTE)
    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", ihdr)
           + chunk(b"PLTE", plte)
           + chunk(b"IDAT", zlib.compress(raw, 9))
           + chunk(b"IEND", b""))

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "wb") as f:
        f.write(png)
    print("Wrote %s (%d bytes)" % (OUT, len(png)))


if __name__ == "__main__":
    main()

