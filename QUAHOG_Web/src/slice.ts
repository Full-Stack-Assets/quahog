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
  bridge?: boolean;
  layer?: number;
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
  water: [number, number][][];
  /** Land polygons (small islands/wharves the OSM water didn't cut out). Cut as
   *  holes in the water so they render as land. Optional — may be absent. */
  islands?: [number, number][][];
  /** Hurricane-barrier breakwater polylines (slice metres). Rendered as a stone
   *  dike and registered as drivable corridors over the water. Optional. */
  barrier?: [number, number][][];
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
  const slice = (await res.json()) as Slice;
  // Optional island/wharf land polygons (islands-<name>.json). Absent file is
  // fine — just no holes get cut from the water.
  try {
    const ir = await fetch(url.replace("slice-", "islands-"));
    if (ir.ok) slice.islands = (await ir.json()) as [number, number][][];
  } catch { /* no islands file — leave undefined */ }
  // Optional hurricane-barrier breakwater geometry.
  try {
    const br = await fetch(url.replace("slice-", "barrier-"));
    if (br.ok) slice.barrier = (await br.json()) as [number, number][][];
  } catch { /* no barrier file — leave undefined */ }
  return slice;
}
