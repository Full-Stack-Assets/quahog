import { useMemo, useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { makeAsphaltTexture, makeCobbleTexture } from "./textures";
import { useGame } from "../store";
import type { Road } from "../slice";

// Road classes → surface material. Highways get lane markings; vehicular streets
// get plain asphalt; footways/pedestrian/steps get historic cobblestone.
const HIGHWAY = new Set([
  "motorway", "trunk", "primary",
  "motorway_link", "trunk_link", "primary_link",
]);
const COBBLE = new Set(["footway", "path", "pedestrian", "steps", "cycleway", "track"]);
const TILE = 8; // metres of road per texture repeat along length
const BRIDGE_Y = 5.5; // deck height for bridges (Coggeshall St, JFK Hwy, the Acushnet crossings)

// Builds one merged ribbon geometry (with UVs). `uScale` controls cross-width
// texture repeats (cobble repeats across the width; asphalt spans 0..1 for lanes).
function buildRibbon(roads: Road[], y: number, uScale: number): THREE.BufferGeometry | null {
  const pos: number[] = [];
  const uv: number[] = [];
  const idx: number[] = [];
  let v = 0;
  for (const r of roads) {
    const half = r.width / 2;
    const u = uScale === 0 ? 1 : r.width / uScale; // tiles across the width
    let len = 0;
    for (let i = 0; i < r.points.length - 1; i++) {
      const [ax, an] = r.points[i];
      const [bx, bn] = r.points[i + 1];
      const x1 = ax, z1 = -an, x2 = bx, z2 = -bn;
      const dx = x2 - x1, dz = z2 - z1;
      const segLen = Math.hypot(dx, dz);
      if (segLen < 1e-4) continue;
      const nx = (-dz / segLen) * half;
      const nz = (dx / segLen) * half;
      const v0 = len / TILE;
      const v1 = (len + segLen) / TILE;
      pos.push(
        x1 + nx, y, z1 + nz,
        x2 + nx, y, z2 + nz,
        x2 - nx, y, z2 - nz,
        x1 - nx, y, z1 - nz,
      );
      uv.push(0, v0, 0, v1, u, v1, u, v0);
      idx.push(v, v + 1, v + 2, v, v + 2, v + 3);
      v += 4;
      len += segLen;
    }
  }
  if (pos.length === 0) return null;
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2));
  g.setIndex(idx);
  g.computeVertexNormals();
  return g;
}

export function Roads({ roads }: { roads: Road[] }) {
  const surfaceTex = useMemo(() => makeAsphaltTexture(false), []);
  const highwayTex = useMemo(() => makeAsphaltTexture(true), []);
  const cobbleTex = useMemo(() => {
    const t = makeCobbleTexture();
    t.repeat.set(1, 0.5); // bigger cobbles along length
    return t;
  }, []);

  const { surface, highway, cobble, bridge, pylons } = useMemo(() => {
    const br = roads.filter((r) => r.bridge);
    const land = roads.filter((r) => !r.bridge);
    const hw = land.filter((r) => HIGHWAY.has(r.highway));
    const cb = land.filter((r) => COBBLE.has(r.highway));
    const sf = land.filter((r) => !HIGHWAY.has(r.highway) && !COBBLE.has(r.highway));
    // pylons: drop a pier from the deck to the water/ground every ~24 m
    const py: [number, number][] = [];
    for (const r of br) {
      for (let i = 0; i < r.points.length - 1 && py.length <= 160; i++) {
        const [ax, an] = r.points[i], [bx, bn] = r.points[i + 1];
        const seg = Math.hypot(bx - ax, bn - an);
        for (let d = 0; d < seg && py.length <= 160; d += 24) {
          const t = seg ? d / seg : 0;
          py.push([ax + (bx - ax) * t, -(an + (bn - an) * t)]);
        }
      }
    }
    return {
      surface: buildRibbon(sf, 0.06, 0),
      highway: buildRibbon(hw, 0.08, 0),
      cobble: buildRibbon(cb, 0.05, 1.2), // setts tile across width every ~1.2m
      bridge: buildRibbon(br, BRIDGE_Y, 0),
      pylons: py,
    };
  }, [roads]);

  // wet-road sheen: drop roughness + darken when it's raining (§5)
  const mats = useRef<(THREE.MeshStandardMaterial | null)[]>([]);
  const baseRough = [0.95, 0.9, 0.82];
  useFrame(() => {
    const wet = useGame.getState().weather === "rain" ? 1 : 0;
    mats.current.forEach((m, i) => {
      if (!m) return;
      m.roughness = baseRough[i] - wet * 0.55;
      m.metalness = wet * 0.5;
    });
  });

  return (
    <group>
      {cobble && (
        <mesh geometry={cobble} receiveShadow>
          <meshStandardMaterial ref={(m) => (mats.current[0] = m)} map={cobbleTex} color="#8a8580" roughness={0.95} />
        </mesh>
      )}
      {surface && (
        <mesh geometry={surface} receiveShadow>
          <meshStandardMaterial ref={(m) => (mats.current[1] = m)} map={surfaceTex} color="#5a5c66" roughness={0.9} />
        </mesh>
      )}
      {highway && (
        <mesh geometry={highway} receiveShadow>
          <meshStandardMaterial ref={(m) => (mats.current[2] = m)} map={highwayTex} color="#6a6c76" roughness={0.82} />
        </mesh>
      )}
      {/* elevated bridge decks + piers */}
      {bridge && (
        <mesh geometry={bridge} castShadow receiveShadow>
          <meshStandardMaterial map={highwayTex} color="#7a7c86" roughness={0.8} />
        </mesh>
      )}
      {pylons.map(([x, z], i) => (
        <mesh key={i} position={[x, BRIDGE_Y / 2, z]} castShadow>
          <boxGeometry args={[1.2, BRIDGE_Y, 1.2]} />
          <meshStandardMaterial color="#8a8276" roughness={0.9} />
        </mesh>
      ))}
    </group>
  );
}
