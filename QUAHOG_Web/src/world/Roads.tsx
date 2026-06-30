import { useMemo, useRef } from "react";
import * as THREE from "three";
import { useFrame, useThree } from "@react-three/fiber";
import { mergeGeometries } from "three/examples/jsm/utils/BufferGeometryUtils.js";
import polygonClipping from "polygon-clipping";
import { makeAsphaltTexture, makeCobbleTexture, makeCobbleNormal, makeNoiseNormal, makeGroundTexture } from "./textures";
import { useGame } from "../store";
import type { Road } from "../slice";

const CELL = 1000;       // road chunk size (m)
const DRAW_DIST = 1500;  // hide road chunks beyond this from the camera

// Road classes → surface material. Highways get lane markings; vehicular streets
// get plain asphalt; footways/pedestrian/steps get historic cobblestone.
const HIGHWAY = new Set([
  "motorway", "trunk", "primary",
  "motorway_link", "trunk_link", "primary_link",
]);
const COBBLE = new Set(["footway", "path", "pedestrian", "steps", "cycleway", "track"]);
// parking-lot aisles / driveways / alleys — thousands of them. Drawn as a quiet,
// darker surface UNDER the real streets (no lane markings, no curb apron, no
// sidewalks) so the map doesn't read as a tangle of equal-weight roads converging.
const SERVICE = new Set(["service"]);
// motorway/trunk/primary on/off ramps — drawn as their own slightly-distinct,
// slightly-raised layer so an interchange reads as mainline + ramps weaving over
// it, not one coplanar converging blob.
const RAMP = new Set(["motorway_link", "trunk_link", "primary_link"]);
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
    // world points (x=east, z=-north)
    const P: [number, number][] = r.points.map(([e, n]) => [e, -n]);
    const m = P.length;
    if (m < 2) continue;
    // per-segment unit direction + left normal + length
    const nrm: [number, number][] = [], seg: number[] = [];
    for (let i = 0; i < m - 1; i++) {
      const dx = P[i + 1][0] - P[i][0], dz = P[i + 1][1] - P[i][1];
      const l = Math.hypot(dx, dz);
      if (l < 1e-6) { nrm.push([0, 0]); seg.push(0); continue; }
      nrm.push([-dz / l, dx / l]); seg.push(l);
    }
    // cumulative length at each vertex (for the lengthwise UV)
    const cum: number[] = [0];
    for (let i = 0; i < m - 1; i++) cum.push(cum[i] + seg[i]);
    // per-vertex MITERED offset: average the adjacent segment normals and scale
    // by 1/cos(half-angle) so the left/right edges stay continuous across a bend
    // instead of each segment overhanging/gapping (the "jutting/converging" look).
    const off: [number, number][] = [];
    for (let i = 0; i < m; i++) {
      if (i === 0) { off.push([nrm[0][0] * half, nrm[0][1] * half]); continue; }
      if (i === m - 1) { off.push([nrm[m - 2][0] * half, nrm[m - 2][1] * half]); continue; }
      let mx = nrm[i - 1][0] + nrm[i][0], mz = nrm[i - 1][1] + nrm[i][1];
      const ml = Math.hypot(mx, mz);
      if (ml < 1e-6) { off.push([nrm[i][0] * half, nrm[i][1] * half]); continue; }
      mx /= ml; mz /= ml;
      const cos = Math.max(mx * nrm[i][0] + mz * nrm[i][1], 0.33); // clamp sharp spikes
      off.push([(mx * half) / cos, (mz * half) / cos]);
    }
    // emit one quad per segment using the shared mitered vertex offsets
    for (let i = 0; i < m - 1; i++) {
      if (seg[i] < 1e-6) continue;
      const v0 = cum[i] / TILE, v1 = cum[i + 1] / TILE;
      const ax = P[i][0], az = P[i][1], bx = P[i + 1][0], bz = P[i + 1][1];
      const oa = off[i], ob = off[i + 1];
      pos.push(
        ax + oa[0], y, az + oa[1],
        bx + ob[0], y, bz + ob[1],
        bx - ob[0], y, bz - ob[1],
        ax - oa[0], y, az - oa[1],
      );
      uv.push(0, v0, 0, v1, u, v1, u, v0);
      idx.push(v, v + 1, v + 2, v, v + 2, v + 3);
      v += 4;
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

// Mitered ribbon quads for one road as closed [e,n] rings (slice coords), for the
// polygon union below. Mirrors buildRibbon's per-vertex miter so the union input
// matches the rest of the road network.
function ribbonQuads(r: Road, widthScale: number): [number, number][][] {
  const half = (r.width * widthScale) / 2;
  const P = r.points, m = P.length;
  const nrm: [number, number][] = [], seg: number[] = [];
  for (let i = 0; i < m - 1; i++) {
    const dx = P[i + 1][0] - P[i][0], dz = P[i + 1][1] - P[i][1];
    const l = Math.hypot(dx, dz);
    if (l < 1e-6) { nrm.push([0, 0]); seg.push(0); continue; }
    nrm.push([-dz / l, dx / l]); seg.push(l);
  }
  const off: [number, number][] = [];
  for (let i = 0; i < m; i++) {
    if (i === 0) { off.push([nrm[0][0] * half, nrm[0][1] * half]); continue; }
    if (i === m - 1) { off.push([nrm[m - 2][0] * half, nrm[m - 2][1] * half]); continue; }
    let mx = nrm[i - 1][0] + nrm[i][0], mz = nrm[i - 1][1] + nrm[i][1];
    const ml = Math.hypot(mx, mz);
    if (ml < 1e-6) { off.push([nrm[i][0] * half, nrm[i][1] * half]); continue; }
    mx /= ml; mz /= ml;
    const cos = Math.max(mx * nrm[i][0] + mz * nrm[i][1], 0.33);
    off.push([(mx * half) / cos, (mz * half) / cos]);
  }
  const out: [number, number][][] = [];
  for (let i = 0; i < m - 1; i++) {
    if (seg[i] < 1e-6) continue;
    const a = P[i], b = P[i + 1], oa = off[i], ob = off[i + 1];
    out.push([
      [a[0] + oa[0], a[1] + oa[1]], [b[0] + ob[0], b[1] + ob[1]],
      [b[0] - ob[0], b[1] - ob[1]], [a[0] - oa[0], a[1] - oa[1]],
      [a[0] + oa[0], a[1] + oa[1]],
    ]);
  }
  return out;
}

// Highways as a *unioned* surface: the divided carriageways + on/off ramps of an
// interchange overlap as many ribbon quads; unioning them merges the overlaps
// into one clean paved polygon (no z-fighting, no jutting corners) while keeping
// genuinely-separate carriageways separate. Triangulated via earcut (handles the
// concave interchange outline + holes). Returns null on any failure so the caller
// falls back to the plain ribbon.
function buildHighwayUnion(roads: Road[], y: number, widthScale: number): THREE.BufferGeometry | null {
  if (!roads.length) return null;
  try {
    const polys: [number, number][][][] = [];
    for (const r of roads) for (const q of ribbonQuads(r, widthScale)) polys.push([q]);
    if (!polys.length) return null;
    const merged = polygonClipping.union(polys[0], ...polys.slice(1));
    const geoms: THREE.BufferGeometry[] = [];
    for (const poly of merged) {
      if (!poly.length || poly[0].length < 4) continue;
      const shape = new THREE.Shape(poly[0].map(([e, n]) => new THREE.Vector2(e, n)));
      for (let h = 1; h < poly.length; h++) {
        if (poly[h].length >= 4) shape.holes.push(new THREE.Path(poly[h].map(([e, n]) => new THREE.Vector2(e, n))));
      }
      const sg = new THREE.ShapeGeometry(shape);
      sg.rotateX(-Math.PI / 2); // (e,n) plane → world (x, 0, -n)
      geoms.push(sg);
    }
    if (!geoms.length) return null;
    const g = mergeGeometries(geoms, false);
    if (!g) return null;
    g.translate(0, y, 0);
    // planar UV (world metres) for the tiling asphalt texture
    const p = g.attributes.position, n = p.count;
    const uv = new Float32Array(n * 2);
    for (let i = 0; i < n; i++) { uv[i * 2] = p.getX(i) / TILE; uv[i * 2 + 1] = p.getZ(i) / TILE; }
    g.setAttribute("uv", new THREE.BufferAttribute(uv, 2));
    g.computeVertexNormals();
    return g;
  } catch {
    return null; // degrade to the ribbon renderer at the call site
  }
}

// Raised curb + sidewalk flanking each street: a top strip at height `top` with
// a short vertical curb face down to grade on the inner (street-facing) edge, on
// both sides of the centerline. Reads as a real walkway instead of flat paint.
function buildSidewalks(roads: Road[], top: number, inner: number, width: number): THREE.BufferGeometry | null {
  const pos: number[] = [], uv: number[] = [], idx: number[] = [];
  let v = 0;
  for (const r of roads) {
    const half = r.width / 2;
    const i0 = half + inner;        // inner (curb) offset from centerline
    const o0 = half + inner + width; // outer edge
    let len = 0;
    for (let i = 0; i < r.points.length - 1; i++) {
      const [ax, an] = r.points[i];
      const [bx, bn] = r.points[i + 1];
      const x1 = ax, z1 = -an, x2 = bx, z2 = -bn;
      const dx = x2 - x1, dz = z2 - z1;
      const segLen = Math.hypot(dx, dz);
      if (segLen < 1e-4) continue;
      const nx = -dz / segLen, nz = dx / segLen; // unit left normal
      const v0 = len / TILE, v1 = (len + segLen) / TILE;
      for (const s of [1, -1]) {
        const ix = nx * i0 * s, iz = nz * i0 * s; // inner offset vector
        const ox = nx * o0 * s, oz = nz * o0 * s; // outer offset vector
        // top strip (inner→outer) at height `top`
        pos.push(x1 + ix, top, z1 + iz, x2 + ix, top, z2 + iz, x2 + ox, top, z2 + oz, x1 + ox, top, z1 + oz);
        uv.push(0, v0, 0, v1, 1, v1, 1, v0);
        idx.push(v, v + 1, v + 2, v, v + 2, v + 3); v += 4;
        // vertical curb face along the inner edge (grade→top), wound to face the street
        const fwd = s === 1 ? 1 : -1; // keep outward-facing winding per side
        pos.push(x1 + ix, 0, z1 + iz, x2 + ix, 0, z2 + iz, x2 + ix, top, z2 + iz, x1 + ix, top, z1 + iz);
        uv.push(0, 0, 0, 1, 1, 1, 1, 0);
        if (fwd === 1) idx.push(v, v + 1, v + 2, v, v + 2, v + 3);
        else idx.push(v, v + 2, v + 1, v, v + 3, v + 2);
        v += 4;
      }
      len += segLen;
    }
  }
  if (!pos.length) return null;
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2));
  g.setIndex(idx);
  g.computeVertexNormals();
  return g;
}

export function Roads({ roads }: { roads: Road[] }) {
  const surfaceTex = useMemo(() => makeAsphaltTexture(false), []);
  const cobbleTex = useMemo(() => {
    const t = makeCobbleTexture();
    t.repeat.set(1, 0.5); // bigger cobbles along length
    return t;
  }, []);
  const cobbleNrm = useMemo(() => { const t = makeCobbleNormal(); t.repeat.set(1, 0.5); return t; }, []);
  const nrm = useMemo(() => makeNoiseNormal(), []);
  const ns = useMemo(() => new THREE.Vector2(0.4, 0.4), []);
  const sidewalkTex = useMemo(() => { const t = makeGroundTexture(); t.repeat.set(3, 0.4); return t; }, []);

  // chunk roads into a spatial grid so off-screen/distant cells are culled
  const chunks = useMemo(() => {
    const land = roads.filter((r) => !r.bridge); // bridges handled by <Bridges/>
    const cells = new Map<string, { cb: Road[]; sf: Road[]; hw: Road[]; rp: Road[]; sv: Road[]; cx: number; cz: number }>();
    for (const r of land) {
      const mid = r.points[Math.floor(r.points.length / 2)] ?? r.points[0];
      const gx = Math.floor(mid[0] / CELL), gn = Math.floor(mid[1] / CELL);
      const key = `${gx}_${gn}`;
      let c = cells.get(key);
      if (!c) { c = { cb: [], sf: [], hw: [], rp: [], sv: [], cx: (gx + 0.5) * CELL, cz: -(gn + 0.5) * CELL }; cells.set(key, c); }
      if (RAMP.has(r.highway)) c.rp.push(r);
      else if (HIGHWAY.has(r.highway)) c.hw.push(r);
      else if (COBBLE.has(r.highway)) c.cb.push(r);
      else if (SERVICE.has(r.highway)) c.sv.push(r);
      else c.sf.push(r);
    }
    return [...cells.values()].map((c) => ({
      cx: c.cx, cz: c.cz,
      // concrete curb/sidewalk apron under + around the carriageway
      apron: buildRibbon([...c.sf, ...c.hw, ...c.rp], 0.04, 0, 2.6),
      // raised curb + walkway flanking ordinary streets (not highways/cobble)
      sidewalk: buildSidewalks(c.sf, 0.14, 0.1, 2.0),
      cobble: buildRibbon(c.cb, 0.05, 1.2),
      // service aisles/driveways: slightly trimmed, drawn just below street level
      service: buildRibbon(c.sv, 0.045, 0, 0, 0.9),
      surface: buildRibbon(c.sf, 0.06, 0),
      // painted centre line down arterials (>=8m: secondary/tertiary) so streets
      // read as real roads, not bare asphalt. Thin ribbon along the centerline.
      centerline: buildRibbon(c.sf.filter((r) => r.width >= 8), 0.066, 0, 0, 0.025),
      // highways: union the carriageway + branch ribbons into clean merged
      // polygons so interchanges stop reading as overlapping/converging ribbons;
      // fall back to a plain ribbon if the union can't be built.
      highway: buildHighwayUnion(c.hw, 0.08, 0.72) ?? buildRibbon(c.hw, 0.08, 0, 0, 0.72),
      // ramps: narrower + a touch higher so they overlay the mainline cleanly
      // where they merge, reading as separate weaving ribbons
      ramp: buildRibbon(c.rp, 0.09, 0, 0, 0.62),
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
              <meshStandardMaterial map={sidewalkTex} normalMap={nrm} normalScale={ns} color="#9a9890" roughness={0.95} userData={{ base: 0.95 }} />
            </mesh>
          )}
          {c.sidewalk && (
            <mesh geometry={c.sidewalk} receiveShadow castShadow>
              <meshStandardMaterial map={sidewalkTex} normalMap={nrm} normalScale={ns} color="#b0aea6" roughness={0.92} userData={{ base: 0.92 }} />
            </mesh>
          )}
          {c.cobble && (
            <mesh geometry={c.cobble} receiveShadow>
              <meshStandardMaterial map={cobbleTex} normalMap={cobbleNrm} normalScale={ns} color="#8a8580" roughness={0.95} userData={{ base: 0.95 }} />
            </mesh>
          )}
          {c.service && (
            <mesh geometry={c.service} receiveShadow>
              <meshStandardMaterial map={surfaceTex} color="#44464d" roughness={0.96} userData={{ base: 0.96 }} polygonOffset polygonOffsetFactor={-0.5} polygonOffsetUnits={-0.5} />
            </mesh>
          )}
          {c.surface && (
            <mesh geometry={c.surface} receiveShadow>
              <meshStandardMaterial map={surfaceTex} normalMap={nrm} normalScale={ns} color="#5a5c66" roughness={0.9} userData={{ base: 0.9 }} polygonOffset polygonOffsetFactor={-1} polygonOffsetUnits={-1} />
            </mesh>
          )}
          {c.centerline && (
            <mesh geometry={c.centerline}>
              <meshStandardMaterial color="#d8b43c" roughness={0.7} emissive="#c8a028" emissiveIntensity={0.15} polygonOffset polygonOffsetFactor={-3} polygonOffsetUnits={-3} />
            </mesh>
          )}
          {c.highway && (
            <mesh geometry={c.highway} receiveShadow>
              <meshStandardMaterial map={surfaceTex} normalMap={nrm} normalScale={ns} color="#6a6c76" roughness={0.82} userData={{ base: 0.82 }} polygonOffset polygonOffsetFactor={-2} polygonOffsetUnits={-2} />
            </mesh>
          )}
          {c.ramp && (
            <mesh geometry={c.ramp} receiveShadow>
              <meshStandardMaterial map={surfaceTex} normalMap={nrm} normalScale={ns} color="#787a84" roughness={0.84} userData={{ base: 0.84 }} polygonOffset polygonOffsetFactor={-3} polygonOffsetUnits={-3} />
            </mesh>
          )}
        </group>
      ))}
    </group>
  );
}
