import { useMemo } from "react";
import * as THREE from "three";
import { RigidBody } from "@react-three/rapier";
import type { Building } from "../slice";

// Auto-extruded OSM footprints (the "graybox blockout"). Each building gets a
// convex-hull collider so the player and car can't drive through it.
export function Buildings({ buildings }: { buildings: Building[] }) {
  const meshes = useMemo(() => {
    return buildings.map((b) => {
      const shape = new THREE.Shape();
      // footprint is [east, north]; build in (east, north) then rotate up.
      b.footprint.forEach(([e, n], i) => {
        if (i === 0) shape.moveTo(e, n);
        else shape.lineTo(e, n);
      });
      const geom = new THREE.ExtrudeGeometry(shape, {
        depth: b.height,
        bevelEnabled: false,
      });
      // extrude is along +z; rotate so it stands up: x=east, y=up, z=-north
      geom.rotateX(-Math.PI / 2);
      geom.computeVertexNormals();
      return { geom, hero: !!b.name && HERO.has(b.name) };
    });
  }, [buildings]);

  return (
    <group>
      {meshes.map(({ geom, hero }, i) => (
        <RigidBody key={i} type="fixed" colliders="hull">
          <mesh geometry={geom} castShadow receiveShadow>
            <meshStandardMaterial
              color={hero ? "#caa24a" : "#3a3c4e"}
              emissive={hero ? "#5a3a10" : "#000000"}
              emissiveIntensity={hero ? 0.4 : 0}
              roughness={0.85}
              flatShading
            />
          </mesh>
        </RigidBody>
      ))}
    </group>
  );
}

const HERO = new Set([
  "Seamen's Bethel",
  "New Bedford Whaling Museum",
  "Mariner's Home",
  "Double Bank Building",
  "Rodman Candleworks",
]);
