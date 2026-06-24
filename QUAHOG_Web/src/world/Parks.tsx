import { useMemo } from "react";
import * as THREE from "three";
import { makeGroundTexture } from "./textures";

// Real OSM green spaces (parks, gardens, grass, ball fields) baked to
// public/parks-newbedford.json (slice metres). Rendered as flat green patches
// just above the ground so the city has real lawns/parks instead of bare ground.
// Coordinates are [east, north]; world x = east, z = -north.

const PARK_Y = 0.06;

export function Parks({ polys }: { polys?: [number, number][][] }) {
  const tex = useMemo(() => { const t = makeGroundTexture(); t.repeat.set(0.05, 0.05); return t; }, []);

  const geometry = useMemo(() => {
    if (!polys || polys.length === 0) return null;
    const geoms: THREE.BufferGeometry[] = [];
    for (const ring of polys) {
      if (ring.length < 3) continue;
      const shape = new THREE.Shape(ring.map(([e, n]) => new THREE.Vector2(e, n)));
      const g = new THREE.ShapeGeometry(shape); // earcut
      g.rotateX(-Math.PI / 2); // (e,n) -> (x,-z)
      geoms.push(g);
    }
    if (geoms.length === 0) return null;
    let count = 0;
    geoms.forEach((g) => (count += g.attributes.position.count));
    const pos = new Float32Array(count * 3);
    let o = 0;
    for (const g of geoms) {
      const p = g.attributes.position.array as Float32Array;
      pos.set(p, o); o += p.length;
    }
    const merged = new THREE.BufferGeometry();
    merged.setAttribute("position", new THREE.BufferAttribute(pos, 3));
    const uv = new Float32Array(count * 2);
    for (let i = 0; i < count; i++) { uv[i * 2] = pos[i * 3]; uv[i * 2 + 1] = pos[i * 3 + 2]; }
    merged.setAttribute("uv", new THREE.BufferAttribute(uv, 2));
    merged.computeVertexNormals();
    return merged;
  }, [polys]);

  if (!geometry) return null;
  return (
    <mesh geometry={geometry} position={[0, PARK_Y, 0]} receiveShadow>
      <meshStandardMaterial map={tex} color="#4f6e3a" roughness={1} polygonOffset polygonOffsetFactor={-1} />
    </mesh>
  );
}
