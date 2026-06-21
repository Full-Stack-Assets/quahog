import { useContext, useEffect, useRef, useState } from "react";
import * as THREE from "three";
import { Canvas, useFrame, useThree } from "@react-three/fiber";
import {
  TilesRenderer,
  TilesPlugin,
  GlobeControls,
  TilesAttributionOverlay,
  EastNorthUpFrame,
  TilesRendererContext,
} from "3d-tiles-renderer/r3f";
import { GoogleCloudAuthPlugin } from "3d-tiles-renderer/plugins";
import { WGS84_ELLIPSOID } from "3d-tiles-renderer/three";
import { Character } from "../world/Character";
import { installInput, isDown, moveAxis } from "../input";

// Isolated TEST page: Google Photorealistic 3D Tiles ("Google Earth" look) over
// New Bedford. Two modes:
//   • Orbit — fly around with globe controls
//   • Walk  — drop the Mount Hope character in and walk the photoreal streets
//             (third-person, ground-follow by raycasting the tile meshes)
//
// Browser fetches tiles from tile.googleapis.com directly (container egress N/A).
// Provide a Google Maps key (Map Tiles API) via ?key=YOUR_KEY or VITE_GOOGLE_MAPS_API_KEY.

const NB_LAT = 41.6358;
const NB_LON = -70.9237; // by Seamen's Bethel / the historic waterfront
const WALK_SPEED = 4.5;
const RUN_SPEED = 9;
const CAM_DIST = 8;
const CAM_HEIGHT = 4;

function getApiKey(): string | null {
  const fromUrl = new URLSearchParams(window.location.search).get("key");
  const fromEnv = import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string | undefined;
  return fromUrl || fromEnv || null;
}

function lerpAngle(a: number, b: number, t: number) {
  let d = ((b - a + Math.PI) % (Math.PI * 2)) - Math.PI;
  if (d < -Math.PI) d += Math.PI * 2;
  return a + d * t;
}

// Orbit mode: position the camera obliquely over New Bedford once.
function FlyToNewBedford() {
  const camera = useThree((s) => s.camera);
  useEffect(() => {
    const d2r = Math.PI / 180;
    const ground = new THREE.Vector3();
    const eye = new THREE.Vector3();
    WGS84_ELLIPSOID.getCartographicToPosition(NB_LAT * d2r, NB_LON * d2r, 0, ground);
    WGS84_ELLIPSOID.getCartographicToPosition((NB_LAT - 0.014) * d2r, NB_LON * d2r, 1400, eye);
    camera.up.copy(ground).normalize();
    camera.position.copy(eye);
    camera.lookAt(ground);
    camera.updateProjectionMatrix();
  }, [camera]);
  return null;
}

// Walk mode: a third-person character inside the ENU frame (y-up content group).
// Moves in the local ground plane; height snaps to the photoreal surface via a
// downward raycast against the loaded tile meshes.
function WalkController() {
  const camera = useThree((s) => s.camera);
  const tiles = useContext(TilesRendererContext);
  const char = useRef<THREE.Group>(null);
  const pos = useRef(new THREE.Vector3(0, 40, 0));
  const heading = useRef(0);
  const camYaw = useRef(0);
  const moving = useRef(false);
  const ray = useRef(new THREE.Raycaster());
  const q = useRef(new THREE.Quaternion());

  useFrame((_, dt) => {
    const c = char.current;
    const parent = c?.parent;
    if (!c || !parent) return;
    const step = Math.min(dt, 0.05);

    // camera-relative movement
    const ax = moveAxis();
    const fwd = new THREE.Vector3(Math.sin(camYaw.current), 0, Math.cos(camYaw.current));
    const right = new THREE.Vector3(fwd.z, 0, -fwd.x);
    const dir = new THREE.Vector3().addScaledVector(fwd, ax.y).addScaledVector(right, ax.x);
    const speed = isDown("ShiftLeft") || isDown("ShiftRight") ? RUN_SPEED : WALK_SPEED;
    if (dir.lengthSq() > 1e-4) {
      dir.normalize();
      pos.current.addScaledVector(dir, speed * step);
      heading.current = Math.atan2(dir.x, dir.z);
      moving.current = true;
    } else {
      moving.current = false;
    }

    // ground-follow: raycast down (along ENU up) against the photoreal tiles
    parent.updateWorldMatrix(true, false);
    parent.getWorldQuaternion(q.current);
    const up = new THREE.Vector3(0, 1, 0).applyQuaternion(q.current);
    const worldPos = parent.localToWorld(pos.current.clone());
    ray.current.set(worldPos.clone().addScaledVector(up, 80), up.clone().negate());
    const group = tiles?.group;
    if (group) {
      const hits = ray.current.intersectObject(group, true);
      if (hits.length) {
        const local = parent.worldToLocal(hits[0].point.clone());
        pos.current.y = local.y;
      }
    }

    c.position.copy(pos.current);
    c.rotation.y = heading.current;

    // third-person chase camera (world space)
    camYaw.current = lerpAngle(camYaw.current, heading.current, 1 - Math.exp(-step * 3));
    const off = new THREE.Vector3(
      -Math.sin(camYaw.current) * CAM_DIST,
      CAM_HEIGHT,
      -Math.cos(camYaw.current) * CAM_DIST,
    ).add(pos.current);
    const camWorld = parent.localToWorld(off.clone());
    const look = parent.localToWorld(pos.current.clone().add(new THREE.Vector3(0, 1.4, 0)));
    camera.up.copy(up);
    camera.position.lerp(camWorld, 1 - Math.exp(-step * 5));
    camera.lookAt(look);
  });

  return (
    <group ref={char}>
      <Character skin="#caa07a" shirt="#b23b34" pants="#23344f" moving={() => moving.current} />
    </group>
  );
}

export function EarthApp() {
  const apiKey = typeof window !== "undefined" ? getApiKey() : null;
  const [mode, setMode] = useState<"orbit" | "walk">("orbit");

  useEffect(() => installInput(), []);

  if (!apiKey) return <NoKeyNotice />;

  return (
    <>
      <Canvas camera={{ position: [0, 0, 2e7], near: 0.5, far: 1e8 }}>
        <hemisphereLight args={["#cfe2ff", "#5a5a4a", 1.0]} />
        <directionalLight position={[1, 2, 1]} intensity={1.4} />
        <TilesRenderer key={apiKey}>
          <TilesPlugin plugin={GoogleCloudAuthPlugin} args={[{ apiToken: apiKey }]} />
          {mode === "orbit" ? (
            <>
              <FlyToNewBedford />
              <GlobeControls enableDamping />
            </>
          ) : (
            <EastNorthUpFrame lat={NB_LAT} lon={NB_LON} height={0}>
              {/* ENU is z-up; rotate so the y-up character/content sits upright */}
              <group rotation={[Math.PI / 2, 0, 0]}>
                <WalkController />
              </group>
            </EastNorthUpFrame>
          )}
          <TilesAttributionOverlay />
        </TilesRenderer>
      </Canvas>
      <Hud mode={mode} setMode={setMode} />
    </>
  );
}

function Hud({ mode, setMode }: { mode: "orbit" | "walk"; setMode: (m: "orbit" | "walk") => void }) {
  const btn = (active: boolean): React.CSSProperties => ({
    pointerEvents: "auto", cursor: "pointer", border: "1px solid #2c3a5e",
    background: active ? "#7ad9ff" : "rgba(5,7,13,.8)", color: active ? "#04121a" : "#e7e0ff",
    font: "12px 'Courier New', monospace", fontWeight: 700, padding: "6px 12px", borderRadius: 6,
  });
  return (
    <div style={{ position: "fixed", inset: 0, pointerEvents: "none", font: "13px/1.5 'Courier New', monospace", color: "#e7e0ff" }}>
      <div style={{ position: "absolute", top: 12, left: 12, background: "rgba(5,7,13,.8)", border: "1px solid #2c3a5e", borderRadius: 8, padding: "10px 13px", maxWidth: 320 }}>
        <b style={{ color: "#7ad9ff" }}>MOUNT HOPE · PHOTOREAL 3D (test)</b>
        <div style={{ opacity: 0.85, marginTop: 4 }}>
          {mode === "orbit"
            ? "Orbit: drag to look, scroll to zoom."
            : "Walk: WASD to move, Shift to run. Camera trails you over the real streets."}
        </div>
        <div style={{ display: "flex", gap: 8, marginTop: 10 }}>
          <button style={btn(mode === "orbit")} onClick={() => setMode("orbit")}>ORBIT</button>
          <button style={btn(mode === "walk")} onClick={() => setMode("walk")}>WALK</button>
        </div>
      </div>
    </div>
  );
}

function NoKeyNotice() {
  return (
    <div style={{ position: "fixed", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", color: "#e7e0ff", background: "#05070d", font: "14px/1.6 'Courier New', monospace", padding: 24, textAlign: "center" }}>
      <div style={{ maxWidth: 560 }}>
        <h2 style={{ color: "#7ad9ff" }}>Photoreal 3D Tiles — needs a Google API key</h2>
        <p>Renders Google's Photorealistic 3D Tiles of New Bedford. Needs a Google Maps Platform key with the <b>Map Tiles API</b> enabled.</p>
        <p style={{ textAlign: "left", background: "#0c0f1a", padding: 12, borderRadius: 8 }}>
          1. Google Cloud → enable <b>Map Tiles API</b>.<br />
          2. Restrict the key to your site's domain.<br />
          3. Open: <code style={{ color: "#9fd8ff" }}>/earth.html?key=YOUR_KEY</code><br />
          &nbsp;&nbsp;&nbsp;or set <code>VITE_GOOGLE_MAPS_API_KEY</code> at build time.
        </p>
        <p style={{ opacity: 0.7 }}>Google bills per tile session and its terms govern use.</p>
      </div>
    </div>
  );
}
