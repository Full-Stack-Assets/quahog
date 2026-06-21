// Loader + types for the OSM-derived New Bedford blockout.
// 2D coordinates are [east, north] meters in slice-local space (origin = bbox
// center). In 3D we map east -> +x, north -> -z, up -> +y.

export interface Building {
  footprint: [number, number][];
  height: number;
  name?: string;
}
export interface Road {
  highway: string;
  width: number;
  name: string | null;
  points: [number, number][];
}
export interface Landmark {
  name: string;
  kind: string;
  pos: [number, number];
  hero?: boolean;
}
export interface Slice {
  name: string;
  origin: { lat: number; lon: number };
  buildings: Building[];
  roads: Road[];
  landmarks: Landmark[];
  attribution: string;
}

/** Convert a slice 2D point to a THREE world position tuple (y configurable). */
export const toWorld = (p: [number, number], y = 0): [number, number, number] => [
  p[0],
  y,
  -p[1],
];

export async function loadSlice(url = "slice-newbedford.json"): Promise<Slice> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`failed to load slice: ${res.status}`);
  return (await res.json()) as Slice;
}
