import { useMemo } from "react";
import { RigidBody } from "@react-three/rapier";
import { makeGroundTexture } from "./textures";

// Region-wide land base with a collider. Must span the whole SouthCoast slice
// (~32 km) so nothing floats and land reads as land against the water polygons
// laid on top — otherwise everything past New Bedford is an unidentifiable void.
const SIZE = 60000;

export function Ground() {
  const tex = useMemo(() => {
    const t = makeGroundTexture();
    t.repeat.set(2000, 2000); // ~30 m per tile across the region
    return t;
  }, []);

  return (
    <RigidBody type="fixed" colliders="cuboid" friction={1}>
      <mesh rotation-x={-Math.PI / 2} receiveShadow>
        <boxGeometry args={[SIZE, SIZE, 0.2]} />
        <meshStandardMaterial map={tex} color="#6c7163" roughness={0.97} />
      </mesh>
    </RigidBody>
  );
}
