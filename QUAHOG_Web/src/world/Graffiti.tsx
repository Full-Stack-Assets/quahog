import { useLayoutEffect, useMemo, useRef } from "react";
import * as THREE from "three";
import { makeGraffiti } from "./textures";
import { sampleRoadEdges } from "./roadSamples";
import type { Road } from "../slice";

// Wall graffiti (Phase 2 weathering): colourful spray tags on upright quads set
// back from the street where building walls are, facing the road. Instanced per
// texture variant; near-core only so it stays cheap.

const RADIUS = 270;
const MAX = 150;
const VARIANTS = 5;
const OFFSET = 7; // metres from road centerline to the "wall"
const _m = new THREE.Matrix4();
const _q = new THREE.Quaternion();
const _e = new THREE.Euler();
const _p = new THREE.Vector3();
const _s = new THREE.Vector3();

interface Tag { x: number; z: number; yaw: number; w: number; h: number }

export function Graffiti({ roads, center }: { roads: Road[]; center: [number, number] }) {
  const texes = useMemo(() => Array.from({ length: VARIANTS }, (_, i) => makeGraffiti(i)), []);
  // bucket tags straight into per-variant arrays (one bucket per texture)
  const byVariant = useMemo(() => {
    const buckets: Tag[][] = Array.from({ length: VARIANTS }, () => []);
    sampleRoadEdges(roads, center, { radius: RADIUS, step: 34, startAt: 14, sparse: 4, max: MAX })
      .forEach((s, i) => {
        const sign = Math.random() < 0.5 ? 1 : -1;      // which side of the street
        const nx = -s.dz * sign, nz = s.dx * sign;      // perpendicular "wall" normal
        buckets[i % VARIANTS].push({
          x: s.x + nx * OFFSET, z: s.z + nz * OFFSET,
          yaw: Math.atan2(-nx, -nz),                    // face back toward the road
          w: 3 + Math.random() * 2, h: 2 + Math.random() * 0.8,
        });
      });
    return buckets;
  }, [roads, center]);

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
