import { useEffect, useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { CuboidCollider, RigidBody, type RapierRigidBody } from "@react-three/rapier";
import { consumeTap, moveAxis } from "../input";
import { shared } from "../shared";
import { useGame } from "../store";

const MAX_SPEED = 28;
const REVERSE_SPEED = 12;

export function Car() {
  const body = useRef<RapierRigidBody>(null);

  useEffect(() => {
    shared.car = body.current;
    return () => {
      shared.car = null;
    };
  }, []);

  useFrame((_, dt) => {
    const rb = body.current;
    if (!rb) return;
    const game = useGame.getState();
    if (game.mode !== "car") return;

    const ax = moveAxis();
    let yaw = shared.carYaw;
    const fwd = new THREE.Vector3(Math.sin(yaw), 0, Math.cos(yaw));
    const v = rb.linvel();
    const vForward = v.x * fwd.x + v.z * fwd.z;

    // steering scales with speed; invert while reversing
    const grip = THREE.MathUtils.clamp(Math.abs(vForward) / 5, 0, 1);
    yaw -= ax.x * 1.5 * dt * grip * (vForward < -0.1 ? -1 : 1);

    // throttle / brake / coast
    const target =
      ax.y > 0 ? MAX_SPEED * ax.y : ax.y < 0 ? -REVERSE_SPEED * -ax.y : 0;
    const rate = ax.y !== 0 ? 2.5 : 1.5;
    const nf = THREE.MathUtils.lerp(vForward, target, 1 - Math.exp(-dt * rate));

    const nfwd = new THREE.Vector3(Math.sin(yaw), 0, Math.cos(yaw));
    rb.setLinvel({ x: nfwd.x * nf, y: v.y, z: nfwd.z * nf }, true);
    rb.setRotation(
      { x: 0, y: Math.sin(yaw / 2), z: 0, w: Math.cos(yaw / 2) },
      true,
    );
    shared.carYaw = yaw;

    // exit
    if (consumeTap("KeyE")) {
      const c = rb.translation();
      const right = new THREE.Vector3(nfwd.z, 0, -nfwd.x);
      const pl = shared.player;
      if (pl) {
        pl.setEnabled(true);
        pl.setTranslation(
          { x: c.x + right.x * 3, y: 2, z: c.z + right.z * 3 },
          true,
        );
        pl.setLinvel({ x: 0, y: 0, z: 0 }, true);
      }
      game.setMode("foot");
    }
  });

  return (
    <RigidBody
      ref={body}
      colliders={false}
      enabledRotations={[false, false, false]}
      position={[4, 2, 14]}
      linearDamping={0.4}
      mass={1.2}
    >
      <CuboidCollider args={[1.0, 0.6, 2.1]} />
      {/* body */}
      <mesh castShadow position={[0, 0.1, 0]}>
        <boxGeometry args={[2.0, 0.9, 4.2]} />
        <meshStandardMaterial color="#1f6f8b" metalness={0.3} roughness={0.4} />
      </mesh>
      {/* cabin */}
      <mesh castShadow position={[0, 0.8, -0.2]}>
        <boxGeometry args={[1.8, 0.7, 2.0]} />
        <meshStandardMaterial color="#0e3b4a" metalness={0.2} roughness={0.5} />
      </mesh>
      {/* wheels */}
      {[
        [-1.0, -0.4, 1.4],
        [1.0, -0.4, 1.4],
        [-1.0, -0.4, -1.4],
        [1.0, -0.4, -1.4],
      ].map((p, i) => (
        <mesh key={i} position={p as [number, number, number]} rotation-z={Math.PI / 2}>
          <cylinderGeometry args={[0.45, 0.45, 0.3, 12]} />
          <meshStandardMaterial color="#111111" roughness={0.9} />
        </mesh>
      ))}
    </RigidBody>
  );
}
