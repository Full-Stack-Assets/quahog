import { EffectComposer, Bloom, Vignette, SMAA, ChromaticAberration, Noise } from "@react-three/postprocessing";
import { BlendFunction } from "postprocessing";
import * as THREE from "three";

// Cinematic post-processing stack (§3). ACES tone mapping is set on the renderer
// (App.tsx); here we add bloom (neon/headlights/sun glints), a soft vignette,
// subtle lens chromatic aberration + film grain, and SMAA anti-aliasing.
export function Effects() {
  return (
    <EffectComposer multisampling={0}>
      <Bloom
        intensity={0.55}
        luminanceThreshold={0.78}
        luminanceSmoothing={0.25}
        mipmapBlur
      />
      <ChromaticAberration offset={new THREE.Vector2(0.0008, 0.0008)} radialModulation modulationOffset={0.4} />
      <Noise premultiply blendFunction={BlendFunction.OVERLAY} opacity={0.16} />
      <Vignette eskil={false} offset={0.28} darkness={0.68} />
      <SMAA />
    </EffectComposer>
  );
}
