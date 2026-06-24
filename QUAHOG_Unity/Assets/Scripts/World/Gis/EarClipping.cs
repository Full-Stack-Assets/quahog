using System.Collections.Generic;
using UnityEngine;

namespace Quahog.SouthCoast.Gis
{
    /// <summary>
    /// Ear-clipping triangulator for a simple 2D polygon (no holes). This is the
    /// classic, battle-tested algorithm: it handles convex and concave footprints,
    /// auto-detects winding, and bails gracefully on degenerate input rather than
    /// looping forever. Output indices reference the input array.
    ///
    /// Used to cap building roofs and to fill flat water areas. Inputs are expected
    /// in the XZ plane (Vector2.x = world X, Vector2.y = world Z).
    /// </summary>
    public static class EarClipper
    {
        public static int[] Triangulate(Vector2[] points)
        {
            var indices = new List<int>();
            int n = points.Length;
            if (n < 3) return indices.ToArray();

            // Work on an index list; orient so we always clip a CCW polygon.
            int[] V = new int[n];
            if (SignedArea(points) > 0f)
                for (int v = 0; v < n; v++) V[v] = v;
            else
                for (int v = 0; v < n; v++) V[v] = (n - 1) - v;

            int nv = n;
            int safety = 2 * nv; // guard against non-simple polygons
            for (int v = nv - 1; nv > 2;)
            {
                if ((safety--) <= 0) break; // bad polygon — return what we have

                int u = v; if (nv <= u) u = 0;
                v = u + 1; if (nv <= v) v = 0;
                int w = v + 1; if (nv <= w) w = 0;

                if (Snip(points, u, v, w, nv, V))
                {
                    indices.Add(V[u]);
                    indices.Add(V[v]);
                    indices.Add(V[w]);
                    // Remove vertex v from the working list.
                    for (int s = v, t = v + 1; t < nv; s++, t++) V[s] = V[t];
                    nv--;
                    safety = 2 * nv;
                }
            }
            return indices.ToArray();
        }

        /// <summary>
        /// Triangulate an outer ring with inner holes (courtyards / islands). Each hole
        /// is welded into the outer ring with a "keyhole" bridge — two coincident edges
        /// to a mutually visible outer vertex — producing one simple polygon, which is
        /// then ear-clipped. The merged vertex list (with duplicated bridge vertices) is
        /// returned via <paramref name="merged"/>; the returned indices reference it.
        /// </summary>
        public static int[] Triangulate(Vector2[] outer, IList<Vector2[]> holes, out Vector2[] merged)
        {
            if (holes == null || holes.Count == 0)
            {
                merged = (Vector2[])outer.Clone();
                return Triangulate(merged);
            }

            var poly = new List<Vector2>(EnsureWinding(outer, ccw: true)); // outer CCW

            // Process holes right-to-left; each bridges to the current (growing) polygon.
            var hs = new List<Vector2[]>();
            foreach (var h in holes)
                if (h != null && h.Length >= 3) hs.Add(EnsureWinding(h, ccw: false)); // holes CW
            hs.Sort((a, b) => MaxX(b).CompareTo(MaxX(a)));
            foreach (var hole in hs) BridgeHole(poly, hole);

            merged = poly.ToArray();
            return TriangulateStrict(merged);
        }

        // Reverse a ring if its winding doesn't match the requested orientation.
        private static Vector2[] EnsureWinding(Vector2[] pts, bool ccw)
        {
            bool isCcw = SignedArea(pts) > 0f;
            if (isCcw == ccw) return (Vector2[])pts.Clone();
            int n = pts.Length;
            var r = new Vector2[n];
            for (int i = 0; i < n; i++) r[i] = pts[n - 1 - i];
            return r;
        }

        private static float MaxX(Vector2[] pts)
        {
            float m = float.MinValue;
            foreach (var p in pts) if (p.x > m) m = p.x;
            return m;
        }

        // Weld one hole into the polygon via a bridge to a visible outer vertex.
        private static void BridgeHole(List<Vector2> poly, Vector2[] hole)
        {
            // M = rightmost hole vertex; cast a ray +x from it to find the bridge target.
            int hm = 0;
            for (int i = 1; i < hole.Length; i++) if (hole[i].x > hole[hm].x) hm = i;
            Vector2 M = hole[hm];
            int pIdx = FindVisible(poly, M);

            var insert = new List<Vector2>(hole.Length + 2);
            for (int k = 0; k < hole.Length; k++) insert.Add(hole[(hm + k) % hole.Length]);
            insert.Add(hole[hm]);     // back to M  (closes the hole loop)
            insert.Add(poly[pIdx]);   // back to P  (closes the bridge)
            poly.InsertRange(pIdx + 1, insert);
        }

        // Index of an outer-polygon vertex mutually visible from M (Eberly's method).
        private static int FindVisible(List<Vector2> poly, Vector2 M)
        {
            int n = poly.Count;
            float bestX = float.MaxValue;
            int edgeI = -1;
            for (int i = 0; i < n; i++)
            {
                Vector2 a = poly[i], b = poly[(i + 1) % n];
                if ((a.y > M.y) == (b.y > M.y)) continue;        // edge must straddle M.y
                float t = (M.y - a.y) / (b.y - a.y);
                float ix = a.x + t * (b.x - a.x);
                if (ix < M.x - 1e-6f) continue;                  // and lie to the right
                if (ix < bestX) { bestX = ix; edgeI = i; }
            }
            if (edgeI < 0) return 0; // degenerate input — bridge to vertex 0 rather than fail

            int ia = edgeI, ib = (edgeI + 1) % n;
            Vector2 I = new Vector2(bestX, M.y);
            int pIdx = poly[ia].x >= poly[ib].x ? ia : ib;       // edge endpoint nearer the ray
            if (Same(I, poly[ia])) return ia;
            if (Same(I, poly[ib])) return ib;

            // A reflex vertex inside triangle (M, I, P) can occlude P — pick the one
            // closest to the ray instead.
            Vector2 P = poly[pIdx];
            float best = float.MaxValue;
            int chosen = pIdx;
            for (int i = 0; i < n; i++)
            {
                if (i == pIdx) continue;
                Vector2 R = poly[i];
                if (!PointInTri(M, I, P, R)) continue;
                Vector2 prev = poly[(i - 1 + n) % n], next = poly[(i + 1) % n];
                float cross = (R.x - prev.x) * (next.y - R.y) - (R.y - prev.y) * (next.x - R.x);
                if (cross >= 0f) continue;                        // CCW poly: reflex = cross < 0
                Vector2 rd = R - M; float len = rd.magnitude;
                if (len < 1e-9f) continue;
                float ang = 1f - rd.x / len;                      // smaller = closer to +x ray
                if (ang < best) { best = ang; chosen = i; }
            }
            return chosen;
        }

        private static bool Same(Vector2 a, Vector2 b)
            => Mathf.Abs(a.x - b.x) < 1e-4f && Mathf.Abs(a.y - b.y) < 1e-4f;

        private static bool PointInTri(Vector2 a, Vector2 b, Vector2 c, Vector2 p)
        {
            float d1 = (p.x - b.x) * (a.y - b.y) - (a.x - b.x) * (p.y - b.y);
            float d2 = (p.x - c.x) * (b.y - c.y) - (b.x - c.x) * (p.y - c.y);
            float d3 = (p.x - a.x) * (c.y - a.y) - (c.x - a.x) * (p.y - a.y);
            bool neg = d1 < 0 || d2 < 0 || d3 < 0;
            bool pos = d1 > 0 || d2 > 0 || d3 > 0;
            return !(neg && pos);
        }

        // Ear-clip a simple polygon that may contain zero-width bridge channels: it
        // uses a STRICT interior test and ignores vertices coincident with an ear's
        // corners, so the duplicated bridge vertices don't wrongly block valid ears.
        private static int[] TriangulateStrict(Vector2[] pts)
        {
            var indices = new List<int>();
            int n = pts.Length;
            if (n < 3) return indices.ToArray();

            int[] V = new int[n];
            if (SignedArea(pts) > 0f) for (int v = 0; v < n; v++) V[v] = v;
            else for (int v = 0; v < n; v++) V[v] = (n - 1) - v;

            int nv = n;
            int safety = 4 * nv;
            for (int v = nv - 1; nv > 2;)
            {
                if ((safety--) <= 0) break;

                int u = v; if (nv <= u) u = 0;
                v = u + 1; if (nv <= v) v = 0;
                int w = v + 1; if (nv <= w) w = 0;

                if (SnipStrict(pts, u, v, w, nv, V))
                {
                    indices.Add(V[u]); indices.Add(V[v]); indices.Add(V[w]);
                    for (int s = v, t = v + 1; t < nv; s++, t++) V[s] = V[t];
                    nv--;
                    safety = 4 * nv;
                }
            }
            return indices.ToArray();
        }

        private static bool SnipStrict(Vector2[] pts, int u, int v, int w, int n, int[] V)
        {
            Vector2 A = pts[V[u]], B = pts[V[v]], C = pts[V[w]];
            if (Mathf.Epsilon > ((B.x - A.x) * (C.y - A.y)) - ((B.y - A.y) * (C.x - A.x)))
                return false;
            for (int p = 0; p < n; p++)
            {
                if (p == u || p == v || p == w) continue;
                Vector2 P = pts[V[p]];
                if (Same(P, A) || Same(P, B) || Same(P, C)) continue; // bridge duplicate
                if (StrictInside(A, B, C, P)) return false;
            }
            return true;
        }

        // Strictly interior (boundary excluded) — points on the bridge channel edges
        // sit exactly on a triangle edge and are therefore not "inside".
        private static bool StrictInside(Vector2 A, Vector2 B, Vector2 C, Vector2 P)
        {
            float ax = C.x - B.x, ay = C.y - B.y;
            float bx = A.x - C.x, by = A.y - C.y;
            float cx = B.x - A.x, cy = B.y - A.y;
            float apx = P.x - A.x, apy = P.y - A.y;
            float bpx = P.x - B.x, bpy = P.y - B.y;
            float cpx = P.x - C.x, cpy = P.y - C.y;
            float aCrossBp = ax * bpy - ay * bpx;
            float cCrossAp = cx * apy - cy * apx;
            float bCrossCp = bx * cpy - by * cpx;
            return aCrossBp > 0f && bCrossCp > 0f && cCrossAp > 0f;
        }

        private static float SignedArea(Vector2[] points)
        {
            int n = points.Length;
            float a = 0f;
            for (int p = n - 1, q = 0; q < n; p = q++)
                a += points[p].x * points[q].y - points[q].x * points[p].y;
            return a * 0.5f;
        }

        private static bool Snip(Vector2[] pts, int u, int v, int w, int n, int[] V)
        {
            Vector2 A = pts[V[u]];
            Vector2 B = pts[V[v]];
            Vector2 C = pts[V[w]];

            // Reject reflex / collinear corners.
            if (Mathf.Epsilon > ((B.x - A.x) * (C.y - A.y)) - ((B.y - A.y) * (C.x - A.x)))
                return false;

            // The candidate ear must contain no other vertex.
            for (int p = 0; p < n; p++)
            {
                if (p == u || p == v || p == w) continue;
                if (InsideTriangle(A, B, C, pts[V[p]])) return false;
            }
            return true;
        }

        private static bool InsideTriangle(Vector2 A, Vector2 B, Vector2 C, Vector2 P)
        {
            float ax = C.x - B.x, ay = C.y - B.y;
            float bx = A.x - C.x, by = A.y - C.y;
            float cx = B.x - A.x, cy = B.y - A.y;
            float apx = P.x - A.x, apy = P.y - A.y;
            float bpx = P.x - B.x, bpy = P.y - B.y;
            float cpx = P.x - C.x, cpy = P.y - C.y;

            float aCrossBp = ax * bpy - ay * bpx;
            float cCrossAp = cx * apy - cy * apx;
            float bCrossCp = bx * cpy - by * cpx;
            return aCrossBp >= 0f && bCrossCp >= 0f && cCrossAp >= 0f;
        }
    }
}
