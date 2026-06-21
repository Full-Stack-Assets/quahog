import type { RapierRigidBody } from "@react-three/rapier";

// Cross-component mutable handles shared by the player, car, and camera.
// (Kept out of React state so per-frame updates don't trigger re-renders.)
export const shared = {
  player: null as RapierRigidBody | null,
  car: null as RapierRigidBody | null,
  // Initial facing = -x (west), looking toward Seamen's Bethel from the spawn.
  /** Camera azimuth (radians), eased toward the active target's heading. */
  camYaw: -Math.PI / 2,
  /** Active on-foot heading (radians). */
  heading: -Math.PI / 2,
  /** Car heading (radians). */
  carYaw: -Math.PI / 2,
};
