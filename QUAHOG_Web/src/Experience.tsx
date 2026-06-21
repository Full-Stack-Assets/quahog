import { useEffect, useState } from "react";
import { Physics } from "@react-three/rapier";
import { loadSlice, type Slice } from "./slice";
import { Ground } from "./world/Ground";
import { Roads } from "./world/Roads";
import { Buildings } from "./world/Buildings";
import { Landmarks } from "./world/Landmarks";
import { Player } from "./actors/Player";
import { Car } from "./actors/Car";
import { FollowCamera } from "./actors/FollowCamera";

export function Experience({ onReady }: { onReady?: (s: Slice) => void }) {
  const [slice, setSlice] = useState<Slice | null>(null);

  useEffect(() => {
    let alive = true;
    loadSlice()
      .then((s) => {
        if (!alive) return;
        setSlice(s);
        onReady?.(s);
      })
      .catch((e) => console.error(e));
    return () => {
      alive = false;
    };
  }, [onReady]);

  return (
    <>
      <color attach="background" args={["#0c0f1a"]} />
      <fog attach="fog" args={["#10131f", 50, 340]} />

      <hemisphereLight args={["#9fb8d8", "#161824", 0.7]} />
      <directionalLight
        position={[60, 90, 40]}
        intensity={1.6}
        color="#ffd9a0"
        castShadow
        shadow-mapSize={[2048, 2048]}
        shadow-camera-near={1}
        shadow-camera-far={400}
        shadow-camera-left={-200}
        shadow-camera-right={200}
        shadow-camera-top={200}
        shadow-camera-bottom={-200}
      />

      <Physics gravity={[0, -9.81, 0]}>
        <Ground />
        <Player />
        <Car />
        {slice && (
          <>
            <Roads roads={slice.roads} />
            <Buildings buildings={slice.buildings} />
            <Landmarks landmarks={slice.landmarks} />
          </>
        )}
      </Physics>

      <FollowCamera />
    </>
  );
}
