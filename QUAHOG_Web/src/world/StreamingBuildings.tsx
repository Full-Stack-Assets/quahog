import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { mergeGeometries } from "three/examples/jsm/utils/BufferGeometryUtils.js";
import { RigidBody } from "@react-three/rapier";
import { shared } from "../shared";
import { Buildings } from "./Buildings";
import { makeFacadeMaps, makeNoiseNormal, FACADE_GRID } from "./textures";
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
const WIN_TILE = FLOOR * FACADE_GRID; // metres spanned by one façade texture tile

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
  const capH = H < 14 ? 0.5 + hash * 0.4
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
    const hash = (i * 0.6180339887) % 1;
    const wall = new THREE.Color(isHero ? HERO_COLOR : pal[i % pal.length]);
    if (!isHero) wall.multiplyScalar(0.82 + hash * 0.34);
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
        uv[v * 2] = 0.02; uv[v * 2 + 1] = 0.02;
      } else { // wall: window grid by floor
        // Fake ambient occlusion: darken the façade toward street level (grime +
        // contact shadow) so buildings feel grounded instead of flat-lit boxes.
        const ao = 0.66 + Math.min(1, y / 6) * 0.34; // 0.66 at base → 1.0 by ~6 m
        colors.set([wall.r * ao, wall.g * ao, wall.b * ao], v * 3);
        const horiz = Math.abs(nor.getX(v)) > Math.abs(nor.getZ(v)) ? z : x;
        uv[v * 2] = horiz / WIN_TILE; uv[v * 2 + 1] = y / WIN_TILE;
      }
    }
    g.setAttribute("color", new THREE.BufferAttribute(colors, 3));
    g.setAttribute("uv", new THREE.BufferAttribute(uv, 2));
    geoms.push(g);
    const cap = parapetGeometry(b, wall, hash);
    if (cap) geoms.push(cap);
  });
  return geoms.length ? mergeGeometries(geoms, false) : null;
}

function Tile({ buildings, colliders }: { buildings: Building[]; colliders: boolean }) {
  const geom = useMemo(() => tileGeometry(buildings), [buildings]);
  const maps = useMemo(() => makeFacadeMaps(), []);
  const nrm = useMemo(() => makeNoiseNormal(), []);
  const nrmScale = useMemo(() => new THREE.Vector2(0.35, 0.35), []);
  const mat = useRef<THREE.MeshStandardMaterial>(null);
  useFrame(() => { if (mat.current) mat.current.emissiveIntensity = (1 - shared.dayT) * 1.0; });

  // Rooftop clutter for skyline depth: a primary unit sized by building class
  // (low AC box on short blocks, water tank on mid-rise, stair-penthouse on tall)
  // plus an occasional offset vent/chimney — varied per building so the roofline
  // reads as a real skyline, not a field of identical boxes.
  const roofs = useMemo(() => {
    const out: { x: number; y: number; z: number; sx: number; sy: number; sz: number }[] = [];
    let i = 0;
    for (const b of buildings) {
      if (b.height < 7 || b.height > 60) { i++; continue; }
      let cx = 0, cn = 0; for (const p of b.footprint) { cx += p[0]; cn += p[1]; }
      const k = b.footprint.length || 1; cx /= k; cn /= k; const cz = -cn;
      const h = (i * 0.6180339887) % 1;
      const h2 = (i * 0.3819660113) % 1;

      if (b.height >= 24)      out.push({ x: cx, y: b.height, z: cz, sx: 2.6 + h * 1.6, sy: 2.4 + h2 * 2.0, sz: 2.6 + h2 * 1.6 }); // penthouse
      else if (b.height >= 12) out.push({ x: cx, y: b.height, z: cz, sx: 1.6 + h * 0.9, sy: 1.4 + h2 * 1.3, sz: 1.6 + h2 * 0.9 }); // water tank
      else                     out.push({ x: cx, y: b.height, z: cz, sx: 1.4 + h * 0.7, sy: 0.55 + h2 * 0.4, sz: 1.4 + h * 0.7 }); // AC unit

      // secondary prop offset toward a footprint corner (vent stack / chimney)
      if (h2 > 0.45 && k >= 1) {
        const vtx = b.footprint[i % k];
        const px = cx + (vtx[0] - cx) * 0.55, pn = cn + (vtx[1] - cn) * 0.55;
        const tall = b.height < 12; // chimney on houses, squat vent elsewhere
        out.push({ x: px, y: b.height, z: -pn, sx: 0.6 + h * 0.4, sy: tall ? 1.6 + h * 1.0 : 0.7, sz: 0.6 + h2 * 0.4 });
      }
      if (out.length > 140) break;
      i++;
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
    }
    m.count = roofs.length;
    m.instanceMatrix.needsUpdate = true;
  }, [roofs]);

  if (!geom) return null;
  const mesh = (
    <mesh geometry={geom} castShadow={colliders} receiveShadow>
      <meshStandardMaterial
        ref={mat} vertexColors map={maps.albedo} emissiveMap={maps.emissive}
        normalMap={nrm} normalScale={nrmScale}
        emissive={WINDOW_GLOW} emissiveIntensity={0} roughness={0.82} metalness={0.04}
      />
    </mesh>
  );
  return (
    <group>
      {colliders ? <RigidBody type="fixed" colliders="trimesh">{mesh}</RigidBody> : mesh}
      <instancedMesh ref={roofRef} args={[undefined, undefined, Math.max(1, roofs.length)]} castShadow>
        <boxGeometry args={[1, 1, 1]} />
        <meshStandardMaterial color="#55585e" roughness={0.9} />
      </instancedMesh>
    </group>
  );
}
const _rm = new THREE.Matrix4();
const _rq = new THREE.Quaternion();
const _rs = new THREE.Vector3();
const _rp = new THREE.Vector3();

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
