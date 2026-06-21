import { useEffect, useMemo, useState } from "react";
import * as THREE from "three";
import { Ground } from "./Ground";

// Drapes a real aerial image over the playable area using the Google Maps
// **Static** API (a single image request — different API from the 3D tiles that
// were failing). The browser fetches it directly, so the build container's egress
// doesn't matter. Falls back silently to the procedural ground if there's no key,
// or the request/CORS/billing fails.
//
// Provide a key via ?key=YOUR_KEY or VITE_GOOGLE_MAPS_API_KEY.

const CENTER = { lat: 41.638, lon: -70.919 }; // New Bedford slice center
const ZOOM = 16;
const PX = 1280; // 640 * scale 2

function getKey(): string | null {
  if (typeof window === "undefined") return null;
  const u = new URLSearchParams(window.location.search).get("key");
  const e = import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string | undefined;
  return u || e || null;
}

export function SatelliteGround({ origin }: { origin?: { lat: number; lon: number } }) {
  const [tex, setTex] = useState<THREE.Texture | null>(null);

  // metric placement of the image relative to the slice origin
  const placement = useMemo(() => {
    if (!origin) return null;
    const mLat = 111320;
    const mLon = 111320 * Math.cos((CENTER.lat * Math.PI) / 180);
    const mpp = (156543.03392 * Math.cos((CENTER.lat * Math.PI) / 180)) / 2 ** ZOOM;
    const size = mpp * PX; // square meters covered on the ground
    const cx = (CENTER.lon - origin.lon) * mLon;
    const cn = (CENTER.lat - origin.lat) * mLat;
    return { size, x: cx, z: -cn };
  }, [origin]);

  useEffect(() => {
    const key = getKey();
    if (!key) return;
    const url =
      `https://maps.googleapis.com/maps/api/staticmap?center=${CENTER.lat},${CENTER.lon}` +
      `&zoom=${ZOOM}&size=640x640&scale=2&maptype=satellite&key=${key}`;
    const loader = new THREE.TextureLoader();
    loader.setCrossOrigin("anonymous");
    let alive = true;
    loader.load(
      url,
      (t) => {
        if (!alive) return;
        t.colorSpace = THREE.SRGBColorSpace;
        t.anisotropy = 8;
        setTex(t);
      },
      undefined,
      () => console.warn("[satellite] Static Maps image failed (key/billing/CORS) — using procedural ground"),
    );
    return () => { alive = false; };
  }, []);

  return (
    <>
      {/* base: collider + procedural fallback look, always present */}
      <Ground />
      {tex && placement && (
        <mesh position={[placement.x, 0.08, placement.z]} rotation-x={-Math.PI / 2} receiveShadow>
          <planeGeometry args={[placement.size, placement.size]} />
          <meshBasicMaterial map={tex} toneMapped={false} />
        </mesh>
      )}
    </>
  );
}
