import * as THREE from "three";
import { useFrame, useThree } from "@react-three/fiber";
import { consumeTap } from "../input";
import { shared } from "../shared";
import { useGame } from "../store";

function lerpAngle(a: number, b: number, t: number) {
  let d = ((b - a + Math.PI) % (Math.PI * 2)) - Math.PI;
  if (d < -Math.PI) d += Math.PI * 2;
  return a + d * t;
}

// Chase camera (3rd person) / eye camera (1st person), behind whichever actor is
// active. Press V to toggle the view.
export function FollowCamera() {
  const camera = useThree((s) => s.camera);

  useFrame((_, dt) => {
    const game = useGame.getState();
    if (consumeTap("KeyV")) game.toggleView();

    const mode = game.mode;
    const target = mode === "car" ? shared.car : shared.player;
    if (!target) return;

    const tp = target.translation();
    const heading = mode === "car" ? shared.carYaw : shared.heading;
    shared.camYaw = lerpAngle(shared.camYaw, heading, 1 - Math.exp(-dt * 3));

    if (game.view === "first") {
      const eyeH = mode === "car" ? 1.2 : 1.6;
      const f = new THREE.Vector3(Math.sin(heading), 0, Math.cos(heading));
      camera.position.set(tp.x + f.x * 0.25, tp.y + eyeH, tp.z + f.z * 0.25);
      camera.lookAt(tp.x + f.x * 12, tp.y + eyeH, tp.z + f.z * 12);
      return;
    }

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
