import { useLayoutEffect, useMemo, useRef } from "react";
import * as THREE from "three";
import { sampleRoadEdges } from "./roadSamples";
import type { Road } from "../slice";

// Extra curbside street detail (§7 streets pass): stop signs, parking meters,
// trash cans, and the odd traffic cone — instanced and placed along the road
// edges near the core to complement the lamp/hydrant/tree layer in <Props>.

const RADIUS = 240;
const _m = new THREE.Matrix4();
const _q = new THREE.Quaternion();
const _s = new THREE.Vector3(1, 1, 1);
const _p = new THREE.Vector3();
const _up = new THREE.Vector3(0, 1, 0);

type Place = { x: number; z: number; rot: number };

function fill(mesh: THREE.InstancedMesh | null, places: Place[], y: number) {
  if (!mesh) return;
  for (let i = 0; i < places.length; i++) {
    _q.setFromAxisAngle(_up, places[i].rot);
    _m.compose(_p.set(places[i].x, y, places[i].z), _q, _s);
    mesh.setMatrixAt(i, _m);
  }
  mesh.count = places.length;
  mesh.instanceMatrix.needsUpdate = true;
}

export function StreetExtras({ roads, center }: { roads: Road[]; center: [number, number] }) {
  const L = useMemo(() => {
    const samples = sampleRoadEdges(roads, center, { radius: RADIUS, step: 28, sparse: 1, max: 900 });
    const stops: Place[] = [], meters: Place[] = [], cans: Place[] = [], cones: Place[] = [];
    let n = 0;
    for (const s of samples) {
      const nx = -s.dz, nz = s.dx;          // left normal of travel
      const side = (n & 1) ? 1 : -1;
      const off = 5.2;                       // curbside offset from centerline
      const x = s.x + nx * off * side, z = s.z + nz * off * side;
      const rot = Math.atan2(nx * side, nz * side);
      const kind = n % 7;
      if (kind === 0) stops.push({ x, z, rot });
      else if (kind === 2) meters.push({ x, z, rot });
      else if (kind === 4) cans.push({ x, z, rot });
      else if (kind === 6) cones.push({ x: x - nx * side * 3.4, z: z - nz * side * 3.4, rot }); // nudge into gutter
      n++;
    }
    return { stops, meters, cans, cones };
  }, [roads, center]);

  const stopPole = useRef<THREE.InstancedMesh>(null);
  const stopSign = useRef<THREE.InstancedMesh>(null);
  const meterPole = useRef<THREE.InstancedMesh>(null);
  const meterHead = useRef<THREE.InstancedMesh>(null);
  const can = useRef<THREE.InstancedMesh>(null);
  const cone = useRef<THREE.InstancedMesh>(null);

  useLayoutEffect(() => {
    fill(stopPole.current, L.stops, 1.1);
    fill(stopSign.current, L.stops, 2.3);
    fill(meterPole.current, L.meters, 0.55);
    fill(meterHead.current, L.meters, 1.15);
    fill(can.current, L.cans, 0.5);
    fill(cone.current, L.cones, 0.3);
  }, [L]);

  return (
    <group>
      {/* stop signs: grey pole + red octagon-ish plate */}
      <instancedMesh ref={stopPole} args={[undefined, undefined, Math.max(1, L.stops.length)]} castShadow>
        <cylinderGeometry args={[0.05, 0.05, 2.2, 6]} />
        <meshStandardMaterial color="#9a9ca0" roughness={0.6} metalness={0.5} />
      </instancedMesh>
      <instancedMesh ref={stopSign} args={[undefined, undefined, Math.max(1, L.stops.length)]} castShadow>
        <cylinderGeometry args={[0.34, 0.34, 0.06, 8]} />
        <meshStandardMaterial color="#b32222" roughness={0.5} emissive="#3a0808" emissiveIntensity={0.3} />
      </instancedMesh>

      {/* parking meters */}
      <instancedMesh ref={meterPole} args={[undefined, undefined, Math.max(1, L.meters.length)]} castShadow>
        <cylinderGeometry args={[0.045, 0.05, 1.1, 6]} />
        <meshStandardMaterial color="#2b2e33" roughness={0.6} metalness={0.5} />
      </instancedMesh>
      <instancedMesh ref={meterHead} args={[undefined, undefined, Math.max(1, L.meters.length)]} castShadow>
        <boxGeometry args={[0.16, 0.3, 0.12]} />
        <meshStandardMaterial color="#3a6b5a" roughness={0.5} metalness={0.4} />
      </instancedMesh>

      {/* trash cans */}
      <instancedMesh ref={can} args={[undefined, undefined, Math.max(1, L.cans.length)]} castShadow>
        <cylinderGeometry args={[0.28, 0.24, 1.0, 10]} />
        <meshStandardMaterial color="#384034" roughness={0.85} />
      </instancedMesh>

      {/* traffic cones */}
      <instancedMesh ref={cone} args={[undefined, undefined, Math.max(1, L.cones.length)]} castShadow>
        <coneGeometry args={[0.22, 0.6, 8]} />
        <meshStandardMaterial color="#e8631a" roughness={0.7} />
      </instancedMesh>
    </group>
  );
}
