import type { Road } from "../slice";

// Water as a barrier (§6 road mechanics): you can't drive/walk across the harbor
// or the Acushnet — except where a bridge road carries you over. Coordinates are
// slice-local [east, north]; a world point (wx, wz) has east=wx, north=-wz.

let waterRings: [number, number][][] = [];
let bridgeSegs: number[] = []; // flattened ax,an,bx,bn,halfWidth, …

export function setWaterZones(water: [number, number][][], roads: Road[]) {
  waterRings = water ?? [];
  bridgeSegs = [];
  for (const r of roads) {
    const hw = r.width / 2 + 4; // generous corridor so you can stay "on the road"
    const isBridge = !!r.bridge;
    for (let i = 0; i < r.points.length - 1; i++) {
      const [ax, an] = r.points[i], [bx, bn] = r.points[i + 1];
      // A bridge always carries you over. For every other road, only its segments
      // that actually run over a water polygon become crossing corridors — so real
      // causeways/spans the OSM data forgot to tag bridge=yes stay drivable, while
      // open harbour off the road network still blocks you.
      if (isBridge || midInWater((ax + bx) / 2, (an + bn) / 2)) {
        bridgeSegs.push(ax, an, bx, bn, hw);
      }
    }
  }
}

function midInWater(px: number, pn: number): boolean {
  for (const ring of waterRings) if (pointInRing(px, pn, ring)) return true;
  return false;
}

function pointInRing(px: number, pn: number, ring: [number, number][]): boolean {
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const xi = ring[i][0], ni = ring[i][1], xj = ring[j][0], nj = ring[j][1];
    if ((ni > pn) !== (nj > pn) && px < ((xj - xi) * (pn - ni)) / (nj - ni) + xi) inside = !inside;
  }
  return inside;
}

function nearBridge(px: number, pn: number): boolean {
  for (let i = 0; i < bridgeSegs.length; i += 5) {
    const ax = bridgeSegs[i], an = bridgeSegs[i + 1], bx = bridgeSegs[i + 2], bn = bridgeSegs[i + 3], hw = bridgeSegs[i + 4];
    const dx = bx - ax, dn = bn - an;
    const len2 = dx * dx + dn * dn || 1;
    let t = ((px - ax) * dx + (pn - an) * dn) / len2;
    t = Math.max(0, Math.min(1, t));
    const cx = ax + dx * t, cn = an + dn * t;
    if (Math.hypot(px - cx, pn - cn) < hw) return true;
  }
  return false;
}

/** True if this world point is open water you may not cross (not on a bridge). */
export function isBlockedWater(wx: number, wz: number): boolean {
  if (!waterRings.length) return false;
  const px = wx, pn = -wz; // world → slice [east, north]
  if (nearBridge(px, pn)) return false;
  for (const ring of waterRings) if (pointInRing(px, pn, ring)) return true;
  return false;
}
