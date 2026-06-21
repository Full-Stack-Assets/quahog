import { useMemo, useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { makeWaterNormal } from "./textures";

// The real harbor, triangulated from the OSM water polygon(s), as an animated
// ocean surface. Sits just above the opaque ground plane so it stays visible.
// Lifted well clear of the region-wide ground plane — at 0.12 it z-fought with
// the ground and vanished in 3D (only the map showed water). 0.45 reads cleanly.
const WATER_Y = 0.45;

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
  // Gerstner-style swell: sum a few directional waves for choppy, believable
  // motion; recompute normals so the IBL reflection rolls with the surface.
  const WAVES = useMemo(() => ([
    { dx: 0.7, dz: 0.7, len: 26, amp: 0.22, spd: 1.0 },
    { dx: -0.5, dz: 0.86, len: 14, amp: 0.13, spd: 1.4 },
    { dx: 0.95, dz: -0.3, len: 8, amp: 0.07, spd: 1.9 },
  ]), []);
  const height = (x: number, z: number, t: number) => {
    let h = 0;
    for (const w of WAVES) {
      const k = (2 * Math.PI) / w.len;
      h += w.amp * Math.sin((x * w.dx + z * w.dz) * k + t * w.spd);
    }
    return h;
  };

  useFrame((state, dt) => {
    if (matRef.current?.normalMap) {
      matRef.current.normalMap.offset.x += dt * 0.012;
      matRef.current.normalMap.offset.y += dt * 0.006;
    }
    // animate the swell only on modest meshes — at region scale (Buzzards Bay)
    // the vertex count is huge, so keep that water static for performance.
    if (base && meshRef.current && base.length < 45000) {
      const t = state.clock.elapsedTime;
      const g = meshRef.current.geometry;
      const pos = g.attributes.position as THREE.BufferAttribute;
      const arr = pos.array as Float32Array;
      for (let i = 0; i < arr.length; i += 3) {
        arr[i + 1] = base[i + 1] + height(base[i], base[i + 2], t);
      }
      pos.needsUpdate = true;
      g.computeVertexNormals();
    }
  });

  if (!geometry) return null;
  return (
    <mesh ref={meshRef} geometry={geometry} position={[0, WATER_Y, 0]} receiveShadow>
      <meshStandardMaterial
        ref={matRef}
        color="#1a5167"
        roughness={0.16}
        metalness={0.55}
        envMapIntensity={1.2}
        normalMap={normalMap}
        normalScale={new THREE.Vector2(0.45, 0.45)}
        transparent
        opacity={0.96}
      />
    </mesh>
  );
}
