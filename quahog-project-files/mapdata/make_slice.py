import json, math

import os
_HERE=os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(_HERE,"nb_slice.osm.json")
OUT = os.path.normpath(os.path.join(_HERE,"..","..","QUAHOG_Web","public","slice-newbedford.json"))

# slice-local origin = bbox center (player spawns near 0,0)
OLAT, OLON = 41.636, -70.9205
M_LAT = 111320.0
M_LON = 111320.0 * math.cos(math.radians(OLAT))
def proj(lon, lat): return [round((lon-OLON)*M_LON, 2), round((lat-OLAT)*M_LAT, 2)]

ROAD_W = {"motorway":16,"trunk":14,"primary":12,"secondary":10,"tertiary":8,
          "residential":7,"unclassified":7,"service":4.5,"living_street":5,
          "pedestrian":5,"footway":2.5,"path":2,"steps":2,"cycleway":2.5}
# landmarks to flag as "hero" candidates for hand-detailing
HERO = {"Seamen's Bethel","New Bedford Whaling Museum","Mariner's Home",
        "Double Bank Building","Rodman Candleworks"}

data = json.load(open(SRC))
buildings, roads, landmarks, water = [], [], [], []

def way_xy(el): return [proj(p["lon"], p["lat"]) for p in el.get("geometry", [])]
def pts_xy(geom): return [proj(p["lon"], p["lat"]) for p in geom]
def centroid(ring):
    xs=[p[0] for p in ring]; ys=[p[1] for p in ring]
    return [round(sum(xs)/len(xs),2), round(sum(ys)/len(ys),2)]
def _d(a,b): return math.hypot(a[0]-b[0], a[1]-b[1])

def assemble_rings(segments):
    """Stitch multipolygon member ways (lists of [e,n]) into closed rings."""
    segs=[list(s) for s in segments if len(s)>=2]
    rings=[]
    while segs:
        ring=segs.pop(0)
        changed=True
        while changed and _d(ring[0],ring[-1])>0.5:
            changed=False
            for i,s in enumerate(segs):
                if   _d(ring[-1],s[0])<0.5:  ring+=s[1:];                 segs.pop(i); changed=True; break
                elif _d(ring[-1],s[-1])<0.5: ring+=list(reversed(s))[1:]; segs.pop(i); changed=True; break
                elif _d(ring[0],s[-1])<0.5:  ring=s[:-1]+ring;            segs.pop(i); changed=True; break
                elif _d(ring[0],s[0])<0.5:   ring=list(reversed(s))[:-1]+ring; segs.pop(i); changed=True; break
        if len(ring)>=3: rings.append(ring)
    return rings

for el in data["elements"]:
    t = el.get("tags", {})
    if el["type"]=="way" and t.get("building"):
        ring = way_xy(el)
        if len(ring) < 4: continue
        if ring[0]==ring[-1]: ring=ring[:-1]
        if len(ring) < 3: continue
        lvls = t.get("building:levels")
        try: h = float(lvls)*3.5 if lvls else 8.0
        except ValueError: h = 8.0
        if t.get("height"):
            try: h = float(str(t["height"]).split()[0])
            except ValueError: pass
        b = {"footprint": ring, "height": round(h,1)}
        if t.get("name"): b["name"] = t["name"]
        buildings.append(b)
    elif el["type"]=="way" and t.get("highway"):
        pts = way_xy(el)
        if len(pts) < 2: continue
        r = {"highway":t["highway"],"width":ROAD_W.get(t["highway"],6),
             "name":t.get("name"),"points":pts}
        if t.get("bridge") and t.get("bridge") != "no":
            r["bridge"] = True
            try: r["layer"] = int(t.get("layer", 1))
            except ValueError: r["layer"] = 1
        roads.append(r)
    elif el["type"]=="way" and (t.get("natural")=="water" or t.get("waterway")=="riverbank"):
        ring = way_xy(el)
        if len(ring) >= 3:
            if ring[0]==ring[-1]: ring=ring[:-1]
            water.append(ring)
    elif el["type"]=="relation" and t.get("natural")=="water":
        members = el.get("members", [])
        outer = [pts_xy(m["geometry"]) for m in members
                 if m.get("type")=="way" and m.get("geometry")
                 and m.get("role","outer") in ("outer","")]
        for ring in assemble_rings(outer):
            if len(ring) >= 3: water.append(ring)
    if t.get("name") and (t.get("historic") or t.get("tourism") or
                          t.get("amenity") in ("place_of_worship","ferry_terminal","theatre",
                                               "hospital","police","townhall","library")):
        # point: node coords, or way centroid
        if el["type"]=="node":
            pt = proj(el["lon"], el["lat"])
        else:
            g = way_xy(el)
            if not g: continue
            pt = centroid(g)
        kind = t.get("historic") or t.get("tourism") or t.get("amenity")
        lm = {"name":t["name"],"kind":kind,"pos":pt}
        if t["name"] in HERO: lm["hero"]=True
        landmarks.append(lm)

# de-dup landmarks by name (node+way duplicates), prefer one with hero flag
seen={}
for lm in landmarks:
    k=lm["name"]
    if k not in seen or lm.get("hero"): seen[k]=lm
landmarks=list(seen.values())

slice_obj = {
    "name": "New Bedford · Fairhaven · Dartmouth · Sconticut Neck",
    "origin": {"lat":OLAT,"lon":OLON},
    "meters_per_degree": {"lat":M_LAT,"lon":round(M_LON,3)},
    "axes": "x=east(m), z=south is +? -> see note; y=up",
    "note": "x=east meters, y=north meters in 2D arrays; in 3D use x=east, z=-y(north), y=up",
    "attribution": "© OpenStreetMap contributors, ODbL",
    "buildings": buildings,
    "roads": roads,
    "water": water,
    "landmarks": sorted(landmarks, key=lambda l:(not l.get('hero',False), l['name'])),
}
json.dump(slice_obj, open(OUT,"w"))
import os
print(f"buildings={len(buildings)} roads={len(roads)} water={len(water)} landmarks={len(landmarks)}")
print(f"{OUT}: {os.path.getsize(OUT)/1024:.0f} KB")
print("heroes:", [l['name'] for l in landmarks if l.get('hero')])
print("water ring sizes:", [len(w) for w in water][:8])
