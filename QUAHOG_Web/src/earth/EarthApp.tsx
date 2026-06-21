import { useEffect } from "react";
import * as THREE from "three";
import { Canvas, useThree } from "@react-three/fiber";
import {
  TilesRenderer,
  TilesPlugin,
  GlobeControls,
  TilesAttributionOverlay,
} from "3d-tiles-renderer/r3f";
import { GoogleCloudAuthPlugin } from "3d-tiles-renderer/plugins";
import { WGS84_ELLIPSOID } from "3d-tiles-renderer/three";

// Isolated TEST page: Google Photorealistic 3D Tiles (the real "Google Earth"
// look) over the New Bedford waterfront. The browser fetches tiles directly from
// tile.googleapis.com, so this works regardless of the build container's egress.
//
// Provide a Google Maps API key (Map Tiles API enabled) one of two ways:
//   • URL:  /earth.html?key=YOUR_KEY        (easiest; no rebuild)
//   • Env:  VITE_GOOGLE_MAPS_API_KEY=...     (baked at build time)

const NB_LAT = 41.636;
const NB_LON = -70.9205;

function getApiKey(): string | null {
  const fromUrl = new URLSearchParams(window.location.search).get("key");
  const fromEnv = import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string | undefined;
  return fromUrl || fromEnv || null;
}

// Position the camera in an oblique aerial view over New Bedford (ECEF space).
function FlyToNewBedford() {
  const camera = useThree((s) => s.camera);
  useEffect(() => {
    const d2r = Math.PI / 180;
    const ground = new THREE.Vector3();
    const eye = new THREE.Vector3();
    WGS84_ELLIPSOID.getCartographicToPosition(NB_LAT * d2r, NB_LON * d2r, 0, ground);
    // eye: a bit south and ~1.4 km up, looking back at the city
    WGS84_ELLIPSOID.getCartographicToPosition(
      (NB_LAT - 0.014) * d2r,
      NB_LON * d2r,
      1400,
      eye,
    );
    camera.up.copy(ground).normalize(); // local "up" = ellipsoid normal
    camera.position.copy(eye);
    camera.lookAt(ground);
    camera.updateProjectionMatrix();
  }, [camera]);
  return null;
}

export function EarthApp() {
  const apiKey = typeof window !== "undefined" ? getApiKey() : null;

  if (!apiKey) {
    return <NoKeyNotice />;
  }

  return (
    <>
      <Canvas camera={{ position: [0, 0, 2e7], near: 1, far: 1e8 }}>
        <hemisphereLight args={["#cfe2ff", "#3a3a4a", 1.0]} />
        <directionalLight position={[1, 1, 1]} intensity={1.2} />
        <TilesRenderer key={apiKey}>
          <TilesPlugin plugin={GoogleCloudAuthPlugin} args={[{ apiToken: apiKey }]} />
          <FlyToNewBedford />
        </TilesRenderer>
        <GlobeControls enableDamping />
        <TilesAttributionOverlay />
      </Canvas>
      <Banner />
    </>
  );
}

function Banner() {
  return (
    <div
      style={{
        position: "fixed", top: 12, left: 12, zIndex: 2,
        font: "13px/1.5 'Courier New', monospace", color: "#e7e0ff",
        background: "rgba(5,7,13,.78)", border: "1px solid #2c3a5e",
        borderRadius: 8, padding: "10px 13px", maxWidth: 320, pointerEvents: "none",
      }}
    >
      <b style={{ color: "#7ad9ff" }}>MOUNT HOPE · PHOTOREAL 3D (test)</b>
      <div style={{ opacity: 0.8, marginTop: 4 }}>
        Google Photorealistic 3D Tiles — New Bedford. Drag to orbit, scroll to zoom.
      </div>
    </div>
  );
}

function NoKeyNotice() {
  return (
    <div
      style={{
        position: "fixed", inset: 0, display: "flex", alignItems: "center",
        justifyContent: "center", color: "#e7e0ff", background: "#05070d",
        font: "14px/1.6 'Courier New', monospace", padding: 24, textAlign: "center",
      }}
    >
      <div style={{ maxWidth: 560 }}>
        <h2 style={{ color: "#7ad9ff" }}>Photoreal 3D Tiles — needs a Google API key</h2>
        <p>
          This test renders Google's Photorealistic 3D Tiles of New Bedford. It
          needs a Google Maps Platform API key with the <b>Map Tiles API</b> enabled.
        </p>
        <p style={{ textAlign: "left", background: "#0c0f1a", padding: 12, borderRadius: 8 }}>
          1. Create a key in Google Cloud → enable <b>Map Tiles API</b>.<br />
          2. Restrict it to your site's domain (HTTP referrer).<br />
          3. Open this page as:<br />
          <code style={{ color: "#9fd8ff" }}>/earth.html?key=YOUR_KEY</code><br />
          &nbsp;&nbsp;&nbsp;or set <code>VITE_GOOGLE_MAPS_API_KEY</code> at build time.
        </p>
        <p style={{ opacity: 0.7 }}>
          Note: Google bills per tile session and its terms govern use.
        </p>
      </div>
    </div>
  );
}
