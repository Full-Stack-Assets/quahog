import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { mergeGeometries } from "three/examples/jsm/utils/BufferGeometryUtils.js";
import { RigidBody } from "@react-three/rapier";
import { shared } from "../shared";
import { Buildings } from "./Buildings";
import { makeFacadeMaps } from "./textures";
import type { Building } from "../slice";

// Multi-tile building streamer (Step 19). Loads building tiles (public/tiles/
// b_<gx>_<gn>.json) within VIEW_R of the player and drops them when far, so
// memory/draw stays bounded as the map grows to the whole South Coast. The
// player's own tile + neighbours (COLLIDE_R) get a static collider. Falls back
// to the monolithic <Buildings> if the manifest isn't present.

const VIEW_R = 3;     // tiles loaded around the player (each TILE metres)
const COLLIDE_R = 1;  // tiles that get physics colliders
const WINDOW_GLOW = new THREE.Color("#ffcf8a");
const WARM = ["#8a5a48", "#6e4a3e", "#a8987e", "#b8b0a0", "#c2bcae"]; // brick/clapboard (short)
const GREY = ["#7c7e88", "#9aa0a6", "#8f8c86"];                       // granite/concrete (tall)
const HERO_COLOR = "#caa24a";
const HERO = new Set(["Seamen's Bethel", "New Bedford Whaling Museum", "Mariner's Home", "Double Bank Building", "Rodman Candleworks"]);
const FLOOR = 3.2; // metres per window row

interface Manifest { tile: number; keys: string[] }

function tileGeometry(buildings: Building[]): THREE.BufferGeometry | null {
  const geoms: THREE.BufferGeometry[] = [];
  buildings.forEach((b, i) => {
    const shape = new THREE.Shape();
    b.footprint.forEach(([e, n], k) => (k === 0 ? shape.moveTo(e, n) : shape.lineTo(e, n)));
    const g = new THREE.ExtrudeGeometry(shape, { depth: b.height, bevelEnabled: false });
    g.rotateX(-Math.PI / 2);
    g.computeVertexNormals();
    // colour by use/height (style guide): short = brick/clapboard, tall = granite
    const pal = b.height >= 14 ? GREY : WARM;
    const col = new THREE.Color(b.name && HERO.has(b.name) ? HERO_COLOR : pal[i % pal.length]);
    const pos = g.attributes.position, nor = g.attributes.normal;
    const count = pos.count;
    const colors = new Float32Array(count * 3);
    const uv = new Float32Array(count * 2);
    for (let v = 0; v < count; v++) {
      colors.set([col.r, col.g, col.b], v * 3);
      const x = pos.getX(v), y = pos.getY(v), z = pos.getZ(v);
      const ny = nor.getY(v);
      if (Math.abs(ny) > 0.5) { uv[v * 2] = x / 6; uv[v * 2 + 1] = z / 6; }            // roof
      else { // wall: window grid by floor
        const horiz = Math.abs(nor.getX(v)) > Math.abs(nor.getZ(v)) ? z : x;
        uv[v * 2] = horiz / FLOOR; uv[v * 2 + 1] = y / FLOOR;
      }
    }
    g.setAttribute("color", new THREE.BufferAttribute(colors, 3));
    g.setAttribute("uv", new THREE.BufferAttribute(uv, 2));
    geoms.push(g);
  });
  return geoms.length ? mergeGeometries(geoms, false) : null;
}

function Tile({ buildings, colliders }: { buildings: Building[]; colliders: boolean }) {
  const geom = useMemo(() => tileGeometry(buildings), [buildings]);
  const maps = useMemo(() => makeFacadeMaps(), []);
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
        emissive={WINDOW_GLOW} emissiveIntensity={0} roughness={0.85}
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
