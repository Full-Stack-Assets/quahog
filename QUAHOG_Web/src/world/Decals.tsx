import { useLayoutEffect, useMemo, useRef } from "react";
import * as THREE from "three";
import { makeGrime } from "./textures";
import type { Road } from "../slice";

// Ground grime: oil stains + worn patches scattered on the streets near the core
// (Phase 2 weathering). Instanced flat quads just above the asphalt.

const RADIUS = 230;
const MAX = 200;
const _m = new THREE.Matrix4();
const _q = new THREE.Quaternion();
const _e = new THREE.Euler();
const _p = new THREE.Vector3();
const _s = new THREE.Vector3();

export function Decals({ roads, center }: { roads: Road[]; center: [number, number] }) {
  const tex = useMemo(() => makeGrime(), []);
  const spots = useMemo(() => {
    const out: { x: number; z: number; r: number; rot: number }[] = [];
    let n = 0;
    for (const r of roads) {
      if (r.bridge || r.points.length < 2) continue;
      if (!["primary", "secondary", "tertiary", "residential", "unclassified"].includes(r.highway)) continue;
      for (let i = 0; i < r.points.length - 1; i++) {
        const [ax, an] = r.points[i], [bx, bn] = r.points[i + 1];
        const x1 = ax, z1 = -an, x2 = bx, z2 = -bn;
        const len = Math.hypot(x2 - x1, z2 - z1);
        for (let d = 8; d < len; d += 20) {
          n++;
          if (n % 3 !== 0) continue; // sparse
          const t = d / len;
          const x = x1 + (x2 - x1) * t + (Math.random() - 0.5) * 2;
          const z = z1 + (z2 - z1) * t + (Math.random() - 0.5) * 2;
          if (Math.hypot(x - center[0], z - center[1]) > RADIUS) continue;
          out.push({ x, z, r: 1.4 + Math.random() * 2.6, rot: Math.random() * Math.PI });
          if (out.length >= MAX) return out;
        }
      }
    }
    return out;
  }, [roads, center]);

  const ref = useRef<THREE.InstancedMesh>(null);
  useLayoutEffect(() => {
    const mesh = ref.current;
    if (!mesh) return;
    for (let i = 0; i < spots.length; i++) {
      _e.set(-Math.PI / 2, spots[i].rot, 0);
      _q.setFromEuler(_e);
      _m.compose(_p.set(spots[i].x, 0.075, spots[i].z), _q, _s.setScalar(spots[i].r));
      mesh.setMatrixAt(i, _m);
    }
    mesh.count = spots.length;
    mesh.instanceMatrix.needsUpdate = true;
  }, [spots]);

  return (
    <instancedMesh ref={ref} args={[undefined, undefined, Math.max(1, spots.length)]}>
      <planeGeometry args={[1, 1]} />
      <meshStandardMaterial map={tex} transparent depthWrite={false} roughness={1} polygonOffset polygonOffsetFactor={-1} />
    </instancedMesh>
  );
}
