import { useMemo, useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { makeWaterNormal } from "./textures";

// The real harbor, triangulated from the OSM water polygon(s), as an animated
// ocean surface. Sits just above the opaque ground plane so it stays visible.
const WATER_Y = 0.12;

export function Water({ polys }: { polys: [number, number][][] }) {
  const normalMap = useMemo(() => {
    const t = makeWaterNormal();
    t.repeat.set(60, 60);
    return t;
  }, []);

  const geometry = useMemo(() => {
    const geoms: THREE.BufferGeometry[] = [];
    for (const ring of polys) {
      if (ring.length < 3) continue;
      const shape = new THREE.Shape(ring.map(([e, n]) => new THREE.Vector2(e, n)));
      const g = new THREE.ShapeGeometry(shape); // earcut, handles concave
      g.rotateX(-Math.PI / 2); // (e,n) plane -> (x, -z) ground plane
      geoms.push(g);
    }
    if (geoms.length === 0) return null;
    // merge into one geometry (simple position concat)
    let count = 0;
    geoms.forEach((g) => (count += g.attributes.position.count));
    const pos = new Float32Array(count * 3);
    let o = 0;
    for (const g of geoms) {
      const p = g.attributes.position.array as ArrayLike<number>;
      pos.set(p as Float32Array, o);
      o += p.length;
    }
    const merged = new THREE.BufferGeometry();
    merged.setAttribute("position", new THREE.BufferAttribute(pos, 3));
    // planar UVs in world meters for the normal map
    const uv = new Float32Array(count * 2);
    for (let i = 0; i < count; i++) {
      uv[i * 2] = pos[i * 3] / 40;
      uv[i * 2 + 1] = pos[i * 3 + 2] / 40;
    }
    merged.setAttribute("uv", new THREE.BufferAttribute(uv, 2));
    merged.computeVertexNormals();
    return merged;
  }, [polys]);

  const matRef = useRef<THREE.MeshStandardMaterial>(null);
  useFrame((_, dt) => {
    if (matRef.current?.normalMap) {
      matRef.current.normalMap.offset.x += dt * 0.012;
      matRef.current.normalMap.offset.y += dt * 0.006;
    }
  });

  if (!geometry) return null;
  return (
    <mesh geometry={geometry} position={[0, WATER_Y, 0]} receiveShadow>
      <meshStandardMaterial
        ref={matRef}
        color="#16384a"
        roughness={0.18}
        metalness={0.55}
        normalMap={normalMap}
        normalScale={new THREE.Vector2(0.5, 0.5)}
        transparent
        opacity={0.94}
      />
    </mesh>
  );
}
