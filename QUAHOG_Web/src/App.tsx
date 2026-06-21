import { useEffect, useState } from "react";
import { Canvas } from "@react-three/fiber";
import { Experience } from "./Experience";
import { HUD } from "./HUD";
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
        dpr={[1, 2]}
      >
        <Experience onReady={(s) => setSliceName(s.name)} />
      </Canvas>
      <HUD sliceName={sliceName} />
    </>
  );
}
