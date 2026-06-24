import { useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { shared } from "../shared";

// Recognizable low-poly road cars built from primitives. Silhouettes are tuned
// per model (ride height, hood/cabin proportions) so a Bronco reads boxy/tall, a
// Mustang long-hood/low, the Z a wedge, etc.

export type VehicleType =
  | "bronco" | "mustang" | "infiniti" | "nissanz" | "rav4"
  | "pickup" | "wagon" | "van" | "sedan" | "boxtruck" | "coupe" | "suv";
export const VEHICLE_TYPES: VehicleType[] =
  ["bronco", "mustang", "infiniti", "nissanz", "rav4", "pickup", "wagon", "van", "sedan",
   "boxtruck", "coupe", "suv"];

interface Spec {
  L: number; W: number; H: number; y: number; // body box + center height
  cabL: number; cabH: number; cabZ: number; cabW?: number; // greenhouse
  ride: number; wheelR: number; // axle height + wheel radius
  glass: string; hood?: number; // optional long-hood block length
}

const _wp = new THREE.Vector3();

const SPECS: Record<VehicleType, Spec> = {
  bronco:   { L: 4.3, W: 2.0, H: 1.3, y: 1.15, cabL: 2.4, cabH: 0.9, cabZ: -0.2, ride: 0.55, wheelR: 0.52, glass: "#20303a" },
  mustang:  { L: 4.7, W: 1.95, H: 0.8, y: 0.78, cabL: 1.7, cabH: 0.62, cabZ: -0.7, ride: 0.34, wheelR: 0.46, glass: "#141a1f", hood: 1.6 },
  infiniti: { L: 4.7, W: 1.85, H: 0.85, y: 0.82, cabL: 2.1, cabH: 0.66, cabZ: -0.1, ride: 0.34, wheelR: 0.44, glass: "#1a2128" },
  nissanz:  { L: 4.4, W: 1.85, H: 0.72, y: 0.7, cabL: 1.4, cabH: 0.55, cabZ: -0.6, ride: 0.3, wheelR: 0.45, glass: "#0f1418", hood: 1.7 },
  rav4:     { L: 4.4, W: 1.9, H: 1.15, y: 1.0, cabL: 2.2, cabH: 0.82, cabZ: -0.15, ride: 0.48, wheelR: 0.48, glass: "#212a30" },
  // mid-80s work pickup: tall, cab-forward, open bed behind
  pickup:   { L: 5.0, W: 2.0, H: 1.0, y: 0.95, cabL: 1.5, cabH: 0.78, cabZ: 0.7, ride: 0.5, wheelR: 0.5, glass: "#1c242b" },
  // station wagon: long low roof all the way back
  wagon:    { L: 4.9, W: 1.9, H: 0.86, y: 0.82, cabL: 2.7, cabH: 0.72, cabZ: -0.1, ride: 0.34, wheelR: 0.44, glass: "#1a2128" },
  // boxy cargo/work van: one tall volume, short stubby hood
  van:      { L: 4.9, W: 2.0, H: 1.55, y: 1.18, cabL: 1.3, cabH: 0.25, cabZ: 1.0, ride: 0.45, wheelR: 0.46, glass: "#161c21" },
  // plain 4-door sedan
  sedan:    { L: 4.6, W: 1.85, H: 0.85, y: 0.82, cabL: 2.3, cabH: 0.7, cabZ: -0.05, ride: 0.34, wheelR: 0.44, glass: "#1b222a" },
  // box delivery truck: long tall body, small forward cab
  boxtruck: { L: 6.4, W: 2.3, H: 2.1, y: 1.45, cabL: 1.5, cabH: 0.0, cabZ: 2.3, ride: 0.5, wheelR: 0.5, glass: "#161c21" },
  // small 2-door coupe: short, low, long-ish hood
  coupe:    { L: 4.2, W: 1.8, H: 0.8, y: 0.76, cabL: 1.5, cabH: 0.6, cabZ: -0.4, ride: 0.32, wheelR: 0.43, glass: "#141a1f", hood: 1.3 },
  // tall family SUV
  suv:      { L: 4.8, W: 2.0, H: 1.25, y: 1.05, cabL: 2.4, cabH: 0.85, cabZ: -0.15, ride: 0.5, wheelR: 0.5, glass: "#212a30" },
};

export function Vehicle({ type, color, brake }: { type: VehicleType; color: string; brake?: () => boolean }) {
  const s = SPECS[type];
  const halfL = s.L / 2;
  const wheelZ = halfL - 0.95;
  const wheelX = s.W / 2 - 0.05;
  const cabW = s.cabW ?? s.W - 0.25;
  const head = useRef<THREE.MeshStandardMaterial>(null);
  const tail = useRef<THREE.MeshStandardMaterial>(null);
  const root = useRef<THREE.Group>(null);
  const wheels = useRef<(THREE.Group | null)[]>([]);
  const prev = useRef<THREE.Vector3 | null>(null);

  // headlights/taillights come up at dusk; taillights flare under braking; and
  // wheels roll by self-measured world speed (works for any vehicle).
  useFrame(() => {
    const night = 1 - shared.dayT;
    if (head.current) head.current.emissiveIntensity = 0.3 + night * 1.6;
    if (tail.current) tail.current.emissiveIntensity = 0.3 + night * 0.9 + (brake?.() ? 2.2 : 0);
    if (root.current) {
      root.current.getWorldPosition(_wp);
      if (prev.current) {
        const roll = prev.current.distanceTo(_wp) / s.wheelR;
        if (roll > 1e-4) for (const w of wheels.current) if (w) w.rotation.x += roll;
        prev.current.copy(_wp);
      } else prev.current = _wp.clone();
    }
  });

  return (
    <group ref={root} position={[0, s.ride - s.wheelR, 0]}>
      {/* body */}
      <mesh position={[0, s.y, 0]} castShadow>
        <boxGeometry args={[s.W, s.H, s.L]} />
        <meshStandardMaterial color={color} metalness={0.35} roughness={0.42} />
      </mesh>
      {/* long hood accent for sports cars */}
      {s.hood && (
        <mesh position={[0, s.y + s.H / 2 - 0.04, halfL - s.hood / 2 - 0.1]} castShadow>
          <boxGeometry args={[s.W - 0.2, 0.1, s.hood]} />
          <meshStandardMaterial color={color} metalness={0.4} roughness={0.35} />
        </mesh>
      )}
      {/* greenhouse / cabin */}
      <mesh position={[0, s.y + s.H / 2 + s.cabH / 2 - 0.02, s.cabZ]} castShadow>
        <boxGeometry args={[cabW, s.cabH, s.cabL]} />
        <meshStandardMaterial color={s.glass} metalness={0.2} roughness={0.25} />
      </mesh>
      {/* roof cap (color) */}
      <mesh position={[0, s.y + s.H / 2 + s.cabH - 0.04, s.cabZ]}>
        <boxGeometry args={[cabW + 0.02, 0.08, s.cabL]} />
        <meshStandardMaterial color={color} metalness={0.35} roughness={0.4} />
      </mesh>
      {/* headlights */}
      <mesh position={[0, s.y, halfL + 0.01]}>
        <boxGeometry args={[s.W - 0.3, 0.18, 0.05]} />
        <meshStandardMaterial ref={head} color="#fdf6d0" emissive="#fde9a0" emissiveIntensity={0.5} />
      </mesh>
      {/* taillights */}
      <mesh position={[0, s.y, -halfL - 0.01]}>
        <boxGeometry args={[s.W - 0.3, 0.16, 0.05]} />
        <meshStandardMaterial ref={tail} color="#7a1010" emissive="#c01818" emissiveIntensity={0.5} />
      </mesh>
      {/* wheels */}
      {[
        [-wheelX, 0, wheelZ], [wheelX, 0, wheelZ],
        [-wheelX, 0, -wheelZ], [wheelX, 0, -wheelZ],
      ].map((p, i) => (
        <group key={i} ref={(el) => (wheels.current[i] = el)} position={[p[0], s.wheelR, p[2]]}>
          <mesh rotation-z={Math.PI / 2}>
            <cylinderGeometry args={[s.wheelR, s.wheelR, 0.32, 14]} />
            <meshStandardMaterial color="#0d0d0f" roughness={0.9} />
          </mesh>
        </group>
      ))}
    </group>
  );
}
