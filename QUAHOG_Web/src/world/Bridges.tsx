import { useMemo } from "react";
import * as THREE from "three";
import { RigidBody } from "@react-three/rapier";
import { makeAsphaltTexture } from "./textures";
import type { Road } from "../slice";

// Drivable elevated bridges (§40). OSM bridge ways are stitched into continuous
// spans, then each span is built as a deck that ramps from grade at the ends up
// to a crest in the middle — with a trimesh collider so you can actually drive
// up and over, side rails, and piers into the water. The water barrier
// (waterZones/Hazards) makes these the only crossings.

const CREST = 7;     // metres at the high point
const RAMP = 26;     // ramp-up length from each shore
const TILE = 8;
const PIER_EVERY = 16;

type Pt = [number, number]; // slice [east, north]

// stitch bridge polylines that share endpoints into longer chains
function stitchSpans(roads: Road[]): { pts: Pt[]; width: number }[] {
  const lines = roads.filter((r) => r.bridge && r.points.length >= 2)
    .map((r) => ({ pts: r.points.slice() as Pt[], width: r.width }));
  const d = (a: Pt, b: Pt) => Math.hypot(a[0] - b[0], a[1] - b[1]);
  const out: { pts: Pt[]; width: number }[] = [];
  while (lines.length) {
    const cur = lines.shift()!;
    let changed = true;
    while (changed) {
      changed = false;
      for (let i = 0; i < lines.length; i++) {
        const l = lines[i];
        const head = cur.pts[0], tail = cur.pts[cur.pts.length - 1];
        if (d(tail, l.pts[0]) < 2) { cur.pts.push(...l.pts.slice(1)); }
        else if (d(tail, l.pts[l.pts.length - 1]) < 2) { cur.pts.push(...l.pts.slice().reverse().slice(1)); }
        else if (d(head, l.pts[l.pts.length - 1]) < 2) { cur.pts.unshift(...l.pts.slice(0, -1)); }
        else if (d(head, l.pts[0]) < 2) { cur.pts.unshift(...l.pts.slice().reverse().slice(0, -1)); }
        else continue;
        cur.width = Math.max(cur.width, l.width);
        lines.splice(i, 1); changed = true; break;
      }
    }
    out.push(cur);
  }
  return out;
}

function rampY(d: number, total: number): number {
  const up = Math.min(d / RAMP, 1), down = Math.min((total - d) / RAMP, 1);
  return CREST * Math.max(0, Math.min(up, down));
}

interface Built { deck: THREE.BufferGeometry; piers: [number, number, number][] }

function buildSpan(pts: Pt[], width: number): Built | null {
  const half = width / 2;
  // cumulative length + per-point height
  const wpt = pts.map(([e, n]) => new THREE.Vector3(e, 0, -n));
  let total = 0; const dist = [0];
  for (let i = 1; i < wpt.length; i++) { total += wpt[i].distanceTo(wpt[i - 1]); dist.push(total); }
  if (total < 4) return null;
  for (let i = 0; i < wpt.length; i++) wpt[i].y = rampY(dist[i], total);

  const pos: number[] = [], uv: number[] = [], idx: number[] = [];
  const piers: [number, number, number][] = [];
  let v = 0, sinceP = 0;
  for (let i = 0; i < wpt.length - 1; i++) {
    const a = wpt[i], b = wpt[i + 1];
    const dx = b.x - a.x, dz = b.z - a.z;
    const segLen = Math.hypot(dx, dz);
    if (segLen < 1e-3) continue;
    const nx = (-dz / segLen) * half, nz = (dx / segLen) * half;
    pos.push(a.x + nx, a.y, a.z + nz, b.x + nx, b.y, b.z + nz, b.x - nx, b.y, b.z - nz, a.x - nx, a.y, a.z - nz);
    const v0 = dist[i] / TILE, v1 = dist[i + 1] / TILE;
    uv.push(0, v0, 0, v1, 1, v1, 1, v0);
    idx.push(v, v + 1, v + 2, v, v + 2, v + 3);
    v += 4;
    sinceP += segLen;
    if (sinceP >= PIER_EVERY && a.y > 1.5) { piers.push([a.x, a.y, a.z]); sinceP = 0; }
  }
  if (!pos.length) return null;
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2));
  g.setIndex(idx);
  g.computeVertexNormals();
  return { deck: g, piers };
}

export function Bridges({ roads }: { roads: Road[] }) {
  const tex = useMemo(() => makeAsphaltTexture(true), []);
  const spans = useMemo(() => stitchSpans(roads).map((s) => buildSpan(s.pts, s.width)).filter(Boolean) as Built[], [roads]);

  return (
    <group>
      {spans.map((s, i) => (
        <group key={i}>
          <RigidBody type="fixed" colliders="trimesh">
            <mesh geometry={s.deck} castShadow receiveShadow>
              <meshStandardMaterial map={tex} color="#74767f" roughness={0.82} side={THREE.DoubleSide} />
            </mesh>
          </RigidBody>
          {s.piers.map((p, k) => (
            <mesh key={k} position={[p[0], p[1] / 2 - 0.75, p[2]]} castShadow>
              <boxGeometry args={[1.1, p[1] + 1.5, 1.1]} />
              <meshStandardMaterial color="#6a5a44" roughness={0.95} />
            </mesh>
          ))}
        </group>
      ))}
    </group>
  );
}
