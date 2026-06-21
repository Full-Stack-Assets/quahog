import type { RapierRigidBody } from "@react-three/rapier";

// Cross-component mutable handles shared by the player, car, and camera.
// (Kept out of React state so per-frame updates don't trigger re-renders.)
export const shared = {
  player: null as RapierRigidBody | null,
  car: null as RapierRigidBody | null,
  /** Camera azimuth (radians), eased toward the active target's heading. */
  camYaw: 0,
  /** Active on-foot heading (radians). */
  heading: 0,
  /** Car heading (radians). */
  carYaw: 0,
};
