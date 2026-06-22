import { Component, Suspense, useEffect, useState, type ReactNode } from "react";
import * as THREE from "three";
import { Canvas } from "@react-three/fiber";
import { Experience } from "./Experience";

// Keep one failing 3D component (e.g. a CDN asset that won't load) from blanking
// the entire game — render an empty scene instead of an unhandled throw. The HUD
// and menus (outside the Canvas) keep working.
class SceneBoundary extends Component<{ children: ReactNode }, { failed: boolean }> {
  state = { failed: false };
  static getDerivedStateFromError() { return { failed: true }; }
  componentDidCatch(e: unknown) { console.error("[scene] component error:", e); }
  render() { return this.state.failed ? null : this.props.children; }
}
import { HUD } from "./HUD";
import { Minimap } from "./Minimap";
import { PauseMenu } from "./ui/PauseMenu";
import { CharacterMenu } from "./ui/CharacterMenu";
import { BigMap } from "./ui/BigMap";
import { TouchControls } from "./ui/TouchControls";
import { Toasts } from "./ui/Toasts";
import { StartMenu } from "./ui/StartMenu";
import { Radio } from "./audio/Radio";
import { installInput } from "./input";

export default function App() {
  const [sliceName, setSliceName] = useState("loading…");

  useEffect(() => {
    installInput();
  }, []);

  return (
    <>
      <Canvas
        shadows
        camera={{ fov: 60, near: 0.3, far: 1000, position: [0, 10, 24] }}
        dpr={[1, 1.5]}
        gl={{ antialias: false, toneMapping: THREE.ACESFilmicToneMapping, toneMappingExposure: 0.98 }}
      >
        <Suspense fallback={null}>
          <SceneBoundary>
            <Experience onReady={(s) => setSliceName(s.name)} />
          </SceneBoundary>
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
      <StartMenu sliceName={sliceName} />
    </>
  );
}
