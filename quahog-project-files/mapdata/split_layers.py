import json, os

import os
SRC = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(SRC, "layers")
os.makedirs(OUT, exist_ok=True)

CITIES = {"fall-river": "Fall River", "new-bedford": "New Bedford"}

# keep tile sizes small: curated property sets per layer
ROAD_KEEP = ("highway","name","oneway","maxspeed","lanes","bridge","tunnel","ref","surface")
KEEP_NAME = ("name",)

layers = {k: [] for k in ("roads","rail","waterways","water","coastline","boundary")}

def pick(props, keys):
    return {k: props[k] for k in keys if k in props}

for slug, city in CITIES.items():
    fc = json.load(open(f"{SRC}/{slug}.geojson"))
    for f in fc["features"]:
        t = f.get("properties", {})
        if t.get("highway"):
            lyr, keep = "roads", ROAD_KEEP
        elif t.get("railway"):
            lyr, keep = "rail", ("railway",)+KEEP_NAME
        elif t.get("waterway"):
            lyr, keep = "waterways", ("waterway",)+KEEP_NAME
        elif t.get("natural") == "water":
            lyr, keep = "water", KEEP_NAME
        elif t.get("natural") == "coastline":
            lyr, keep = "coastline", ()
        elif t.get("boundary") == "administrative":
            lyr, keep = "boundary", ("name","admin_level")
        else:
            continue
        props = pick(t, keep)
        props["city"] = city
        layers[lyr].append({"type":"Feature","geometry":f["geometry"],"properties":props})

for lyr, feats in layers.items():
    json.dump({"type":"FeatureCollection","features":feats},
              open(f"{OUT}/{lyr}.geojson","w"))
    print(f"{lyr:10s} {len(feats):5d} features")
