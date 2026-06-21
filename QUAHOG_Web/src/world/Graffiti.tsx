import { useLayoutEffect, useMemo, useRef } from "react";
import * as THREE from "three";
import { makeGraffiti } from "./textures";
import type { Road } from "../slice";

// Wall graffiti (Phase 2 weathering): colourful spray tags on upright quads set
// back from the street where building walls are, facing the road. Instanced per
// texture variant; near-core only so it stays cheap.

const RADIUS = 240;
const MAX = 60;
const VARIANTS = 5;
const OFFSET = 7; // metres from road centerline to the "wall"
const _m = new THREE.Matrix4();
const _q = new THREE.Quaternion();
const _e = new THREE.Euler();
const _p = new THREE.Vector3();
const _s = new THREE.Vector3();

interface Tag { x: number; z: number; yaw: number; w: number; h: number; v: number }

export function Graffiti({ roads, center }: { roads: Road[]; center: [number, number] }) {
  const texes = useMemo(() => Array.from({ length: VARIANTS }, (_, i) => makeGraffiti(i)), []);
  const tags = useMemo(() => {
    const out: Tag[] = [];
    let n = 0;
    for (const r of roads) {
      if (r.bridge || r.points.length < 2) continue;
      if (!["primary", "secondary", "tertiary", "residential", "unclassified"].includes(r.highway)) continue;
      for (let i = 0; i < r.points.length - 1; i++) {
        const [ax, an] = r.points[i], [bx, bn] = r.points[i + 1];
        const x1 = ax, z1 = -an, x2 = bx, z2 = -bn;
        const len = Math.hypot(x2 - x1, z2 - z1);
        for (let d = 14; d < len; d += 34) {
          n++;
          if (n % 4 !== 0) continue; // sparse
          const t = d / len;
          let dx = (x2 - x1) / len, dz = (z2 - z1) / len;
          // perpendicular "wall" side (random sign)
          const sign = Math.random() < 0.5 ? 1 : -1;
          const nx = -dz * sign, nz = dx * sign;
          const x = x1 + (x2 - x1) * t + nx * OFFSET;
          const z = z1 + (z2 - z1) * t + nz * OFFSET;
          if (Math.hypot(x - center[0], z - center[1]) > RADIUS) continue;
          // face back toward the road (normal = -n)
          out.push({ x, z, yaw: Math.atan2(-nx, -nz), w: 3 + Math.random() * 2, h: 2 + Math.random() * 0.8, v: out.length % VARIANTS });
          if (out.length >= MAX) return out;
        }
      }
    }
    return out;
  }, [roads, center]);

  const byVariant = useMemo(() => texes.map((_, v) => tags.filter((t) => t.v === v)), [tags, texes]);
  const refs = useRef<(THREE.InstancedMesh | null)[]>([]);
  useLayoutEffect(() => {
    byVariant.forEach((list, v) => {
      const mesh = refs.current[v];
      if (!mesh) return;
      list.forEach((t, i) => {
        _e.set(0, t.yaw, 0);
        _q.setFromEuler(_e);
        _m.compose(_p.set(t.x, t.h / 2 + 0.4, t.z), _q, _s.set(t.w, t.h, 1));
        mesh.setMatrixAt(i, _m);
      });
      mesh.count = list.length;
      mesh.instanceMatrix.needsUpdate = true;
    });
  }, [byVariant]);

  return (
    <group>
      {byVariant.map((list, v) => (
        <instancedMesh key={v} ref={(el) => (refs.current[v] = el)} args={[undefined, undefined, Math.max(1, list.length)]} frustumCulled={false}>
          <planeGeometry args={[1, 1]} />
          <meshStandardMaterial map={texes[v]} transparent depthWrite={false} roughness={1} side={THREE.DoubleSide} polygonOffset polygonOffsetFactor={-1} />
        </instancedMesh>
      ))}
    </group>
  );
}
