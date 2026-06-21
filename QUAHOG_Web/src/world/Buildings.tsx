import { useMemo } from "react";
import * as THREE from "three";
import { mergeGeometries } from "three/examples/jsm/utils/BufferGeometryUtils.js";
import { RigidBody } from "@react-three/rapier";
import type { Building } from "../slice";

// Auto-extruded OSM footprints. Buildings within COLLIDER_RADIUS of the playable
// core get individual hull colliders; the rest are merged into one mesh (no
// collider) so 1000+ footprints stay performant. Colors vary for a real-city mix.

const COLLIDER_RADIUS = 230; // metres from `center`
const HERO = new Set([
  "Seamen's Bethel", "New Bedford Whaling Museum", "Mariner's Home",
  "Double Bank Building", "Rodman Candleworks",
]);
const PALETTE = ["#8a5a48", "#b8b0a0", "#7c7e88", "#a8987e", "#6e4a3e", "#9aa0a6", "#c2bcae"];
const HERO_COLOR = "#caa24a";

function footprintGeometry(b: Building): THREE.BufferGeometry {
  const shape = new THREE.Shape();
  b.footprint.forEach(([e, n], i) => (i === 0 ? shape.moveTo(e, n) : shape.lineTo(e, n)));
  const g = new THREE.ExtrudeGeometry(shape, { depth: b.height, bevelEnabled: false });
  g.rotateX(-Math.PI / 2); // extrude up: x=east, y=up, z=-north
  g.deleteAttribute("uv");
  g.computeVertexNormals();
  return g;
}

function centroid(b: Building): [number, number] {
  let x = 0, y = 0;
  for (const [e, n] of b.footprint) { x += e; y += n; }
  return [x / b.footprint.length, y / b.footprint.length];
}

function colorFor(b: Building, i: number): string {
  if (b.name && HERO.has(b.name)) return HERO_COLOR;
  return PALETTE[i % PALETTE.length];
}

export function Buildings({
  buildings,
  center = [0, 0],
}: {
  buildings: Building[];
  center?: [number, number];
}) {
  // near buildings -> individual colliders; far -> one merged mesh
  const { near, merged } = useMemo(() => {
    const near: { geom: THREE.BufferGeometry; color: string }[] = [];
    const far: THREE.BufferGeometry[] = [];
    buildings.forEach((b, i) => {
      const [cx, cy] = centroid(b);
      const d = Math.hypot(cx - center[0], cy - center[1]);
      const geom = footprintGeometry(b);
      if (d <= COLLIDER_RADIUS) {
        near.push({ geom, color: colorFor(b, i) });
      } else {
        const col = new THREE.Color(colorFor(b, i));
        const n = geom.attributes.position.count;
        const colors = new Float32Array(n * 3);
        for (let k = 0; k < n; k++) colors.set([col.r, col.g, col.b], k * 3);
        geom.setAttribute("color", new THREE.BufferAttribute(colors, 3));
        far.push(geom);
      }
    });
    const merged = far.length ? mergeGeometries(far, false) : null;
    return { near, merged };
  }, [buildings, center]);

  return (
    <group>
      {near.map(({ geom, color }, i) => (
        <RigidBody key={i} type="fixed" colliders="hull">
          <mesh geometry={geom} castShadow receiveShadow>
            <meshStandardMaterial color={color} roughness={0.85} flatShading />
          </mesh>
        </RigidBody>
      ))}
      {merged && (
        <mesh geometry={merged} castShadow receiveShadow>
          <meshStandardMaterial vertexColors roughness={0.85} flatShading />
        </mesh>
      )}
    </group>
  );
}
