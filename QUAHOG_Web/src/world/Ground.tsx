import { useMemo } from "react";
import { RigidBody, CuboidCollider } from "@react-three/rapier";
import { makeGroundTexture } from "./textures";

// Region-wide land base. The visual plane sits at y=0 and the collider top is at
// y=0, so roads (0.05–0.08) and water (0.45) sit cleanly ABOVE it — otherwise
// they z-fight the ground and flicker. Spans the whole ~32 km slice.
const SIZE = 60000;

export function Ground() {
  const tex = useMemo(() => {
    const t = makeGroundTexture();
    t.repeat.set(2000, 2000); // ~30 m per tile across the region
    return t;
  }, []);

  return (
    <RigidBody type="fixed">
      <CuboidCollider args={[SIZE / 2, 0.1, SIZE / 2]} position={[0, -0.1, 0]} friction={1} />
      <mesh rotation-x={-Math.PI / 2} position={[0, 0, 0]} receiveShadow>
        <planeGeometry args={[SIZE, SIZE]} />
        <meshStandardMaterial map={tex} color="#6c7163" roughness={0.97} />
      </mesh>
    </RigidBody>
  );
}
