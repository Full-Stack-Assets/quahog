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
