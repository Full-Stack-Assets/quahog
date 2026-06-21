import json, math, os

import os
SRC = os.path.dirname(os.path.abspath(__file__))
CITIES = ["fall-river", "new-bedford"]

# road half-widths (meters) by OSM highway class
WIDTH = {
    "motorway":16,"trunk":14,"primary":12,"secondary":10,"tertiary":8,
    "unclassified":6,"residential":6,"living_street":5,"service":4,
    "motorway_link":8,"trunk_link":7,"primary_link":7,"secondary_link":6,"tertiary_link":5,
    "pedestrian":4,"footway":2,"path":2,"cycleway":2,"steps":2,"track":3,
}
def half_width(hw): return WIDTH.get(hw, 6) / 2.0

# ---- load both cities, gather extent for a shared local origin ----
feats = []
lats=[]; lons=[]
for slug in CITIES:
    fc = json.load(open(f"{SRC}/{slug}.geojson"))
    for f in fc["features"]:
        feats.append(f)
        g = f["geometry"]
        def scan(c):
            if isinstance(c[0],(int,float)): lons.append(c[0]); lats.append(c[1])
            else:
                for x in c: scan(x)
        scan(g["coordinates"])

olat = (min(lats)+max(lats))/2.0
olon = (min(lons)+max(lons))/2.0
M_LAT = 111320.0
M_LON = 111320.0 * math.cos(math.radians(olat))
def proj(lon, lat):          # -> (x east, z north) meters, origin at center
    return ((lon-olon)*M_LON, (lat-olat)*M_LAT)

# ---- OBJ writer (y-up, ground plane x/z, y=0 roads, y=-0.2 water) ----
obj = []
vcount = 0
def add_quad(p1,p2,p3,p4,y):     # CCW
    global vcount
    for (x,z) in (p1,p2,p3,p4):
        obj.append(f"v {x:.3f} {y:.3f} {z:.3f}")
    a=vcount+1
    obj.append(f"f {a} {a+1} {a+2}")
    obj.append(f"f {a} {a+2} {a+3}")
    vcount += 4
def add_tri(p1,p2,p3,y):
    global vcount
    for (x,z) in (p1,p2,p3):
        obj.append(f"v {x:.3f} {y:.3f} {z:.3f}")
    a=vcount+1; obj.append(f"f {a} {a+1} {a+2}"); vcount += 3

# ---- ear-clipping triangulation for simple polygons ----
def area2(poly):
    s=0
    for i in range(len(poly)):
        x1,z1=poly[i]; x2,z2=poly[(i+1)%len(poly)]; s+=x1*z2-x2*z1
    return s
def pt_in_tri(p,a,b,c):
    def sign(o,u,v): return (o[0]-v[0])*(u[1]-v[1])-(u[0]-v[0])*(o[1]-v[1])
    d1,d2,d3=sign(p,a,b),sign(p,b,c),sign(p,c,a)
    neg=(d1<0)or(d2<0)or(d3<0); pos=(d1>0)or(d2>0)or(d3>0)
    return not(neg and pos)
def earclip(poly):
    poly=poly[:]
    if area2(poly)<0: poly.reverse()        # ensure CCW
    idx=list(range(len(poly))); tris=[]
    guard=0
    while len(idx)>3 and guard<10000:
        guard+=1; ear=False
        for k in range(len(idx)):
            i0,i1,i2=idx[(k-1)%len(idx)],idx[k],idx[(k+1)%len(idx)]
            a,b,c=poly[i0],poly[i1],poly[i2]
            cross=(b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
            if cross<=0: continue            # reflex
            if any(pt_in_tri(poly[j],a,b,c) for j in idx if j not in (i0,i1,i2)): continue
            tris.append((a,b,c)); del idx[k]; ear=True; break
        if not ear: break
    if len(idx)==3:
        tris.append((poly[idx[0]],poly[idx[1]],poly[idx[2]]))
    return tris

# ---- build geometry + road graph ----
roads_graph = []
n_road=n_water=0
obj.append("o roads")
for f in feats:
    t=f["properties"]; g=f["geometry"]
    if t.get("highway") and g["type"]=="LineString":
        pts=[proj(x,y) for x,y in g["coordinates"]]
        if len(pts)<2: continue
        hw=t["highway"]; hwid=half_width(hw)
        for i in range(len(pts)-1):
            (x1,z1),(x2,z2)=pts[i],pts[i+1]
            dx,dz=x2-x1,z2-z1; L=math.hypot(dx,dz)
            if L<1e-6: continue
            nx,nz=-dz/L*hwid, dx/L*hwid
            add_quad((x1+nx,z1+nz),(x2+nx,z2+nz),(x2-nx,z2-nz),(x1-nx,z1-nz),0.0)
        roads_graph.append({
            "name": t.get("name"), "highway": hw, "city": t.get("city"),
            "width": round(hwid*2,1),
            "oneway": t.get("oneway")=="yes",
            "points": [[round(x,2),round(z,2)] for x,z in pts],
        })
        n_road+=1

obj.append("o water")
for f in feats:
    t=f["properties"]; g=f["geometry"]
    if t.get("natural")=="water" and g["type"]=="Polygon":
        ring=[proj(x,y) for x,y in g["coordinates"][0]]
        if len(ring)>3 and ring[0]==ring[-1]: ring=ring[:-1]
        if len(ring)<3: continue
        for a,b,c in earclip(ring): add_tri(a,b,c,-0.2)
        n_water+=1

# ---- write OBJ ----
open(f"{SRC}/southcoast.obj","w").write(
    "# QUAHOG South Coast baked mesh — y-up, meters, origin at "
    f"lat={olat:.6f} lon={olon:.6f}\n"
    "# Data © OpenStreetMap contributors, ODbL\n" + "\n".join(obj)+"\n")

# ---- write road graph for the spawner ----
json.dump({
    "origin": {"lat":olat,"lon":olon},
    "meters_per_degree": {"lat":M_LAT,"lon":round(M_LON,3)},
    "axes": "x=east(m), z=north(m), y=up",
    "attribution": "© OpenStreetMap contributors, ODbL",
    "road_count": len(roads_graph),
    "roads": roads_graph,
}, open(f"{SRC}/southcoast-roads.json","w"))

print(f"origin lat={olat:.6f} lon={olon:.6f}")
print(f"roads meshed: {n_road}   water polys: {n_water}   vertices: {vcount}")
print(f"road graph entries: {len(roads_graph)}")
for p in ("southcoast.obj","southcoast-roads.json"):
    print(f"  {p}: {os.path.getsize(SRC+'/'+p)/1e6:.2f} MB")
