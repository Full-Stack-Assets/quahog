import * as THREE from "three";
import { useFrame, useThree } from "@react-three/fiber";
import { shared } from "../shared";
import { useGame } from "../store";

function lerpAngle(a: number, b: number, t: number) {
  let d = ((b - a + Math.PI) % (Math.PI * 2)) - Math.PI;
  if (d < -Math.PI) d += Math.PI * 2;
  return a + d * t;
}

// Third-person chase camera that eases behind whichever actor is active.
export function FollowCamera() {
  const camera = useThree((s) => s.camera);

  useFrame((_, dt) => {
    const mode = useGame.getState().mode;
    const target = mode === "car" ? shared.car : shared.player;
    if (!target) return;

    const tp = target.translation();
    const heading = mode === "car" ? shared.carYaw : shared.heading;
    shared.camYaw = lerpAngle(shared.camYaw, heading, 1 - Math.exp(-dt * 3));

    const yaw = shared.camYaw;
    const dist = mode === "car" ? 12 : 7;
    const height = mode === "car" ? 5.5 : 4;
    const fwd = new THREE.Vector3(Math.sin(yaw), 0, Math.cos(yaw));

    const want = new THREE.Vector3(
      tp.x - fwd.x * dist,
      tp.y + height,
      tp.z - fwd.z * dist,
    );
    camera.position.lerp(want, 1 - Math.exp(-dt * 6));
    camera.lookAt(tp.x, tp.y + 1.5, tp.z);
  });

  return null;
}
