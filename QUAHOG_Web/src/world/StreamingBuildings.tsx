import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { mergeGeometries } from "three/examples/jsm/utils/BufferGeometryUtils.js";
import { RigidBody } from "@react-three/rapier";
import { shared } from "../shared";
import { Buildings } from "./Buildings";
import { makeFacadeMaps, makeNoiseNormal, FACADE_GRID, FACADE_VARIANTS } from "./textures";
import type { Building } from "../slice";

// Multi-tile building streamer (Step 19). Loads building tiles (public/tiles/
// b_<gx>_<gn>.json) within VIEW_R of the player and drops them when far, so
// memory/draw stays bounded as the map grows to the whole South Coast. The
// player's own tile + neighbours (COLLIDE_R) get a static collider. Falls back
// to the monolithic <Buildings> if the manifest isn't present.

const VIEW_R = 3;     // tiles loaded around the player (each TILE metres)
const COLLIDE_R = 1;  // tiles that get physics colliders
const WINDOW_GLOW = new THREE.Color("#ffcf8a");
// New Bedford palette: brick reds, painted clapboard, weathered wood (short
// residential/commercial) vs granite + concrete (tall downtown).
const WARM = ["#7e463a", "#8a5a48", "#9c6347", "#a8514a", "#6e4a3e", "#b0a48c", "#c2bcae", "#5e6b66", "#8a9488", "#b8b0a0"];
const GREY = ["#7c7e88", "#9aa0a6", "#8f8c86", "#6f7178", "#a7a59c", "#86837c"];
const ROOF = ["#2c2a28", "#37322c", "#31343a", "#2a2e30", "#3a352f"]; // tar / gravel roofs
// Real materials for the Johnny Cake Hill hero buildings (was a flat gold marker):
// white clapboard for the wood Federal/Greek-revival ones, red brick + granite for
// the institutional ones.
const HERO_COLORS: Record<string, string> = {
  "Mariner's Home": "#dcd8cc",            // white clapboard
  "New Bedford Whaling Museum": "#7c3b30", // red brick
  "Double Bank Building": "#bcb6a8",       // granite Greek revival
  "Rodman Candleworks": "#c4bdaf",         // granite
  "Seamen's Bethel": "#e6e2d8",            // white clapboard (also modelled separately)
};
const HERO = new Set(Object.keys(HERO_COLORS));
const FLOOR = 3.2; // metres per window row
// Buildings shorter than this get a peaked (hip) roof — New Bedford's signature
// triple-deckers/houses read as boxes when flat-topped. Taller granite downtown
// + brick mills keep their realistic flat roofs.
const PITCH_MAX_H = 14;

/**
 * A peaked hip roof capping a footprint: fan of triangles from each footprint
 * edge (at wall height `h`) up to a single apex over the centroid. Robust for
 * any polygon — concave footprints just give a slightly creased cap, never a
 * crash. Returns a non-indexed BufferGeometry with position/normal/uv/color so
 * it merges with the extruded walls. Plain UV (no window grid) + roof tone.
 */
function roofGeometry(footprint: [number, number][], h: number, roof: THREE.Color): THREE.BufferGeometry | null {
  // de-dupe a closed ring's repeated last vertex
  const pts = footprint.slice();
  if (pts.length > 1) {
    const [fe, fn] = pts[0], [le, ln] = pts[pts.length - 1];
    if (Math.abs(fe - le) < 1e-6 && Math.abs(fn - ln) < 1e-6) pts.pop();
  }
  if (pts.length < 3) return null;
  let cx = 0, cn = 0, minE = Infinity, maxE = -Infinity, minN = Infinity, maxN = -Infinity;
  for (const [e, n] of pts) {
    cx += e; cn += n;
    if (e < minE) minE = e; if (e > maxE) maxE = e;
    if (n < minN) minN = n; if (n > maxN) maxN = n;
  }
  cx /= pts.length; cn /= pts.length;
  const minHalfSpan = Math.min(maxE - minE, maxN - minN) / 2;
  if (minHalfSpan < 1.5) return null; // too thin to roof cleanly — leave flat
  // Steep enough to clearly read as a New England pitched roof (~35-45°) on
  // typical house/triple-decker widths, capped so wide blocks don't get spikes.
  const pitch = Math.max(2.2, Math.min(5.5, minHalfSpan * 0.9));
  // The fan triangles must wind so their normals face UP/outward, else they're
  // backface-culled (invisible) and the flat extrude cap shows through. OSM
  // footprint orientation varies, so derive the winding from the ring's signed
  // area in world XZ (x=east, z=-north) rather than assuming a fixed order.
  let area2 = 0;
  for (let i = 0; i < pts.length; i++) {
    const [ea, na] = pts[i];
    const [eb, nb] = pts[(i + 1) % pts.length];
    area2 += ea * -nb - eb * -na; // x_i*z_{i+1} - x_{i+1}*z_i, with z=-n
  }
  const flip = area2 > 0; // keeps apex-fan normals pointing up
  const pos: number[] = [];
  for (let i = 0; i < pts.length; i++) {
    const [ea, na] = pts[i];
    const [eb, nb] = pts[(i + 1) % pts.length];
    if (Math.abs(ea - eb) < 1e-6 && Math.abs(na - nb) < 1e-6) continue; // degenerate edge
    // world-local: x=east, y=up, z=-north
    if (flip) pos.push(eb, h, -nb, ea, h, -na, cx, h + pitch, -cn);
    else pos.push(ea, h, -na, eb, h, -nb, cx, h + pitch, -cn);
  }
  if (pos.length === 0) return null;
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.BufferAttribute(new Float32Array(pos), 3));
  g.computeVertexNormals();
  const count = g.attributes.position.count;
  const colors = new Float32Array(count * 3);
  const uv = new Float32Array(count * 2);
  for (let v = 0; v < count; v++) {
    colors.set([roof.r, roof.g, roof.b], v * 3);
    uv[v * 2] = 0.04; uv[v * 2 + 1] = 0.04; // plain wall sample (no window grid)
  }
  g.setAttribute("color", new THREE.BufferAttribute(colors, 3));
  g.setAttribute("uv", new THREE.BufferAttribute(uv, 2));
  return g;
}

interface Manifest { tile: number; keys: string[] }

function pushTri(arr: number[], a: number[], b: number[], c: number[]) {
  arr.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]);
}

// A parapet/cornice ring standing above the roof: extrude the footprint edges
// upward by capH so the flat extrude top becomes a recessed roof behind a rim
// wall — kills the "extruded box" silhouette and gives roofline variation
// (mills get a tall parapet, downtown a shorter cornice). Vertical extrusion of
// the outline → no corner gaps. Coloured a touch darker than the wall as a cap
// band; merges into the wall geometry (plain wall UV, so no windows on the cap).
function parapetGeometry(b: Building, wall: THREE.Color, hash: number): THREE.BufferGeometry | null {
  const fp = b.footprint;
  if (fp.length < 3) return null;
  const H = b.height;
  // Roofline variety so the skyline isn't a row of identically-rimmed boxes. A
  // second hash (decoupled from the colour/window hash) picks the parapet style:
  // ~28% of short blocks get a tall Main-Street "false front", the rest a normal
  // cornice that still varies in height.
  const r2 = (b.footprint.length * 0.27 + H * 0.13 + hash * 0.5) % 1;
  const falseFront = H < 16 && r2 > 0.72;
  const capH = falseFront ? 1.6 + r2 * 1.4
             : H < 14 ? 0.5 + hash * 0.4
             : H < 32 ? 1.1 + hash * 0.7
             : 0.9 + hash * 0.5;
  let cx = 0, cn = 0;
  for (const [e, n] of fp) { cx += e; cn += n; }
  cx /= fp.length; cn /= fp.length;
  const cz = -cn; // world-space centroid z
  const pos: number[] = [];
  for (let i = 0; i < fp.length; i++) {
    const [e1, n1] = fp[i];
    const [e2, n2] = fp[(i + 1) % fp.length];
    const ax = e1, az = -n1, bx = e2, bz = -n2; // world: x=east, z=-north
    const dx = bx - ax, dz = bz - az;
    if (Math.hypot(dx, dz) < 1e-3) continue;
    // outward = left normal (-dz, dx) if it points away from the centroid
    const mx = (ax + bx) / 2, mz = (az + bz) / 2;
    const outward = (-dz) * (mx - cx) + dx * (mz - cz) >= 0;
    const v0 = [ax, H, az], v1 = [bx, H, bz];
    const v2 = [bx, H + capH, bz], v3 = [ax, H + capH, az];
    if (outward) { pushTri(pos, v0, v1, v2); pushTri(pos, v0, v2, v3); }
    else         { pushTri(pos, v0, v2, v1); pushTri(pos, v0, v3, v2); }
  }
  if (!pos.length) return null;
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.computeVertexNormals();
  const count = g.attributes.position.count;
  const colors = new Float32Array(count * 3);
  const uv = new Float32Array(count * 2);
  const trim = wall.clone().multiplyScalar(0.9);
  for (let v = 0; v < count; v++) {
    colors.set([trim.r, trim.g, trim.b], v * 3);
    uv[v * 2] = 0.02; uv[v * 2 + 1] = 0.02; // plain wall UV → no windows on the cap
  }
  g.setAttribute("color", new THREE.BufferAttribute(colors, 3));
  g.setAttribute("uv", new THREE.BufferAttribute(uv, 2));
  return g;
}

// A ground-floor base course / storefront band: a battered stone plinth at the
// foot of each building. Bottom edge is pushed outward by OUT, top edge stays
// flush with the wall — the face is angled (never coplanar with the wall, so no
// z-fighting; top meets the wall corners exactly, so no gaps). Coloured a darker
// cool stone with plain wall UV (no windows) so the street level reads as a
// shopfront/granite base instead of more of the same window grid.
function baseGeometry(b: Building, wall: THREE.Color, hash: number): THREE.BufferGeometry | null {
  const fp = b.footprint;
  if (fp.length < 3 || b.height < 6) return null;
  const baseH = Math.min(b.height >= 14 ? 3.6 : 2.6 + hash * 0.5, b.height * 0.5);
  const OUT = 0.16; // how much wider the plinth is at grade than at its top
  let cx = 0, cn = 0;
  for (const [e, n] of fp) { cx += e; cn += n; }
  cx /= fp.length; cn /= fp.length;
  const cz = -cn;
  const pos: number[] = [];
  for (let i = 0; i < fp.length; i++) {
    const [e1, n1] = fp[i];
    const [e2, n2] = fp[(i + 1) % fp.length];
    const ax = e1, az = -n1, bx = e2, bz = -n2;
    const dx = bx - ax, dz = bz - az;
    const len = Math.hypot(dx, dz);
    if (len < 1e-3) continue;
    const mx = (ax + bx) / 2, mz = (az + bz) / 2;
    const outward = (-dz) * (mx - cx) + dx * (mz - cz) >= 0;
    // outward unit normal (matching the winding test) to push the base out
    let nx = -dz / len, nz = dx / len;
    if (!outward) { nx = -nx; nz = -nz; }
    const ox = nx * OUT, oz = nz * OUT;
    const v0 = [ax + ox, 0, az + oz], v1 = [bx + ox, 0, bz + oz]; // splayed grade edge
    const v2 = [bx, baseH, bz], v3 = [ax, baseH, az];             // flush top edge
    if (outward) { pushTri(pos, v0, v1, v2); pushTri(pos, v0, v2, v3); }
    else         { pushTri(pos, v0, v2, v1); pushTri(pos, v0, v3, v2); }
  }
  if (!pos.length) return null;
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.computeVertexNormals();
  const count = g.attributes.position.count;
  const colors = new Float32Array(count * 3);
  const uv = new Float32Array(count * 2);
  // cool granite/shopfront tone: pull the wall colour toward dark stone + darken
  const stone = wall.clone().lerp(new THREE.Color("#43474d"), 0.5).multiplyScalar(0.78);
  for (let v = 0; v < count; v++) {
    colors.set([stone.r, stone.g, stone.b], v * 3);
    uv[v * 2] = 0.02; uv[v * 2 + 1] = 0.02; // plain wall UV → no windows on the base
  }
  g.setAttribute("color", new THREE.BufferAttribute(colors, 3));
  g.setAttribute("uv", new THREE.BufferAttribute(uv, 2));
  return g;
}

// Returns one merged geometry per façade variant (or null for an empty bucket).
// Buildings are split across variants so neighbours show different window styles
// instead of one shared texture — the core fix for the "repetitive boxes" read.
function tileGeometry(buildings: Building[]): (THREE.BufferGeometry | null)[] {
  const buckets: THREE.BufferGeometry[][] = Array.from({ length: FACADE_VARIANTS }, () => []);
  buildings.forEach((b, i) => {
    const shape = new THREE.Shape();
    b.footprint.forEach(([e, n], k) => (k === 0 ? shape.moveTo(e, n) : shape.lineTo(e, n)));
    const g = new THREE.ExtrudeGeometry(shape, { depth: b.height, bevelEnabled: false });
    g.rotateX(-Math.PI / 2);
    g.computeVertexNormals();
    // colour by use/height (style guide): short = brick/clapboard, tall = granite,
    // with per-building tonal variation so neighbours don't read identical. Roofs
    // get a dark tar tone and sample plain wall (no windows on the roof).
    const pal = b.height >= 14 ? GREY : WARM;
    const isHero = !!(b.name && HERO.has(b.name));
    const hash = (i * 0.6180339887) % 1;
    const hash3 = (i * 0.3819660113) % 1;
    const wall = new THREE.Color(isHero ? (HERO_COLORS[b.name!] ?? "#c2bcae") : pal[i % pal.length]);
    if (!isHero) wall.multiplyScalar(0.78 + hash * 0.42); // wider tonal spread between neighbours
    const roof = new THREE.Color(ROOF[i % ROOF.length]);
    // Per-building window SCALE: floors run taller/shorter (and windows wider/
    // narrower) building-to-building so the street isn't one repeated window grid
    // — the biggest fix for the "repetitive boxes" read. ±~25% around the base.
    const winTile = WIN_TILE * (0.8 + hash3 * 0.5);
    // Per-building façade phase (whole-window steps) so neighbours show a
    // different slice of the 4×4 window grid — varied lit pattern at night.
    const phaseX = Math.floor(hash * FACADE_GRID) / FACADE_GRID;
    const phaseY = Math.floor(((i * 0.7548776662) % 1) * FACADE_GRID) / FACADE_GRID;
    const pos = g.attributes.position, nor = g.attributes.normal;
    const count = pos.count;
    const colors = new Float32Array(count * 3);
    const uv = new Float32Array(count * 2);
    for (let v = 0; v < count; v++) {
      const x = pos.getX(v), y = pos.getY(v), z = pos.getZ(v);
      const ny = nor.getY(v);
      if (Math.abs(ny) > 0.5) { // roof / underside: roof tone, sample plain wall (no windows)
        colors.set([roof.r, roof.g, roof.b], v * 3);
        uv[v * 2] = 0.02; uv[v * 2 + 1] = 0.02;
      } else { // wall: window grid by floor
        // Fake ambient occlusion: darken the façade toward street level (grime +
        // contact shadow) so buildings feel grounded instead of flat-lit boxes.
        const ao = 0.66 + Math.min(1, y / 6) * 0.34; // 0.66 at base → 1.0 by ~6 m
        colors.set([wall.r * ao, wall.g * ao, wall.b * ao], v * 3);
        const horiz = Math.abs(nor.getX(v)) > Math.abs(nor.getZ(v)) ? z : x;
        uv[v * 2] = horiz / winTile + phaseX; uv[v * 2 + 1] = y / winTile + phaseY;
      }
    }
    g.setAttribute("color", new THREE.BufferAttribute(colors, 3));
    g.setAttribute("uv", new THREE.BufferAttribute(uv, 2));
    geoms.push(g);
    // short residential/commercial footprints get a peaked roof so the skyline
    // stops reading as a field of flat boxes (heroes keep their modeled look).
    if (!isHero && b.height < PITCH_MAX_H) {
      const rg = roofGeometry(b.footprint, b.height, roof);
      if (rg) geoms.push(rg);
    }
  });
  return buckets.map((geoms) => (geoms.length ? mergeGeometries(geoms, false) : null));
}

function Tile({ buildings, colliders }: { buildings: Building[]; colliders: boolean }) {
  const geoms = useMemo(() => tileGeometry(buildings), [buildings]);
  const maps = useMemo(() => Array.from({ length: FACADE_VARIANTS }, (_, v) => makeFacadeMaps(v)), []);
  const nrm = useMemo(() => makeNoiseNormal(), []);
  const nrmScale = useMemo(() => new THREE.Vector2(0.35, 0.35), []);
  const mats = useRef<(THREE.MeshStandardMaterial | null)[]>([]);
  // Windows only light at dusk/night. A plain (1 - dayT) ramp left them glowing
  // orange through the day; gate it to the low end so daytime glass reads dark.
  // One material per façade variant, all driven from the same dusk ramp.
  useFrame(() => {
    const ei = (1 - THREE.MathUtils.smoothstep(shared.dayT, 0, 0.3)) * 1.1;
    for (const m of mats.current) if (m) m.emissiveIntensity = ei;
  });

  // Rooftop clutter for skyline depth: a primary unit sized by building class
  // (low AC box on short blocks, water tank on mid-rise, stair-penthouse on tall)
  // plus an occasional offset vent/chimney — varied per building so the roofline
  // reads as a real skyline, not a field of identical boxes.
  const roofs = useMemo(() => {
    const out: { x: number; y: number; z: number; sx: number; sy: number; sz: number }[] = [];
    let i = 0;
    for (const b of buildings) {
      if (b.height < PITCH_MAX_H || b.height > 45) continue; // only flat-roofed buildings
      let x = 0, n = 0; for (const p of b.footprint) { x += p[0]; n += p[1]; }
      const k = b.footprint.length;
      out.push([x / k, b.height, -(n / k)]);
      if (out.length > 90) break;
    }
    return out;
  }, [buildings]);
  const roofRef = useRef<THREE.InstancedMesh>(null);
  useLayoutEffect(() => {
    const m = roofRef.current;
    if (!m) return;
    for (let i = 0; i < roofs.length; i++) {
      const r = roofs[i];
      _rs.set(r.sx, r.sy, r.sz);
      _rp.set(r.x, r.y + r.sy / 2, r.z); // sit on the roof
      _rm.compose(_rp, _rq, _rs);
      m.setMatrixAt(i, _rm);
      m.setColorAt(i, _rc.set(ROOF_UNIT[i % ROOF_UNIT.length]));
    }
    m.count = roofs.length;
    m.instanceMatrix.needsUpdate = true;
    if (m.instanceColor) m.instanceColor.needsUpdate = true;
  }, [roofs]);

  if (!geoms.some(Boolean)) return null;
  const meshes = geoms.map((g, v) =>
    g ? (
      <mesh key={v} geometry={g} castShadow={colliders} receiveShadow>
        <meshStandardMaterial
          ref={(m) => { mats.current[v] = m as THREE.MeshStandardMaterial | null; }}
          vertexColors map={maps[v].albedo} emissiveMap={maps[v].emissive}
          normalMap={nrm} normalScale={nrmScale}
          emissive={WINDOW_GLOW} emissiveIntensity={0} roughness={0.82} metalness={0.04}
        />
      </mesh>
    ) : null,
  );
  return (
    <group>
      {colliders ? <RigidBody type="fixed" colliders="trimesh">{meshes}</RigidBody> : <>{meshes}</>}
      <instancedMesh ref={roofRef} args={[undefined, undefined, Math.max(1, roofs.length)]} castShadow>
        <boxGeometry args={[1, 1, 1]} />
        <meshStandardMaterial color="#ffffff" roughness={0.9} />
      </instancedMesh>
    </group>
  );
}
const _rm = new THREE.Matrix4();
const _rq = new THREE.Quaternion();
const _rs = new THREE.Vector3();
const _rp = new THREE.Vector3();
const _rc = new THREE.Color();
const ROOF_UNIT = ["#55585e", "#6a6258", "#4a4e54", "#736a5e", "#5e5a52", "#484c50"]; // varied HVAC/tank tones

export function StreamingBuildings({ fallback, center }: { fallback: Building[]; center: [number, number] }) {
  const [manifest, setManifest] = useState<Manifest | null>(null);
  const [failed, setFailed] = useState(false);
  const [active, setActive] = useState<{ key: string; collide: boolean }[]>([]);
  const cache = useRef<Map<string, Building[]>>(new Map());
  const keySet = useRef<Set<string>>(new Set());
  const sig = useRef("");
  const acc = useRef(0);

  useEffect(() => {
    fetch("tiles/manifest.json")
      .then((r) => { if (!r.ok) throw new Error("no manifest"); return r.json(); })
      .then((m: Manifest) => { keySet.current = new Set(m.keys); setManifest(m); })
      .catch(() => setFailed(true));
  }, []);

  useFrame((_, dt) => {
    const m = manifest;
    if (!m) return;
    acc.current += dt;
    if (acc.current < 0.4) return;
    acc.current = 0;

    const body = shared.car && shared.player ? (shared.player.isEnabled() ? shared.player : shared.car) : (shared.player ?? shared.car);
    const t = body?.translation();
    const px = t?.x ?? 0, pn = -(t?.z ?? 0); // north = -z
    const gx = Math.floor(px / m.tile), gn = Math.floor(pn / m.tile);

    const want: { key: string; collide: boolean }[] = [];
    for (let dx = -VIEW_R; dx <= VIEW_R; dx++) {
      for (let dn = -VIEW_R; dn <= VIEW_R; dn++) {
        const key = `${gx + dx}_${gn + dn}`;
        if (!keySet.current.has(key)) continue;
        want.push({ key, collide: Math.abs(dx) <= COLLIDE_R && Math.abs(dn) <= COLLIDE_R });
      }
    }
    const s = want.map((w) => w.key + (w.collide ? "*" : "")).sort().join(",");
    if (s === sig.current) return;
    sig.current = s;

    // fetch any tiles we don't have yet, then publish the active set
    const missing = want.filter((w) => !cache.current.has(w.key));
    if (missing.length === 0) { setActive(want); return; }
    Promise.all(
      missing.map((w) =>
        fetch(`tiles/b_${w.key}.json`).then((r) => r.json()).then((b: Building[]) => cache.current.set(w.key, b)).catch(() => {}),
      ),
    ).then(() => setActive(want));
  });

  if (failed) return <Buildings buildings={fallback} center={center} />;

  return (
    <group>
      {active.map(({ key, collide }) => {
        const b = cache.current.get(key);
        return b ? <Tile key={key} buildings={b} colliders={collide} /> : null;
      })}
    </group>
  );
}
