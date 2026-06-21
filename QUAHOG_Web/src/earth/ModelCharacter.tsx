import { useEffect, useMemo, useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { useAnimations, useGLTF } from "@react-three/drei";
import { clone as skeletonClone } from "three/examples/jsm/utils/SkeletonUtils.js";

// A real rigged, animated human (CesiumMan, © Cesium, CC-BY 4.0) replacing the
// primitive humanoid in the photoreal world. Cloned per instance so the player
// and every pedestrian get their own skeleton + animation mixer.
//
// TUNE these if the figure is the wrong size / facing the wrong way once you see
// it on the tiles — I can't preview WebGL here.
const URL = "/models/CesiumMan.glb";
const SCALE = 0.92; // model is ~2 units tall -> ~1.85 m
const FACE = 0; // yaw offset (radians) so it faces travel direction
const Y_OFF = 0; // lift/drop so feet sit on the ground

useGLTF.preload(URL);

export function ModelCharacter({ moving }: { moving?: () => boolean }) {
  const gltf = useGLTF(URL);
  const scene = useMemo(() => skeletonClone(gltf.scene), [gltf.scene]);
  const { actions, names } = useAnimations(gltf.animations, scene);
  const action = useRef<THREE.AnimationAction | null>(null);

  useEffect(() => {
    scene.traverse((o) => {
      if ((o as THREE.Mesh).isMesh) o.castShadow = true;
    });
    const a = names.length ? actions[names[0]] : null;
    if (a) { a.reset().play(); action.current = a; }
  }, [actions, names, scene]);

  useFrame(() => {
    if (action.current) action.current.paused = moving ? !moving() : false;
  });

  return (
    <group rotation-y={FACE} position={[0, Y_OFF, 0]} scale={SCALE}>
      <primitive object={scene} />
    </group>
  );
}
