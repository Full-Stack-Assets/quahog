import { EffectComposer, Bloom, Vignette, SMAA } from "@react-three/postprocessing";

// Cinematic post-processing stack (§3). ACES tone mapping is set on the renderer
// (App.tsx); here we add bloom for neon/headlights/sun glints, a soft vignette,
// and SMAA anti-aliasing. Kept light so it stays performant.
export function Effects() {
  return (
    <EffectComposer multisampling={0}>
      <Bloom
        intensity={0.55}
        luminanceThreshold={0.78}
        luminanceSmoothing={0.25}
        mipmapBlur
      />
      <Vignette eskil={false} offset={0.28} darkness={0.68} />
      <SMAA />
    </EffectComposer>
  );
}
