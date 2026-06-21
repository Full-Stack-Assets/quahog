import { RigidBody } from "@react-three/rapier";

// Flat harbor-grey ground with a fixed collider.
export function Ground() {
  return (
    <RigidBody type="fixed" colliders="cuboid" friction={1}>
      <mesh rotation-x={-Math.PI / 2} receiveShadow>
        <boxGeometry args={[2000, 2000, 0.2]} />
        <meshStandardMaterial color="#15161f" roughness={0.95} />
      </mesh>
    </RigidBody>
  );
}
