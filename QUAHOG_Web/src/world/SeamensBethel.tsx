import { useMemo } from "react";
import * as THREE from "three";
import { Text } from "@react-three/drei";
import { CuboidCollider, RigidBody } from "@react-three/rapier";
import { toWorld } from "../slice";
import type { Landmark } from "../slice";

// Hand-detailed hero landmark: the Seamen's Bethel ("Whaleman's Chapel", 1832) on
// Johnny Cake Hill — a white New England clapboard chapel with a gable front,
// square belfry + spire, arched windows, and double doors over stone steps.
// Built procedurally from primitives; front facade faces +x (the approach).

const WHITE = "#eae6dc";
const TRIM = "#f3f0e8";
const ROOF = "#2e2e33";
const STONE = "#8c8a84";
const DOOR = "#3a281a";
const GLASS = "#ffdda0";

export function SeamensBethel({ landmark }: { landmark: Landmark }) {
  const [wx, , wz] = toWorld(landmark.pos);

  // Gable roof as a triangular prism (ridge runs front→back along x).
  const roofGeom = useMemo(() => {
    const tri = new THREE.Shape();
    tri.moveTo(-6.3, 7.5);
    tri.lineTo(6.3, 7.5);
    tri.lineTo(0, 10.8);
    tri.closePath();
    const g = new THREE.ExtrudeGeometry(tri, { depth: 19, bevelEnabled: false });
    g.rotateY(Math.PI / 2); // extrude axis (z) -> world x
    g.translate(-9.5, 0, 0); // center along x
    g.computeVertexNormals();
    return g;
  }, []);

  return (
    <RigidBody type="fixed" colliders={false} position={[wx, 0, wz]}>
      {/* solid mass collider (body + eaves) */}
      <CuboidCollider args={[9.2, 4, 6.2]} position={[0, 4, 0]} />

      {/* foundation */}
      <mesh position={[0, 0.25, 0]} receiveShadow castShadow>
        <boxGeometry args={[18.8, 0.5, 12.8]} />
        <meshStandardMaterial color={STONE} roughness={0.95} />
      </mesh>

      {/* main body */}
      <mesh position={[0, 4.0, 0]} castShadow receiveShadow>
        <boxGeometry args={[18, 7, 12]} />
        <meshStandardMaterial color={WHITE} roughness={0.85} />
      </mesh>

      {/* roof */}
      <mesh geometry={roofGeom} castShadow receiveShadow>
        <meshStandardMaterial color={ROOF} roughness={0.8} flatShading />
      </mesh>

      {/* corner pilasters (white trim) */}
      {[
        [9, 6], [9, -6], [-9, 6], [-9, -6],
      ].map(([x, z], i) => (
        <mesh key={i} position={[x, 4, z]} castShadow>
          <boxGeometry args={[0.5, 7.2, 0.5]} />
          <meshStandardMaterial color={TRIM} roughness={0.8} />
        </mesh>
      ))}

      {/* belfry tower on the front peak */}
      <mesh position={[8, 12.3, 0]} castShadow>
        <boxGeometry args={[2.6, 3, 2.6]} />
        <meshStandardMaterial color={WHITE} roughness={0.85} />
      </mesh>
      {/* belfry louvered openings (dark insets) */}
      {[
        [9.32, 0, Math.PI / 2],
        [6.68, 0, Math.PI / 2],
        [8, 1.31, 0],
        [8, -1.31, 0],
      ].map(([x, z, ry], i) => (
        <mesh key={i} position={[x, 12.3, z]} rotation-y={ry}>
          <boxGeometry args={[0.1, 1.8, 1.4]} />
          <meshStandardMaterial color="#20242c" roughness={0.6} />
        </mesh>
      ))}
      {/* spire */}
      <mesh position={[8, 15.4, 0]} rotation-y={Math.PI / 4} castShadow>
        <coneGeometry args={[1.95, 3.2, 4]} />
        <meshStandardMaterial color={ROOF} roughness={0.7} flatShading />
      </mesh>
      <mesh position={[8, 17.2, 0]} castShadow>
        <sphereGeometry args={[0.22, 8, 8]} />
        <meshStandardMaterial color="#d8c270" metalness={0.6} roughness={0.3} />
      </mesh>

      {/* double doors on the front facade */}
      <mesh position={[9.02, 2.0, 0]} castShadow>
        <boxGeometry args={[0.25, 3, 2.4]} />
        <meshStandardMaterial color={DOOR} roughness={0.7} />
      </mesh>
      <mesh position={[9.05, 3.5, 0]}>
        <boxGeometry args={[0.2, 0.6, 2.8]} />
        <meshStandardMaterial color={TRIM} roughness={0.8} />
      </mesh>

      {/* stone steps */}
      {[0, 1, 2].map((i) => (
        <mesh key={i} position={[9.6 + i * 0.5, 0.45 - i * 0.15, 0]} castShadow receiveShadow>
          <boxGeometry args={[0.5, 0.3, 3.6 + i * 0.6]} />
          <meshStandardMaterial color={STONE} roughness={0.95} />
        </mesh>
      ))}

      {/* side windows */}
      {[-4.5, 0, 4.5].map((x) => (
        <ArchWindow key={`r${x}`} position={[x, 3.6, 6.06]} axis="z" />
      ))}
      {[-4.5, 0, 4.5].map((x) => (
        <ArchWindow key={`l${x}`} position={[x, 3.6, -6.06]} axis="z" />
      ))}
      {/* front windows flanking the door */}
      <ArchWindow position={[9.06, 3.6, 3.2]} axis="x" />
      <ArchWindow position={[9.06, 3.6, -3.2]} axis="x" />

      {/* name board over the door */}
      <Text
        position={[9.15, 5.0, 0]}
        rotation-y={Math.PI / 2}
        fontSize={0.5}
        color="#2a2118"
        anchorX="center"
        anchorY="middle"
        maxWidth={6}
        textAlign="center"
      >
        SEAMEN'S BETHEL
      </Text>
    </RigidBody>
  );
}

// A tall arched window: warm-glowing glass with a half-round top.
function ArchWindow({
  position,
  axis,
}: {
  position: [number, number, number];
  axis: "x" | "z";
}) {
  const ry = axis === "x" ? Math.PI / 2 : 0;
  return (
    <group position={position} rotation-y={ry}>
      <mesh>
        <boxGeometry args={[1.2, 2.6, 0.12]} />
        <meshStandardMaterial
          color={GLASS}
          emissive={GLASS}
          emissiveIntensity={0.4}
          roughness={0.3}
        />
      </mesh>
      <mesh position={[0, 1.3, 0]} rotation-x={Math.PI / 2}>
        <cylinderGeometry args={[0.6, 0.6, 0.12, 12, 1, false, 0, Math.PI]} />
        <meshStandardMaterial
          color={GLASS}
          emissive={GLASS}
          emissiveIntensity={0.4}
          roughness={0.3}
        />
      </mesh>
      {/* simple white frame */}
      <mesh position={[0, 0, -0.02]}>
        <boxGeometry args={[1.5, 3.0, 0.08]} />
        <meshStandardMaterial color={TRIM} roughness={0.8} />
      </mesh>
    </group>
  );
}
