import { useLayoutEffect, useMemo, useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";

// Working-waterfront dressing (§6): dock pilings along the harbor edge, bobbing
// buoys, and a couple of fishing boats riding the swell. Placement is derived
// from the OSM water polygon so the props hug the real shoreline.

const _m = new THREE.Matrix4();
const _q = new THREE.Quaternion();
const _s = new THREE.Vector3();
const _p = new THREE.Vector3();
const RADIUS = 320;

export function HarborProps({
  polys,
  center,
}: {
  polys: [number, number][][];
  center: [number, number];
}) {
  const { pilings, buoys, boats } = useMemo(() => {
    const pilings: [number, number][] = [];
    const buoys: [number, number][] = [];
    const boats: [number, number, number][] = []; // x, z, rot
    const ring = polys.reduce((a, b) => (b.length > a.length ? b : a), [] as [number, number][]);
    if (ring.length > 2) {
      let acc = 0;
      for (let i = 0; i < ring.length - 1; i++) {
        const [ax, an] = ring[i];
        const [bx, bn] = ring[i + 1];
        const x1 = ax, z1 = -an, x2 = bx, z2 = -bn;
        const seg = Math.hypot(x2 - x1, z2 - z1);
        const ux = (x2 - x1) / (seg || 1), uz = (z2 - z1) / (seg || 1);
        for (let d = 0; d < seg; d += 7) {
          acc++;
          const x = x1 + ux * d, z = z1 + uz * d;
          if (Math.hypot(x - center[0], z - center[1]) > RADIUS) continue;
          pilings.push([x, z]);
          // push a buoy slightly off the edge into the water now and then
          if (acc % 5 === 0) buoys.push([x - uz * 6, z + ux * 6]);
          if (acc % 23 === 0) boats.push([x - uz * 12, z + ux * 12, Math.atan2(ux, uz)]);
        }
      }
    }
    return {
      pilings: pilings.slice(0, 600),
      buoys: buoys.slice(0, 120),
      boats: boats.slice(0, 10),
    };
  }, [polys, center]);

  const pilingRef = useRef<THREE.InstancedMesh>(null);
  const buoyRef = useRef<THREE.InstancedMesh>(null);
  const boatRefs = useRef<(THREE.Group | null)[]>([]);

  useLayoutEffect(() => {
    const pm = pilingRef.current;
    if (pm) {
      for (let i = 0; i < pilings.length; i++) {
        _q.identity();
        _m.compose(_p.set(pilings[i][0], 0.6, pilings[i][1]), _q, _s.set(1, 1, 1));
        pm.setMatrixAt(i, _m);
      }
      pm.count = pilings.length;
      pm.instanceMatrix.needsUpdate = true;
    }
  }, [pilings]);

  useFrame((state) => {
    const t = state.clock.elapsedTime;
    // bob the buoys
    const bm = buoyRef.current;
    if (bm) {
      for (let i = 0; i < buoys.length; i++) {
        const y = 0.25 + Math.sin(t * 1.6 + i) * 0.12;
        _q.setFromAxisAngle(_p.set(1, 0, 0), Math.sin(t + i) * 0.15);
        _m.compose(_p.set(buoys[i][0], y, buoys[i][1]), _q, _s.set(1, 1, 1));
        bm.setMatrixAt(i, _m);
      }
      bm.count = buoys.length;
      bm.instanceMatrix.needsUpdate = true;
    }
    // bob + roll the boats
    boats.forEach((b, i) => {
      const g = boatRefs.current[i];
      if (!g) return;
      g.position.set(b[0], 0.35 + Math.sin(t * 1.1 + i * 2) * 0.18, b[1]);
      g.rotation.set(Math.sin(t * 0.9 + i) * 0.06, b[2], Math.sin(t * 1.3 + i) * 0.08);
    });
  });

  return (
    <group>
      <instancedMesh ref={pilingRef} args={[undefined, undefined, Math.max(1, pilings.length)]} castShadow>
        <cylinderGeometry args={[0.22, 0.26, 2.2, 6]} />
        <meshStandardMaterial color="#3c2c1e" roughness={0.95} />
      </instancedMesh>

      <instancedMesh ref={buoyRef} args={[undefined, undefined, Math.max(1, buoys.length)]}>
        <sphereGeometry args={[0.35, 8, 6]} />
        <meshStandardMaterial color="#c0341f" roughness={0.5} emissive="#3a0a06" emissiveIntensity={0.3} />
      </instancedMesh>

      {boats.map((_, i) => (
        <group key={i} ref={(el) => (boatRefs.current[i] = el)}>
          {/* hull */}
          <mesh castShadow>
            <boxGeometry args={[2.4, 1.0, 6.5]} />
            <meshStandardMaterial color="#6a7a86" roughness={0.8} />
          </mesh>
          {/* wheelhouse */}
          <mesh position={[0, 1.0, -1.2]} castShadow>
            <boxGeometry args={[1.8, 1.3, 2.0]} />
            <meshStandardMaterial color="#d8d2c4" roughness={0.7} />
          </mesh>
          {/* mast */}
          <mesh position={[0, 2.4, 0.6]}>
            <cylinderGeometry args={[0.06, 0.06, 3.2, 5]} />
            <meshStandardMaterial color="#2a2a2a" />
          </mesh>
        </group>
      ))}
    </group>
  );
}
