import { useEffect, useMemo, useState } from "react";
import * as THREE from "three";
import { Ground } from "./Ground";

// Drapes real aerial imagery over the playable area using the Google Maps
// **Static** API, fetched through our own signed serverless proxy (/api/staticmap)
// so the key/secret stay server-side and the image is same-origin (no CORS taint).
// A GRID×GRID block of tiles is fetched at one zoom level (they tile exactly), so
// real aerial covers the core + surrounding neighbourhoods, not just one square.
// Falls back silently to the procedural ground if the proxy isn't configured
// (e.g. local `vite dev`, or missing env vars) or the requests fail.

const CENTER = { lat: 41.638, lon: -70.919 }; // New Bedford slice center
const ZOOM = 16;
const PX = 1280; // 640 * scale 2
const GRID = 3;  // NxN aerial tiles (odd, centred on CENTER) — 3 → ~7km square

interface Tile { tex: THREE.Texture; x: number; z: number; size: number }

export function SatelliteGround({ origin }: { origin?: { lat: number; lon: number } }) {
  const [tiles, setTiles] = useState<Tile[]>([]);

  // metric constants for this latitude
  const geo = useMemo(() => {
    const mLat = 111320;
    const mLon = 111320 * Math.cos((CENTER.lat * Math.PI) / 180);
    const mpp = (156543.03392 * Math.cos((CENTER.lat * Math.PI) / 180)) / 2 ** ZOOM;
    const size = mpp * PX; // square metres covered by one tile
    return { mLat, mLon, size };
  }, []);

  useEffect(() => {
    if (!origin) return;
    const loader = new THREE.TextureLoader();
    let alive = true;
    const half = (GRID - 1) / 2;
    const out: Tile[] = [];
    const { mLat, mLon, size } = geo;
    const dLat = size / mLat;          // tile spacing in degrees
    const dLon = size / mLon;

    for (let gx = -half; gx <= half; gx++) {
      for (let gn = -half; gn <= half; gn++) {
        const lat = CENTER.lat + gn * dLat;
        const lon = CENTER.lon + gx * dLon;
        const url = `/api/staticmap?center=${lat},${lon}&zoom=${ZOOM}&size=640x640&scale=2&maptype=satellite`;
        loader.load(
          url,
          (t) => {
            if (!alive) return;
            t.colorSpace = THREE.SRGBColorSpace;
            t.anisotropy = 8;
            const x = (lon - origin.lon) * mLon;
            const z = -(lat - origin.lat) * mLat;
            out.push({ tex: t, x, z, size });
            setTiles([...out]);
          },
          undefined,
          () => { /* missing proxy / env vars → procedural ground shows through */ },
        );
      }
    }
    return () => { alive = false; };
  }, [origin, geo]);

  return (
    <>
      {/* base: collider + procedural fallback look, always present */}
      <Ground />
      {tiles.map((t, i) => (
        <mesh key={i} position={[t.x, 0.03, t.z]} rotation-x={-Math.PI / 2} receiveShadow>
          <planeGeometry args={[t.size, t.size]} />
          <meshBasicMaterial map={t.tex} toneMapped={false} />
        </mesh>
      ))}
    </>
  );
}
