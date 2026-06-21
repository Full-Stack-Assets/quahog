// Fixed civic locations in the slice (world coords: x=east, z=-north).
// Used for respawns and map markers. Picked on inland streets near the core.
//
// POLICE_STATION is now the REAL downtown New Bedford Police Station footprint
// captured in the expanded slice. HOSPITAL is still a stand-in — St. Luke's
// (101 Page St, ~41.6306,-70.9419) sits just west of the current bbox; widen
// the pull westward and re-anchor HOSPITAL to it (see make_slice.py bbox).

export interface Civic { name: string; kind: "hospital" | "police"; pos: [number, number, number] }

export const HOSPITAL: [number, number, number] = [-256.2, 3, 106.5]; // stand-in by the Bethel
export const POLICE_STATION: [number, number, number] = [-513, 3, 147]; // real NB Police Station

export const CIVIC: Civic[] = [
  { name: "St. Luke's Hospital", kind: "hospital", pos: HOSPITAL },
  { name: "New Bedford Police Station", kind: "police", pos: POLICE_STATION },
];
