import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { mergeGeometries } from "three/examples/jsm/utils/BufferGeometryUtils.js";
import { RigidBody } from "@react-three/rapier";
import { shared } from "../shared";
import { Buildings } from "./Buildings";
import { makeFacadeMaps, makeNoiseNormal } from "./textures";
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
    // short residential/commercial footprints get a peaked roof so the skyline
    // stops reading as a field of flat boxes (heroes keep their modeled look).
    if (!isHero && b.height < PITCH_MAX_H) {
      const rg = roofGeometry(b.footprint, b.height, roof);
      if (rg) geoms.push(rg);
    }
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

  // rooftop clutter (water tanks / AC units) on mid-rise buildings for skyline depth
  const roofs = useMemo(() => {
    const out: [number, number, number][] = [];
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
    for (let i = 0; i < roofs.length; i++) { _rm.makeTranslation(roofs[i][0], roofs[i][1] + 0.5, roofs[i][2]); m.setMatrixAt(i, _rm); }
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
