import { useEffect, useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { CuboidCollider, RigidBody, type RapierRigidBody } from "@react-three/rapier";
import { consumeTap, moveAxis } from "../input";
import { Vehicle } from "../earth/Vehicles";
import { shared } from "../shared";
import { useGame } from "../store";

// Arcade tuning informed by the legacy Unity CarController.cs (high lateral grip
// kills sliding; modest top speed for tight historic streets).
const MAX_SPEED = 22;
const REVERSE_SPEED = 9;

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
    if (game.paused) { shared.skid = false; return; }
    if (game.mode !== "car") { shared.skid = false; shared.carSpeed = 0; return; }

    const ax = moveAxis();
    let yaw = shared.carYaw;
    const fwd = new THREE.Vector3(Math.sin(yaw), 0, Math.cos(yaw));
    const v = rb.linvel();
    const vForward = v.x * fwd.x + v.z * fwd.z;

    // steering scales with speed; invert while reversing
    const grip = THREE.MathUtils.clamp(Math.abs(vForward) / 5, 0, 1);
    const steer = ax.x * 1.7 * dt * grip * (vForward < -0.1 ? -1 : 1);
    yaw -= steer;

    // publish driving signals (§13): speed for camera FOV, skid for tire marks
    shared.carSpeed = vForward;
    shared.skid = Math.abs(ax.x) > 0.55 && Math.abs(vForward) > 11;

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
      position={[-249, 2, 108]}
      rotation={[0, -Math.PI / 2, 0]}
      linearDamping={0.4}
      mass={1.2}
    >
      <CuboidCollider args={[1.0, 0.6, 2.1]} />
      {/* real car model; collider center is ~0.6 above the wheels' contact */}
      <group position={[0, -0.6, 0]}>
        <Vehicle type="mustang" color="#b81d24" />
      </group>
    </RigidBody>
  );
}
