import * as THREE from "three";
import type { RapierRigidBody } from "@react-three/rapier";

// A knockable agent (pedestrian) the player can punch/shove.
export interface Body {
  pos: THREE.Vector3;
  push: THREE.Vector3;
  hit: number; // melee hits queued by the player, consumed by the owner
}

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
  /** Pedestrian bodies registered by StreetLife, for melee contact. */
  peds: [] as Body[],
  /** Day factor 0 (night) .. 1 (noon), driven by the day/night cycle. */
  dayT: 1,
  /** Current in-game hour 0..24. */
  hour: 9,
};
