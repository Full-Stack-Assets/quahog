import { Suspense, useCallback, useEffect, useState } from "react";
import * as THREE from "three";
import { Canvas } from "@react-three/fiber";
import { Experience } from "./Experience";
import { HUD } from "./HUD";
import { Minimap } from "./Minimap";
import { PauseMenu } from "./ui/PauseMenu";
import { CharacterMenu } from "./ui/CharacterMenu";
import { BigMap } from "./ui/BigMap";
import { TouchControls } from "./ui/TouchControls";
import { Toasts } from "./ui/Toasts";
import { DebugStats } from "./ui/DebugStats";
import { StartMenu } from "./ui/StartMenu";
import { Radio } from "./audio/Radio";
import { installInput } from "./input";

export default function App() {
  const [sliceName, setSliceName] = useState("loading…");
  const [progress, setProgress] = useState(0);

  // stable callbacks so the Experience loader effect doesn't re-run each render
  const onReady = useCallback((s: { name: string }) => setSliceName(s.name), []);
  const onProgress = useCallback((f: number) => setProgress(f), []);

  useEffect(() => {
    installInput();
  }, []);

  return (
    <>
      <Canvas
        shadows="soft"
        camera={{ fov: 60, near: 0.3, far: 1000, position: [0, 10, 24] }}
        dpr={[1, 1.5]}
        gl={{ antialias: false, toneMapping: THREE.ACESFilmicToneMapping, toneMappingExposure: 1.05 }}
      >
        <Suspense fallback={null}>
          <Experience onReady={onReady} onProgress={onProgress} />
        </Suspense>
      </Canvas>
      <HUD sliceName={sliceName} />
      <Minimap />
      <BigMap />
      <CharacterMenu />
      <PauseMenu />
      <TouchControls />
      <Toasts />
      <Radio />
      <DebugStats />
      <StartMenu sliceName={sliceName} progress={progress} />
    </>
  );
}
