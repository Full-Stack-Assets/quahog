#!/usr/bin/env python3
"""Gzip-compress the map data in place (tiles/*.json, slice, overlays) and drop
the plain originals. Map data ships compressed so the web download stays small —
footprint/road JSON compresses to ~25% of its size. The game reads the .gz
transparently (MapLoader.read_json_any inflates with COMPRESSION_GZIP).

The data-gen tools (refresh_buildings.py / split_road_tiles.py) already emit
.gz directly; run this only to recompress if a plain .json sneaks back in.
"""
import gzip, glob, os, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
MAP = os.path.normpath(os.path.join(HERE, "..", "..", "QUAHOG_GODOT1", "data", "map"))


def main():
    targets = (glob.glob(os.path.join(MAP, "tiles", "*.json"))
               + glob.glob(os.path.join(MAP, "*.json"))
               + glob.glob(os.path.join(MAP, "overlays", "*.json")))
    n = before = after = 0
    for p in targets:
        b = os.path.getsize(p); before += b
        with open(p, "rb") as fi, gzip.open(p + ".gz", "wb", compresslevel=9) as fo:
            shutil.copyfileobj(fi, fo)
        after += os.path.getsize(p + ".gz")
        os.remove(p); n += 1
    if n:
        print(f"compressed {n} files: {before/1e6:.1f}MB -> {after/1e6:.1f}MB ({100*after/before:.0f}%)")
    else:
        print("nothing to compress (all data already gzipped)")


if __name__ == "__main__":
    main()
