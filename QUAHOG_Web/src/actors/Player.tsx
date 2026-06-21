import { useEffect, useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { CapsuleCollider, RigidBody, type RapierRigidBody } from "@react-three/rapier";
import { ModelCharacter } from "../world/ModelCharacter";
import { consumeTap, moveAxis } from "../input";
import { shared } from "../shared";
import { useGame } from "../store";
import { useStats } from "../game";

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
    // hide the body in first-person, and while driving
    if (mesh.current) mesh.current.visible = game.mode === "foot" && game.view !== "first";
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
        useStats.getState().heat(0.5, 0); // grand theft auto
      }
    }

    // melee: punch the nearest pedestrian in front (F)
    if (consumeTap("KeyF")) {
      const p = rb.translation();
      const fx = Math.sin(shared.heading), fz = Math.cos(shared.heading);
      let best: (typeof shared.peds)[number] | null = null;
      let bestD = 2.0;
      for (const ped of shared.peds) {
        const dx = ped.pos.x - p.x, dz = ped.pos.z - p.z;
        const dd = Math.hypot(dx, dz) || 1;
        if (dd < bestD && (dx * fx + dz * fz) / dd > 0.25) { best = ped; bestD = dd; }
      }
      if (best) {
        best.hit += 1;
        const ax = best.pos.x - p.x, az = best.pos.z - p.z;
        const m = Math.hypot(ax, az) || 1;
        best.push.x += ax / m; best.push.z += az / m;
        useStats.getState().heat(0.4, 0.9); // assault draws police + faction heat
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
        {/* rigged human; feet at local 0, so drop by the capsule half-height */}
        <group position={[0, -0.9, 0]}>
          <ModelCharacter
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
