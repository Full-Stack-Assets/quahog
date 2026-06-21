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

// Hero landmarks (world coords from real lat/lon via the slice origin).
export const BATTLESHIP_COVE: [number, number, number] = [-20273, 0, -7625]; // USS Massachusetts, Fall River
export const LIZZIE_BORDEN: [number, number, number] = [-19599, 0, -7080];   // 92 Second St, Fall River
export const DARTMOUTH_MALL: [number, number, number] = [-3921, 0, 378];     // Route 6, Dartmouth
