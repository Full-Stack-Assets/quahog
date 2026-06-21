// Fixed civic locations in the slice (world coords: x=east, z=-north).
// Used for respawns and map markers. Picked on inland streets near the core.
//
// TODO (world build-out): when the OSM slice expands to cover the real sites,
// re-anchor these to the actual buildings —
//   HOSPITAL       → St. Luke's Hospital, 101 Page St (41.6356, -70.9300)
//   POLICE_STATION → New Bedford PD HQ, 871 Rockdale Ave (41.6759, -70.9425)
// (both currently sit north of this waterfront slice, so we use stand-ins.)

export interface Civic { name: string; kind: "hospital" | "police"; pos: [number, number, number] }

export const HOSPITAL: [number, number, number] = [-256.2, 3, 106.5]; // stand-in by the Bethel
export const POLICE_STATION: [number, number, number] = [-205, 3, 150];

export const CIVIC: Civic[] = [
  { name: "St. Luke's Hospital", kind: "hospital", pos: HOSPITAL },
  { name: "Police Station", kind: "police", pos: POLICE_STATION },
];
