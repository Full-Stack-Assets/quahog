import { useMemo } from "react";
import * as THREE from "three";
import type { Road } from "../slice";

// All road centerlines extruded to flat ribbons, merged into one mesh.
// (Visual blockout; the ground collider handles physics.)
export function Roads({ roads }: { roads: Road[] }) {
  const geometry = useMemo(() => {
    const pos: number[] = [];
    const idx: number[] = [];
    let v = 0;
    const y = 0.06;
    for (const r of roads) {
      const half = r.width / 2;
      for (let i = 0; i < r.points.length - 1; i++) {
        const [ax, an] = r.points[i];
        const [bx, bn] = r.points[i + 1];
        // world: x = east, z = -north
        const x1 = ax, z1 = -an, x2 = bx, z2 = -bn;
        const dx = x2 - x1, dz = z2 - z1;
        const len = Math.hypot(dx, dz);
        if (len < 1e-4) continue;
        const nx = (-dz / len) * half;
        const nz = (dx / len) * half;
        pos.push(
          x1 + nx, y, z1 + nz,
          x2 + nx, y, z2 + nz,
          x2 - nx, y, z2 - nz,
          x1 - nx, y, z1 - nz,
        );
        idx.push(v, v + 1, v + 2, v, v + 2, v + 3);
        v += 4;
      }
    }
    const g = new THREE.BufferGeometry();
    g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
    g.setIndex(idx);
    g.computeVertexNormals();
    return g;
  }, [roads]);

  return (
    <mesh geometry={geometry} receiveShadow>
      <meshStandardMaterial color="#2a2b38" roughness={0.8} />
    </mesh>
  );
}
