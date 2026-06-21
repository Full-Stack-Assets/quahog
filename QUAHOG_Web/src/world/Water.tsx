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

  // cache base vertex positions so we can ripple them each frame (§6 waves)
  const base = useMemo(() => (geometry ? (geometry.attributes.position.array as Float32Array).slice() : null), [geometry]);

  const matRef = useRef<THREE.MeshStandardMaterial>(null);
  const meshRef = useRef<THREE.Mesh>(null);
  useFrame((state, dt) => {
    if (matRef.current?.normalMap) {
      matRef.current.normalMap.offset.x += dt * 0.012;
      matRef.current.normalMap.offset.y += dt * 0.006;
    }
    // gentle swell: displace Y by crossing sine waves over world x/z
    if (base && meshRef.current) {
      const t = state.clock.elapsedTime;
      const pos = meshRef.current.geometry.attributes.position as THREE.BufferAttribute;
      const arr = pos.array as Float32Array;
      for (let i = 0; i < arr.length; i += 3) {
        const x = base[i], z = base[i + 2];
        arr[i + 1] = base[i + 1] + Math.sin(x * 0.08 + t * 1.1) * 0.18 + Math.cos(z * 0.06 - t * 0.8) * 0.14;
      }
      pos.needsUpdate = true;
    }
  });

  if (!geometry) return null;
  return (
    <mesh ref={meshRef} geometry={geometry} position={[0, WATER_Y, 0]} receiveShadow>
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
