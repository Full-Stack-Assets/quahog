import { useMemo } from "react";
import { RigidBody } from "@react-three/rapier";
import { makeGroundTexture } from "./textures";

// Flat paved ground with a fixed collider and a tiled procedural texture.
export function Ground() {
  const tex = useMemo(() => {
    const t = makeGroundTexture();
    t.repeat.set(400, 400);
    return t;
  }, []);

  return (
    <RigidBody type="fixed" colliders="cuboid" friction={1}>
      <mesh rotation-x={-Math.PI / 2} receiveShadow>
        <boxGeometry args={[3000, 3000, 0.2]} />
        <meshStandardMaterial map={tex} color="#7a7d86" roughness={0.95} />
      </mesh>
    </RigidBody>
  );
}
