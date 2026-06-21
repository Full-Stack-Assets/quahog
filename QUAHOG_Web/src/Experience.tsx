import { useEffect, useState } from "react";
import { Physics } from "@react-three/rapier";
import { loadSlice, type Slice } from "./slice";
import { useGame } from "./store";
import { SatelliteGround } from "./world/SatelliteGround";
import { Roads } from "./world/Roads";
import { Bridges } from "./world/Bridges";
import { StreamingBuildings } from "./world/StreamingBuildings";
import { Water } from "./world/Water";
import { Landmarks } from "./world/Landmarks";
import { StreetLife } from "./world/StreetLife";
import { SeamensBethel } from "./world/SeamensBethel";
import { Props } from "./world/Props";
import { Awnings } from "./world/Awnings";
import { Crosswalks } from "./world/Crosswalks";
import { UtilityPoles } from "./world/UtilityPoles";
import { Decals } from "./world/Decals";
import { Businesses } from "./world/Businesses";
import { NeonSigns } from "./world/NeonSigns";
import { StreetSigns } from "./world/StreetSigns";
import { TrafficLights } from "./world/TrafficLights";
import { ParkedCars } from "./world/ParkedCars";
import { Posters } from "./world/Posters";
import { Collectibles } from "./world/Collectibles";
import { Race } from "./world/Race";
import { Impacts } from "./world/Impacts";
import { HarborProps } from "./world/HarborProps";
import { Marina } from "./world/Marina";
import { Gulls } from "./world/Gulls";
import { SkidMarks } from "./world/SkidMarks";
import { Rain } from "./world/Rain";
import { Tracers } from "./world/Tracers";
import { Police } from "./world/Police";
import { Consequence } from "./world/Consequence";
import { Hazards } from "./world/Hazards";
import { setWaterZones } from "./world/waterZones";
import { Safehouse } from "./world/Safehouse";
import { Hospital } from "./world/Hospital";
import { Heroes } from "./world/Heroes";
import { Ambient } from "./earth/Ambient";
import { DayNight } from "./world/DayNight";
import { EnvLight } from "./world/EnvLight";
import { GameSystems } from "./world/GameSystems";
import { MissionRunner } from "./world/MissionRunner";
import { Effects } from "./world/Effects";
import { Player } from "./actors/Player";
import { Car } from "./actors/Car";
import { Boat } from "./actors/Boat";
import { FollowCamera } from "./actors/FollowCamera";

// Post-processing, toggleable from settings (§26).
function FxGate() {
  const on = useGame((s) => s.fxOn);
  return on ? <Effects /> : null;
}

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
        useGame.getState().setSlice(s);
        setWaterZones(s.water ?? [], s.roads);
        onReady?.(s);
      })
      .catch((e) => console.error(e));
    return () => {
      alive = false;
    };
  }, [onReady]);

  return (
    <>
      <DayNight />
      <EnvLight />
      <GameSystems />
      <MissionRunner />
      <Consequence />
      <Hazards />

      <Physics gravity={[0, -9.81, 0]}>
        <SatelliteGround origin={slice?.origin} />
        <Player />
        <Car />
        <Boat />
        {slice && (
          <>
            <Roads roads={slice.roads} />
            <Bridges roads={slice.roads} />
            <StreamingBuildings fallback={slice.buildings} center={CORE} />
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
      {slice && slice.water?.length > 0 && (
        <HarborProps polys={slice.water} center={[CORE[0], -CORE[1]]} />
      )}
      <Marina />
      <Gulls />
      {slice && <Props roads={slice.roads} center={[CORE[0], -CORE[1]]} />}
      {slice && <Awnings roads={slice.roads} center={[CORE[0], -CORE[1]]} />}
      {slice && <Crosswalks roads={slice.roads} center={[CORE[0], -CORE[1]]} />}
      {slice && <UtilityPoles roads={slice.roads} center={[CORE[0], -CORE[1]]} />}
      {slice && <Decals roads={slice.roads} center={[CORE[0], -CORE[1]]} />}
      {slice && <StreetSigns roads={slice.roads} center={[CORE[0], -CORE[1]]} />}
      {slice && <TrafficLights roads={slice.roads} center={[CORE[0], -CORE[1]]} />}
      {slice && <ParkedCars roads={slice.roads} center={[CORE[0], -CORE[1]]} />}
      {slice && <StreetLife roads={slice.roads} center={[CORE[0], -CORE[1]]} />}
      <Safehouse />
      <Hospital />
      <Heroes />
      <Businesses />
      <NeonSigns />
      <Collectibles />
      <Race />
      <Posters />
      <Police />
      <Tracers />
      <Impacts />
      <SkidMarks />
      <Rain />
      <Ambient weather="clear" />

      <FollowCamera />
      <FxGate />
    </>
  );
}
