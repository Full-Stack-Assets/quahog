import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { mergeGeometries } from "three/examples/jsm/utils/BufferGeometryUtils.js";
import { RigidBody } from "@react-three/rapier";
import { shared } from "../shared";
import { Buildings } from "./Buildings";
import { makeFacadeMaps, makeFacadeNormal, makeFacadeRoughness } from "./textures";
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
const HERO_COLOR = "#caa24a";
const HERO = new Set(["Seamen's Bethel", "New Bedford Whaling Museum", "Mariner's Home", "Double Bank Building", "Rodman Candleworks"]);
const FLOOR = 3.2; // metres per window row

interface Manifest { tile: number; keys: string[] }

// A simple hip roof: triangles from each footprint edge up to a centre apex, so
// short residential buildings read as pitched houses (triple-deckers, capes)
// instead of flat-topped boxes. Winding is corrected so every face points up.
function hipRoof(b: Building, roofH: number, col: THREE.Color): THREE.BufferGeometry | null {
  const fp = b.footprint;
  if (fp.length < 3) return null;
  let cx = 0, cn = 0;
  for (const [e, n] of fp) { cx += e; cn += n; }
  cx /= fp.length; cn /= fp.length;
  const apex: [number, number, number] = [cx, b.height + roofH, -cn];
  const EAVE = 1.07; // base ring pushed out from the centroid → roof overhangs walls
  const pos: number[] = [], colr: number[] = [], uv: number[] = [];
  const push = (x: number, y: number, z: number) => { pos.push(x, y, z); colr.push(col.r, col.g, col.b); uv.push(0.04, 0.04); };
  for (let i = 0; i < fp.length; i++) {
    const [e0, n0] = fp[i], [e1, n1] = fp[(i + 1) % fp.length];
    // overhang: expand each eave vertex outward from the footprint centroid
    const a: [number, number, number] = [cx + (e0 - cx) * EAVE, b.height, -(cn + (n0 - cn) * EAVE)];
    const c: [number, number, number] = [cx + (e1 - cx) * EAVE, b.height, -(cn + (n1 - cn) * EAVE)];
    // face normal (a→c→apex); flip if it points down so roofs catch the sun
    const ux = c[0] - a[0], uy = c[1] - a[1], uz = c[2] - a[2];
    const vx = apex[0] - a[0], vy = apex[1] - a[1], vz = apex[2] - a[2];
    const ny = uz * vx - ux * vz;
    if (ny >= 0) { push(...a); push(...c); push(...apex); }
    else { push(...a); push(...apex); push(...c); }
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute("color", new THREE.Float32BufferAttribute(colr, 3));
  g.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2));
  g.computeVertexNormals();
  return g;
}

// A parapet: a short wall band standing just above the roof line, around the
// footprint perimeter, so flat-roofed commercial/mill/downtown blocks read with
// a real coping edge instead of a bare extruded-box top. Outward winding is
// derived from each edge vs. the centroid (deterministic, no guesswork).
function parapet(b: Building, h: number, col: THREE.Color): THREE.BufferGeometry | null {
  const fp = b.footprint;
  if (fp.length < 3) return null;
  let cx = 0, cn = 0;
  for (const [e, n] of fp) { cx += e; cn += n; }
  cx /= fp.length; cn /= fp.length;
  const cz = -cn; // centroid in world z
  const y0 = b.height, y1 = b.height + h;
  const pos: number[] = [], colr: number[] = [], uv: number[] = [];
  const push = (x: number, y: number, z: number) => { pos.push(x, y, z); colr.push(col.r, col.g, col.b); uv.push(0.04, 0.04); };
  for (let i = 0; i < fp.length; i++) {
    const [e0, n0] = fp[i], [e1, n1] = fp[(i + 1) % fp.length];
    const ax = e0, az = -n0, bx = e1, bz = -n1;
    const ex = bx - ax, ez = bz - az;
    if (Math.hypot(ex, ez) < 1e-4) continue;
    const mx = (ax + bx) / 2 - cx, mz = (az + bz) / 2 - cz; // edge midpoint → outward
    const outward = (-ez) * mx + ex * mz >= 0; // sign of the (A0,B0,B1) normal
    const A0: [number, number, number] = [ax, y0, az], B0: [number, number, number] = [bx, y0, bz];
    const B1: [number, number, number] = [bx, y1, bz], A1: [number, number, number] = [ax, y1, az];
    if (outward) { push(...A0); push(...B0); push(...B1); push(...A0); push(...B1); push(...A1); }
    else { push(...A0); push(...B1); push(...B0); push(...A0); push(...A1); push(...B1); }
  }
  if (!pos.length) return null;
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute("color", new THREE.Float32BufferAttribute(colr, 3));
  g.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2));
  g.computeVertexNormals();
  return g;
}

// A plinth / base course: a short stone band hugging the foot of the building and
// projecting slightly proud of the wall, so blocks read with a real granite base
// at street level instead of meeting the pavement as a bare extruded box. Same
// deterministic outward-winding approach as the parapet.
function plinth(b: Building, h: number, col: THREE.Color): THREE.BufferGeometry | null {
  const fp = b.footprint;
  if (fp.length < 3) return null;
  let cx = 0, cn = 0;
  for (const [e, n] of fp) { cx += e; cn += n; }
  cx /= fp.length; cn /= fp.length;
  const cz = -cn;
  const PUSH = 0.07; // metres the base course projects beyond the wall face
  const pos: number[] = [], colr: number[] = [], uv: number[] = [];
  const push = (x: number, y: number, z: number) => { pos.push(x, y, z); colr.push(col.r, col.g, col.b); uv.push(0.04, 0.04); };
  for (let i = 0; i < fp.length; i++) {
    const [e0, n0] = fp[i], [e1, n1] = fp[(i + 1) % fp.length];
    const ax = e0, az = -n0, bx = e1, bz = -n1;
    const ex = bx - ax, ez = bz - az;
    const el = Math.hypot(ex, ez);
    if (el < 1e-4) continue;
    // outward unit normal (perp to the edge, oriented away from the centroid)
    let nx = -ez / el, nz = ex / el;
    const mx = (ax + bx) / 2 - cx, mz = (az + bz) / 2 - cz;
    if (nx * mx + nz * mz < 0) { nx = -nx; nz = -nz; }
    const ox = nx * PUSH, oz = nz * PUSH;
    const Ax = ax + ox, Az = az + oz, Bx = bx + ox, Bz = bz + oz;
    const A0: [number, number, number] = [Ax, 0, Az], B0: [number, number, number] = [Bx, 0, Bz];
    const B1: [number, number, number] = [Bx, h, Bz], A1: [number, number, number] = [Ax, h, Az];
    if ((-ez) * nx + ex * nz >= 0) { push(...A0); push(...B0); push(...B1); push(...A0); push(...B1); push(...A1); }
    else { push(...A0); push(...B1); push(...B0); push(...A0); push(...A1); push(...B1); }
  }
  if (!pos.length) return null;
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute("color", new THREE.Float32BufferAttribute(colr, 3));
  g.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2));
  g.computeVertexNormals();
  return g;
}

// A brick chimney stack rising through the roof of a house — the recognizable
// New Bedford triple-decker / Cape silhouette cue. Sides are wound outward from
// the stack centre (same deterministic approach as the parapet/plinth).
function chimney(b: Building, idx: number, col: THREE.Color): THREE.BufferGeometry | null {
  const fp = b.footprint;
  if (fp.length < 3) return null;
  let cx = 0, cn = 0;
  for (const [e, n] of fp) { cx += e; cn += n; }
  cx /= fp.length; cn /= fp.length;
  // sit it partway from the centroid toward a footprint vertex, so it lands on
  // the roof slope rather than dead-centre on the apex
  const vtx = fp[idx % fp.length];
  const x0 = cx + (vtx[0] - cx) * 0.5;
  const z0 = -(cn + (vtx[1] - cn) * 0.5);
  const s = 0.45;
  const y0 = b.height - 0.3;
  const y1 = b.height + 1.8 + ((idx * 0.6180339887) % 1) * 0.9;
  const corner: [number, number][] = [[x0 - s, z0 - s], [x0 + s, z0 - s], [x0 + s, z0 + s], [x0 - s, z0 + s]];
  const pos: number[] = [], colr: number[] = [], uv: number[] = [];
  const push = (x: number, y: number, z: number) => { pos.push(x, y, z); colr.push(col.r, col.g, col.b); uv.push(0.04, 0.04); };
  for (let i = 0; i < 4; i++) {
    const [ax, az] = corner[i], [bx, bz] = corner[(i + 1) % 4];
    const ex = bx - ax, ez = bz - az;
    let nx = -ez, nz = ex;
    const mx = (ax + bx) / 2 - x0, mz = (az + bz) / 2 - z0;
    if (nx * mx + nz * mz < 0) { nx = -nx; nz = -nz; }
    const A0: [number, number, number] = [ax, y0, az], B0: [number, number, number] = [bx, y0, bz];
    const B1: [number, number, number] = [bx, y1, bz], A1: [number, number, number] = [ax, y1, az];
    if ((-ez) * nx + ex * nz >= 0) { push(...A0); push(...B0); push(...B1); push(...A0); push(...B1); push(...A1); }
    else { push(...A0); push(...B1); push(...B0); push(...A0); push(...A1); push(...B1); }
  }
  // top cap (upward-facing)
  const T = corner.map(([x, z]) => [x, y1, z] as [number, number, number]);
  push(...T[0]); push(...T[2]); push(...T[1]); push(...T[0]); push(...T[3]); push(...T[2]);
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute("color", new THREE.Float32BufferAttribute(colr, 3));
  g.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2));
  g.computeVertexNormals();
  return g;
}

function tileGeometry(buildings: Building[]): THREE.BufferGeometry | null {
  const geoms: THREE.BufferGeometry[] = [];
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
    const wall = new THREE.Color(isHero ? HERO_COLOR : pal[i % pal.length]);
    if (!isHero) wall.multiplyScalar(0.82 + ((i * 0.6180339887) % 1) * 0.34);
    const roof = new THREE.Color(ROOF[i % ROOF.length]);
    const pos = g.attributes.position, nor = g.attributes.normal;
    const count = pos.count;
    const colors = new Float32Array(count * 3);
    const uv = new Float32Array(count * 2);
    for (let v = 0; v < count; v++) {
      const x = pos.getX(v), y = pos.getY(v), z = pos.getZ(v);
      const ny = nor.getY(v);
      if (Math.abs(ny) > 0.5) { // roof / underside: roof tone, sample plain wall (no windows)
        colors.set([roof.r, roof.g, roof.b], v * 3);
        uv[v * 2] = 0.04; uv[v * 2 + 1] = 0.04;
      } else { // wall: window grid by floor
        colors.set([wall.r, wall.g, wall.b], v * 3);
        const horiz = Math.abs(nor.getX(v)) > Math.abs(nor.getZ(v)) ? z : x;
        uv[v * 2] = horiz / FLOOR; uv[v * 2 + 1] = y / FLOOR;
      }
    }
    g.setAttribute("color", new THREE.BufferAttribute(colors, 3));
    g.setAttribute("uv", new THREE.BufferAttribute(uv, 2));
    geoms.push(g);
    // short residential buildings get a pitched hip roof so they don't read as
    // flat-topped boxes; taller commercial/downtown blocks get a parapet coping
    // band instead (both deterministic per-building).
    if (!isHero && b.height < 12) {
      const r = hipRoof(b, 1.5 + ((i * 0.6180339887) % 1) * 1.6, roof);
      if (r) geoms.push(r);
      // most houses get a brick chimney for silhouette variety (deterministic)
      if (b.height >= 5 && i % 3 !== 0) {
        const ch = chimney(b, i, new THREE.Color("#6e4a3e"));
        if (ch) geoms.push(ch);
      }
    } else if (!isHero) {
      // coping tone: the wall colour lightened toward limestone/concrete
      const coping = wall.clone().lerp(new THREE.Color("#cfc9bc"), 0.4);
      const p = parapet(b, 0.7 + ((i * 0.6180339887) % 1) * 0.7, coping);
      if (p) geoms.push(p);
    }
    // granite base course at street level (all real buildings tall enough to have one)
    if (!isHero && b.height >= 3.5) {
      const baseCol = wall.clone().lerp(new THREE.Color("#39362f"), 0.5);
      const pl = plinth(b, Math.min(1.4, b.height * 0.16), baseCol);
      if (pl) geoms.push(pl);
    }
  });
  return geoms.length ? mergeGeometries(geoms, false) : null;
}

function Tile({ buildings, colliders }: { buildings: Building[]; colliders: boolean }) {
  const geom = useMemo(() => tileGeometry(buildings), [buildings]);
  const maps = useMemo(() => makeFacadeMaps(), []);
  const nrm = useMemo(() => makeFacadeNormal(), []); // brick-aligned relief
  const rough = useMemo(() => makeFacadeRoughness(), []); // glossy glass vs matte brick
  const nrmScale = useMemo(() => new THREE.Vector2(0.7, 0.7), []);
  const mat = useRef<THREE.MeshStandardMaterial>(null);
  useFrame(() => { if (mat.current) mat.current.emissiveIntensity = (1 - shared.dayT) * 1.0; });

  // rooftop clutter (water tanks / AC units) on mid-rise buildings for skyline depth
  const roofs = useMemo(() => {
    const out: [number, number, number][] = [];
    for (const b of buildings) {
      if (b.height < 7 || b.height > 45) continue;
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
    for (let i = 0; i < roofs.length; i++) { _rm.makeTranslation(roofs[i][0], roofs[i][1] + 0.5, roofs[i][2]); m.setMatrixAt(i, _rm); }
    m.count = roofs.length;
    m.instanceMatrix.needsUpdate = true;
  }, [roofs]);

  if (!geom) return null;
  const mesh = (
    <mesh geometry={geom} castShadow={colliders} receiveShadow>
      <meshStandardMaterial
        ref={mat} vertexColors map={maps.albedo} emissiveMap={maps.emissive}
        normalMap={nrm} normalScale={nrmScale} roughnessMap={rough}
        emissive={WINDOW_GLOW} emissiveIntensity={0} roughness={1} metalness={0.04} envMapIntensity={1.1}
      />
    </mesh>
  );
  return (
    <group>
      {colliders ? <RigidBody type="fixed" colliders="trimesh">{mesh}</RigidBody> : mesh}
      <instancedMesh ref={roofRef} args={[undefined, undefined, Math.max(1, roofs.length)]} castShadow>
        <boxGeometry args={[1.8, 1, 1.8]} />
        <meshStandardMaterial color="#55585e" roughness={0.9} />
      </instancedMesh>
    </group>
  );
}
const _rm = new THREE.Matrix4();

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
