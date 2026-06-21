import { useEffect, useMemo, useState } from "react";
import * as THREE from "three";
import { Ground } from "./Ground";

// Drapes a real aerial image over the playable area using the Google Maps
// **Static** API, fetched through our own signed serverless proxy (/api/staticmap)
// so the key/secret stay server-side and the image is same-origin (no CORS taint).
// Falls back silently to the procedural ground if the proxy isn't configured
// (e.g. local `vite dev`, or missing env vars) or the request fails.

const CENTER = { lat: 41.638, lon: -70.919 }; // New Bedford slice center
const ZOOM = 16;
const PX = 1280; // 640 * scale 2

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
    const url =
      `/api/staticmap?center=${CENTER.lat},${CENTER.lon}` +
      `&zoom=${ZOOM}&size=640x640&scale=2&maptype=satellite`;
    const loader = new THREE.TextureLoader();
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
      () => console.warn("[satellite] /api/staticmap unavailable — using procedural ground"),
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
