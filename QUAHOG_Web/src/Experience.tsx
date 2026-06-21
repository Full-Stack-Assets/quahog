import { useEffect, useState } from "react";
import { Sky } from "@react-three/drei";
import { Physics } from "@react-three/rapier";
import { loadSlice, type Slice } from "./slice";
import { Ground } from "./world/Ground";
import { Roads } from "./world/Roads";
import { Buildings } from "./world/Buildings";
import { Water } from "./world/Water";
import { Landmarks } from "./world/Landmarks";
import { StreetLife } from "./world/StreetLife";
import { SeamensBethel } from "./world/SeamensBethel";
import { Player } from "./actors/Player";
import { Car } from "./actors/Car";
import { FollowCamera } from "./actors/FollowCamera";

// Landmarks rendered as hand-detailed models (so the generic beam/label is skipped).
const MODELED = new Set(["Seamen's Bethel"]);
// Playable core (slice-local east, north) — drives building colliders + ped density.
const CORE: [number, number] = [-266, -100];

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
      {/* daytime, realistic look */}
      <color attach="background" args={["#bcd4ea"]} />
      <fog attach="fog" args={["#c4d6e6", 350, 1400]} />
      <Sky sunPosition={[120, 80, 60]} turbidity={4} rayleigh={1.2} />

      <hemisphereLight args={["#dceaff", "#8a8678", 1.0]} />
      <directionalLight
        position={[120, 160, 80]}
        intensity={2.0}
        color="#fff6e8"
        castShadow
        shadow-mapSize={[2048, 2048]}
        shadow-camera-near={1}
        shadow-camera-far={600}
        shadow-camera-left={-250}
        shadow-camera-right={250}
        shadow-camera-top={250}
        shadow-camera-bottom={-250}
      />

      <Physics gravity={[0, -9.81, 0]}>
        <Ground />
        <Player />
        <Car />
        {slice && (
          <>
            <Roads roads={slice.roads} />
            <Buildings buildings={slice.buildings} center={CORE} />
            {/* generic markers, minus landmarks we hand-model */}
            <Landmarks landmarks={slice.landmarks.filter((l) => !MODELED.has(l.name))} />
            {slice.landmarks
              .filter((l) => l.name === "Seamen's Bethel")
              .map((l, i) => (
                <SeamensBethel key={i} landmark={l} />
              ))}
          </>
        )}
      </Physics>

      {slice && slice.water?.length > 0 && <Water polys={slice.water} />}
      {slice && <StreetLife roads={slice.roads} center={[CORE[0], -CORE[1]]} />}

      <FollowCamera />
    </>
  );
}
