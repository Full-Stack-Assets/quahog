import { useMemo, useRef } from "react";
import * as THREE from "three";
import { useFrame } from "@react-three/fiber";
import { Character } from "./Character";
import type { Road } from "../slice";

// Ambient "street life" ported from the legacy Unity StreetLife.cs: wandering
// pedestrians + decorative patrol cars. Everything is KINEMATIC (plain meshes,
// no rigid bodies) so it can never shove the player's physics car — exactly the
// constraint the Unity version held. Cars here follow the REAL OSM road network.

const PED_COUNT = 12;
const PED_SPEED = 1.5; // m/s
const PED_WANDER = 32; // half-extent of wander box around origin
const CAR_COUNT = 8;
const CAR_SPEED = 9; // m/s
const CONNECT_R = 10; // how close road endpoints must be to count as joined

const DRIVABLE = new Set([
  "motorway", "trunk", "primary", "secondary", "tertiary",
  "residential", "unclassified", "living_street", "service",
]);

const PED_COLORS = ["#c0563f", "#3f6cc0", "#4a8c52", "#b8a23a", "#7a4a8c", "#c87a3f"];
const PANTS = ["#2c2f3a", "#3a3326", "#23344f", "#4a4a4a", "#5a3a2a"];
const SKINS = ["#caa07a", "#e0b48c", "#a87a52", "#8a5a36", "#d8a87a"];
const HAIRS = ["#2a2018", "#4a3422", "#1a1a1a", "#6a5a3a", "#8a8a8a"];
const CAR_COLORS = ["#9c3a3a", "#2f6f7a", "#caa24a", "#3a5a9c", "#5a5a5a", "#8c6a3a"];

interface Route {
  pts: THREE.Vector3[];
  total: number; // total length
}

// ---------------------------------------------------------------------------

export function StreetLife({
  roads,
  center = [0, 0],
}: {
  roads: Road[];
  center?: [number, number];
}) {
  const routes = useMemo<Route[]>(() => {
    const out: Route[] = [];
    for (const r of roads) {
      if (!DRIVABLE.has(r.highway) || r.points.length < 2) continue;
      const pts = r.points.map(([e, n]) => new THREE.Vector3(e, 0.4, -n));
      let total = 0;
      for (let i = 0; i < pts.length - 1; i++) total += pts[i].distanceTo(pts[i + 1]);
      if (total > 6) out.push({ pts, total });
    }
    return out;
  }, [roads]);

  if (routes.length === 0) return null;
  return (
    <group>
      <Pedestrians center={center} />
      <Traffic routes={routes} />
    </group>
  );
}

// ---------------------------------------------------------------------------
// Pedestrians — wander between random points in a box around the district core.

function Pedestrians({ center }: { center: [number, number] }) {
  const refs = useRef<(THREE.Group | null)[]>([]);
  const state = useRef(
    Array.from({ length: PED_COUNT }, () => {
      const pos = randInBox(center);
      return { pos, goal: randInBox(center), heading: 0, color: pick(PED_COLORS) };
    }),
  );

  useFrame((_, dt) => {
    const step = Math.min(dt, 0.05);
    state.current.forEach((p, i) => {
      const g = refs.current[i];
      if (!g) return;
      const to = new THREE.Vector3().subVectors(p.goal, p.pos);
      to.y = 0;
      if (to.length() < 0.6) {
        p.goal = randInBox(center);
      } else {
        to.normalize();
        p.pos.addScaledVector(to, PED_SPEED * step);
        p.heading = Math.atan2(to.x, to.z);
      }
      g.position.copy(p.pos);
      g.rotation.y = p.heading;
    });
  });

  return (
    <group>
      {state.current.map((p, i) => (
        <group key={i} ref={(el) => (refs.current[i] = el)} position={p.pos}>
          <Character shirt={p.color} pants={pick(PANTS)} skin={pick(SKINS)} hair={pick(HAIRS)} />
        </group>
      ))}
    </group>
  );
}

// ---------------------------------------------------------------------------
// Traffic — cars drive along real road polylines and turn onto a connected road
// at each end (falling back to a U-turn when nothing connects).

function Traffic({ routes }: { routes: Route[] }) {
  const refs = useRef<(THREE.Group | null)[]>([]);
  const state = useRef(
    Array.from({ length: CAR_COUNT }, () => {
      const ri = Math.floor(Math.random() * routes.length);
      return {
        route: ri,
        forward: Math.random() < 0.5,
        dist: Math.random() * routes[ri].total,
        color: pick(CAR_COLORS),
        pos: new THREE.Vector3(),
        heading: 0,
      };
    }),
  );

  useFrame((_, dt) => {
    const step = Math.min(dt, 0.05);
    state.current.forEach((c, i) => {
      const g = refs.current[i];
      if (!g) return;
      const route = routes[c.route];
      c.dist += CAR_SPEED * step;

      if (c.dist >= route.total) {
        // reached the far end — turn onto a connected road if possible
        const end = c.forward ? route.pts[route.pts.length - 1] : route.pts[0];
        const next = pickConnected(routes, c.route, end);
        if (next) {
          c.route = next.idx;
          c.forward = next.forward;
        } else {
          c.forward = !c.forward; // U-turn
        }
        c.dist = 0;
      }

      const along = c.forward ? c.dist : route.total - c.dist;
      const { point, dir } = sampleAlong(routes[c.route], along);
      c.pos.copy(point);
      c.heading = Math.atan2(dir.x, dir.z) + (c.forward ? 0 : Math.PI);
      g.position.copy(c.pos);
      g.rotation.y = c.heading;
    });
  });

  return (
    <group>
      {state.current.map((c, i) => (
        <group key={i} ref={(el) => (refs.current[i] = el)}>
          <mesh castShadow position={[0, 0.5, 0]}>
            <boxGeometry args={[1.7, 0.7, 3.6]} />
            <meshStandardMaterial color={c.color} metalness={0.2} roughness={0.5} />
          </mesh>
          <mesh castShadow position={[0, 1.0, -0.2]}>
            <boxGeometry args={[1.5, 0.55, 1.7]} />
            <meshStandardMaterial color="#1a1a22" roughness={0.4} />
          </mesh>
        </group>
      ))}
    </group>
  );
}

// ---------------------------------------------------------------------------
// helpers

function randInBox(center: [number, number] = [0, 0]) {
  return new THREE.Vector3(
    center[0] + (Math.random() * 2 - 1) * PED_WANDER,
    0,
    center[1] + (Math.random() * 2 - 1) * PED_WANDER,
  );
}
const pick = <T,>(a: T[]) => a[Math.floor(Math.random() * a.length)];

/** Position + unit direction at arc-length `d` along a route (start→end). */
function sampleAlong(route: Route, d: number): { point: THREE.Vector3; dir: THREE.Vector3 } {
  const pts = route.pts;
  let acc = 0;
  for (let i = 0; i < pts.length - 1; i++) {
    const seg = pts[i].distanceTo(pts[i + 1]);
    if (acc + seg >= d || i === pts.length - 2) {
      const t = seg > 1e-4 ? THREE.MathUtils.clamp((d - acc) / seg, 0, 1) : 0;
      const point = new THREE.Vector3().lerpVectors(pts[i], pts[i + 1], t);
      const dir = new THREE.Vector3().subVectors(pts[i + 1], pts[i]).normalize();
      return { point, dir };
    }
    acc += seg;
  }
  return { point: pts[0].clone(), dir: new THREE.Vector3(0, 0, 1) };
}

/** Find a route (not `current`) with an endpoint near `at`; head away from it. */
function pickConnected(routes: Route[], current: number, at: THREE.Vector3) {
  const hits: { idx: number; forward: boolean }[] = [];
  for (let i = 0; i < routes.length; i++) {
    if (i === current) continue;
    const r = routes[i];
    if (r.pts[0].distanceTo(at) < CONNECT_R) hits.push({ idx: i, forward: true });
    else if (r.pts[r.pts.length - 1].distanceTo(at) < CONNECT_R)
      hits.push({ idx: i, forward: false });
  }
  return hits.length ? hits[Math.floor(Math.random() * hits.length)] : null;
}
