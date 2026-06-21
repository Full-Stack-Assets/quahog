import { useEffect, useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { CapsuleCollider, RigidBody, type RapierRigidBody } from "@react-three/rapier";
import { Character } from "../world/Character";
import { consumeTap, moveAxis } from "../input";
import { shared } from "../shared";
import { useGame } from "../store";

const WALK_SPEED = 6.5;
const ENTER_RADIUS = 4.5;

export function Player() {
  const body = useRef<RapierRigidBody>(null);
  const mesh = useRef<THREE.Group>(null);

  useEffect(() => {
    shared.player = body.current;
    return () => {
      shared.player = null;
    };
  }, []);

  useFrame(() => {
    const rb = body.current;
    if (!rb) return;
    const game = useGame.getState();
    if (game.mode === "car") return; // disabled while driving

    const ax = moveAxis();
    const yaw = shared.camYaw;
    const fwd = new THREE.Vector3(Math.sin(yaw), 0, Math.cos(yaw));
    const right = new THREE.Vector3(fwd.z, 0, -fwd.x);
    const dir = new THREE.Vector3()
      .addScaledVector(fwd, ax.y)
      .addScaledVector(right, ax.x);

    const v = rb.linvel();
    if (dir.lengthSq() > 1e-4) {
      dir.normalize();
      rb.setLinvel({ x: dir.x * WALK_SPEED, y: v.y, z: dir.z * WALK_SPEED }, true);
      shared.heading = Math.atan2(dir.x, dir.z);
    } else {
      rb.setLinvel({ x: 0, y: v.y, z: 0 }, true);
    }
    if (mesh.current) mesh.current.rotation.y = shared.heading;

    // proximity to car + enter
    const car = shared.car;
    if (car) {
      const p = rb.translation();
      const c = car.translation();
      const d = Math.hypot(p.x - c.x, p.z - c.z);
      game.setNearCar(d < ENTER_RADIUS);
      if (d < ENTER_RADIUS && consumeTap("KeyE")) {
        rb.setEnabled(false);
        game.setNearCar(false);
        game.setMode("car");
      }
    }
  });

  return (
    <RigidBody
      ref={body}
      colliders={false}
      enabledRotations={[false, false, false]}
      position={[-256.2, 3, 106.5]}
      friction={0.6}
      linearDamping={0.2}
      mass={1}
    >
      <CapsuleCollider args={[0.5, 0.4]} />
      <group ref={mesh}>
        {/* humanoid; feet at local 0, so drop by the capsule half-height */}
        <group position={[0, -0.9, 0]}>
          <Character
            skin="#caa07a"
            shirt="#b23b34"
            pants="#23344f"
            hair="#2a2018"
            moving={() => {
              const v = body.current?.linvel();
              return !!v && Math.hypot(v.x, v.z) > 0.6;
            }}
          />
        </group>
      </group>
    </RigidBody>
  );
}
