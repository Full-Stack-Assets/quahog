import { useMemo, useRef } from "react";
import * as THREE from "three";
import { useFrame, useThree } from "@react-three/fiber";
import { makeAsphaltTexture, makeCobbleTexture, makeNoiseNormal, makeGroundTexture } from "./textures";
import { useGame } from "../store";
import type { Road } from "../slice";

const CELL = 1000;       // road chunk size (m)
const DRAW_DIST = 2200;  // hide road chunks beyond this from the camera (open, fog-free view)

// Road classes → surface material. Highways get lane markings; vehicular streets
// get plain asphalt; footways/pedestrian/steps get historic cobblestone.
const HIGHWAY = new Set([
  "motorway", "trunk", "primary",
  "motorway_link", "trunk_link", "primary_link",
]);
const COBBLE = new Set(["footway", "path", "pedestrian", "steps", "cycleway", "track"]);
// Cobblestone historic district — the streets around Johnny Cake Hill / the
// Whaling Historic District (Seamen's Bethel + the hero buildings) are real
// granite-sett cobblestone. Drivable streets whose midpoint falls in this radius
// render on the cobble surface to match the district.
const HIST_CX = -230, HIST_CN = -60, HIST_R = 185;
const TILE = 8; // metres of road per texture repeat along length

// Builds one merged ribbon geometry (with UVs). `uScale` controls cross-width
// texture repeats (cobble repeats across the width; asphalt spans 0..1 for lanes).
function buildRibbon(roads: Road[], y: number, uScale: number, pad = 0, widthScale = 1): THREE.BufferGeometry | null {
  const pos: number[] = [];
  const uv: number[] = [];
  const idx: number[] = [];
  let v = 0;
  for (const r of roads) {
    const half = (r.width * widthScale) / 2 + pad;
    const u = uScale === 0 ? 1 : r.width / uScale; // tiles across the width
    let len = 0;
    for (let i = 0; i < r.points.length - 1; i++) {
      const [ax, an] = r.points[i];
      const [bx, bn] = r.points[i + 1];
      const x1 = ax, z1 = -an, x2 = bx, z2 = -bn;
      const dx = x2 - x1, dz = z2 - z1;
      const segLen = Math.hypot(dx, dz);
      if (segLen < 1e-4) continue;
      const nx = (-dz / segLen) * half;
      const nz = (dx / segLen) * half;
      const v0 = len / TILE;
      const v1 = (len + segLen) / TILE;
      pos.push(
        x1 + nx, y, z1 + nz,
        x2 + nx, y, z2 + nz,
        x2 - nx, y, z2 - nz,
        x1 - nx, y, z1 - nz,
      );
      uv.push(0, v0, 0, v1, u, v1, u, v0);
      idx.push(v, v + 1, v + 2, v, v + 2, v + 3);
      v += 4;
      len += segLen;
    }
  }
  if (pos.length === 0) return null;
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2));
  g.setIndex(idx);
  g.computeVertexNormals();
  return g;
}

export function Roads({ roads }: { roads: Road[] }) {
  const surfaceTex = useMemo(() => makeAsphaltTexture(false), []);
  const highwayTex = useMemo(() => makeAsphaltTexture(true), []);
  const cobbleTex = useMemo(() => {
    const t = makeCobbleTexture();
    t.repeat.set(1, 0.5); // bigger cobbles along length
    return t;
  }, []);
  const nrm = useMemo(() => makeNoiseNormal(), []);
  const ns = useMemo(() => new THREE.Vector2(0.4, 0.4), []);
  const sidewalkTex = useMemo(() => { const t = makeGroundTexture(); t.repeat.set(3, 0.4); return t; }, []);

  // chunk roads into a spatial grid so off-screen/distant cells are culled
  const chunks = useMemo(() => {
    const land = roads.filter((r) => !r.bridge); // bridges handled by <Bridges/>
    const cells = new Map<string, { cb: Road[]; sf: Road[]; hw: Road[]; cx: number; cz: number }>();
    for (const r of land) {
      const mid = r.points[Math.floor(r.points.length / 2)] ?? r.points[0];
      const gx = Math.floor(mid[0] / CELL), gn = Math.floor(mid[1] / CELL);
      const key = `${gx}_${gn}`;
      let c = cells.get(key);
      if (!c) { c = { cb: [], sf: [], hw: [], cx: (gx + 0.5) * CELL, cz: -(gn + 0.5) * CELL }; cells.set(key, c); }
      if (HIGHWAY.has(r.highway)) c.hw.push(r);
      else if (COBBLE.has(r.highway)) c.cb.push(r);
      else if (Math.hypot(mid[0] - HIST_CX, mid[1] - HIST_CN) < HIST_R) c.cb.push(r); // historic cobblestone
      else c.sf.push(r);
    }
    return [...cells.values()].map((c) => ({
      cx: c.cx, cz: c.cz,
      // concrete curb/sidewalk apron under + around the carriageway
      apron: buildRibbon([...c.sf, ...c.hw], 0.04, 0, 2.6),
      cobble: buildRibbon(c.cb, 0.05, 1.2),
      surface: buildRibbon(c.sf, 0.06, 0),
      // trim highway carriageway width a touch so close divided carriageways
      // (e.g. the two directions of I-195) read as separate roads with a median
      // instead of one squished blob; the concrete apron keeps the shoulders.
      highway: buildRibbon(c.hw, 0.08, 0, 0, 0.82),
    }));
  }, [roads]);

  // distance-cull cells + wet-road sheen (rain) via traversal
  const root = useRef<THREE.Group>(null);
  const groups = useRef<(THREE.Group | null)[]>([]);
  const camera = useThree((s) => s.camera);
  useFrame(() => {
    const wet = useGame.getState().weather === "rain" ? 1 : 0;
    const cp = camera.position;
    chunks.forEach((c, i) => {
      const g = groups.current[i];
      if (g) g.visible = Math.hypot(cp.x - c.cx, cp.z - c.cz) < DRAW_DIST;
    });
    if (wet !== lastWet.current) {
      lastWet.current = wet;
      root.current?.traverse((o) => {
        const m = (o as THREE.Mesh).material as THREE.MeshStandardMaterial | undefined;
        if (m?.isMeshStandardMaterial) { m.roughness = (m.userData.base ?? 0.9) - wet * 0.55; m.metalness = wet * 0.5; }
      });
    }
  });
  const lastWet = useRef(-1);

  return (
    <group ref={root}>
      {chunks.map((c, i) => (
        <group key={i} ref={(el) => (groups.current[i] = el)}>
          {c.apron && (
            <mesh geometry={c.apron} receiveShadow>
              <meshStandardMaterial map={sidewalkTex} color="#9a9890" roughness={0.95} userData={{ base: 0.95 }} />
            </mesh>
          )}
          {c.cobble && (
            <mesh geometry={c.cobble} receiveShadow>
              <meshStandardMaterial map={cobbleTex} color="#8a8580" roughness={0.95} userData={{ base: 0.95 }} />
            </mesh>
          )}
          {c.surface && (
            <mesh geometry={c.surface} receiveShadow>
              <meshStandardMaterial map={surfaceTex} normalMap={nrm} normalScale={ns} color="#5a5c66" roughness={0.9} userData={{ base: 0.9 }} polygonOffset polygonOffsetFactor={-1} polygonOffsetUnits={-1} />
            </mesh>
          )}
          {c.highway && (
            <mesh geometry={c.highway} receiveShadow>
              <meshStandardMaterial map={highwayTex} normalMap={nrm} normalScale={ns} color="#6a6c76" roughness={0.82} userData={{ base: 0.82 }} polygonOffset polygonOffsetFactor={-2} polygonOffsetUnits={-2} />
            </mesh>
          )}
        </group>
      ))}
    </group>
  );
}
