import { useMemo } from "react";
import * as THREE from "three";
import { makeAsphaltTexture } from "./textures";
import type { Road } from "../slice";

const HIGHWAY = new Set([
  "motorway", "trunk", "primary",
  "motorway_link", "trunk_link", "primary_link",
]);
const TILE = 8; // metres of road per texture repeat (controls lane-dash spacing)

// Builds one merged ribbon geometry (with UVs) for a set of roads.
function buildRibbon(roads: Road[], y: number): THREE.BufferGeometry | null {
  const pos: number[] = [];
  const uv: number[] = [];
  const idx: number[] = [];
  let v = 0;
  for (const r of roads) {
    const half = r.width / 2;
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
      uv.push(0, v0, 0, v1, 1, v1, 1, v0);
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

  const { surface, highway } = useMemo(() => {
    const hw = roads.filter((r) => HIGHWAY.has(r.highway));
    const sf = roads.filter((r) => !HIGHWAY.has(r.highway));
    return {
      surface: buildRibbon(sf, 0.06),
      highway: buildRibbon(hw, 0.08), // sit slightly above surface streets
    };
  }, [roads]);

  return (
    <group>
      {surface && (
        <mesh geometry={surface} receiveShadow>
          <meshStandardMaterial map={surfaceTex} color="#5a5c66" roughness={0.85} />
        </mesh>
      )}
      {highway && (
        <mesh geometry={highway} receiveShadow>
          <meshStandardMaterial map={highwayTex} color="#6a6c76" roughness={0.8} />
        </mesh>
      )}
    </group>
  );
}
