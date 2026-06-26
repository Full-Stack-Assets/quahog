using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace Quahog.SouthCoast.Gis
{
    /// <summary>
    /// Builds a map-accurate, low-poly city block from real GIS data (a GeoJSON
    /// FeatureCollection in lon/lat). Roads become flat ribbon meshes; building
    /// footprints are extruded to their tagged height; water areas are filled flat.
    ///
    /// This is a drop-in replacement for <see cref="TownGreybox"/>: it exposes the
    /// same <see cref="PlayerSpawn"/> / <see cref="VehicleSpawn"/> so the bootstrap
    /// can use either interchangeably. Geometry is merged into a few large meshes
    /// (UInt32 indices) to keep WebGL draw calls low.
    ///
    /// Coordinate convention matches the rest of the project: X = east, Z = north,
    /// Y = up, ground top at y = 0. lon/lat are projected with an equirectangular
    /// approximation centred on the dataset — accurate to well under a metre across
    /// a single district.
    /// </summary>
    public class GisCity : MonoBehaviour
    {
        // ---- Public API the integration layer depends on (matches TownGreybox). ----
        public Vector3 PlayerSpawn { get; private set; }
        public Vector3 VehicleSpawn { get; private set; }

        private const float GroundTopY = 0f;

        // Shared materials (a handful, reused across all geometry — WebGL friendly).
        private Material _matGround;
        private Material _matRoad;
        private Material[] _matBuildings; // indexed by (int)BuildingCategory
        private Material _matWater;

        // Equirectangular projection origin + scale.
        private double _lon0, _lat0;
        private double _mPerLon, _mPerLat;

        // World-space bounds of all projected geometry (for the ground plane).
        private float _minX = float.MaxValue, _maxX = float.MinValue;
        private float _minZ = float.MaxValue, _maxZ = float.MinValue;

        /// <summary>
        /// Loads a GeoJSON TextAsset from Resources (e.g. "gis/newbedford" for
        /// Assets/Resources/gis/newbedford.json) and builds the city. Returns null
        /// if the asset is missing or the data can't be built, so the caller can
        /// fall back to the greybox town.
        /// </summary>
        public static GisCity TryBuildFromResources(string resourcePath)
        {
            var ta = Resources.Load<TextAsset>(resourcePath);
            if (ta == null)
            {
                Debug.Log($"[GisCity] No GIS data at Resources/{resourcePath}; falling back to greybox.");
                return null;
            }

            try
            {
                var city = Build(ta.text);
                if (city == null) return null;
                Debug.Log($"[GisCity] Built '{resourcePath}'.");
                return city;
            }
            catch (Exception e)
            {
                Debug.LogError($"[GisCity] Failed to build '{resourcePath}': {e}");
                return null;
            }
        }

        /// <summary>Builds the city from raw GeoJSON text. Returns null on empty data.</summary>
        public static GisCity Build(string geoJsonText)
        {
            GeoData data = GeoJson.Parse(geoJsonText);
            if (data.Roads.Count == 0 && data.Buildings.Count == 0)
            {
                Debug.LogWarning("[GisCity] GeoJSON contained no roads or buildings.");
                return null;
            }

            var root = new GameObject("GisCity");
            var city = root.AddComponent<GisCity>();
            city.BuildInternal(data);
            return city;
        }

        private void BuildInternal(GeoData data)
        {
            CreateMaterials();
            ComputeProjection(data);

            BuildRoads(data.Roads);     // also extends bounds
            BuildBuildings(data.Buildings);
            BuildWater(data.Water);
            BuildGround();              // sized to the bounds gathered above
            ChooseSpawns(data.Roads);
        }

        // -----------------------------------------------------------------
        // Projection
        // -----------------------------------------------------------------

        private void ComputeProjection(GeoData data)
        {
            // Origin = centre of the lon/lat bounding box of all input coordinates.
            double minLon = double.MaxValue, maxLon = double.MinValue;
            double minLat = double.MaxValue, maxLat = double.MinValue;

            void Acc(LonLat p)
            {
                if (p.Lon < minLon) minLon = p.Lon;
                if (p.Lon > maxLon) maxLon = p.Lon;
                if (p.Lat < minLat) minLat = p.Lat;
                if (p.Lat > maxLat) maxLat = p.Lat;
            }

            foreach (var r in data.Roads) foreach (var p in r.Line) Acc(p);
            foreach (var b in data.Buildings) foreach (var p in b.Ring) Acc(p);
            foreach (var w in data.Water) foreach (var p in w.Ring) Acc(p);

            _lon0 = (minLon + maxLon) * 0.5;
            _lat0 = (minLat + maxLat) * 0.5;
            _mPerLat = 111320.0;
            _mPerLon = 111320.0 * Math.Cos(_lat0 * Math.PI / 180.0);
        }

        /// <summary>Projects lon/lat to local metres (X east, Z north) at y = 0.</summary>
        private Vector3 Project(LonLat p)
        {
            float x = (float)((p.Lon - _lon0) * _mPerLon);
            float z = (float)((p.Lat - _lat0) * _mPerLat);
            if (x < _minX) _minX = x;
            if (x > _maxX) _maxX = x;
            if (z < _minZ) _minZ = z;
            if (z > _maxZ) _maxZ = z;
            return new Vector3(x, 0f, z);
        }

        // -----------------------------------------------------------------
        // Materials (cross-pipeline, same approach as TownGreybox)
        // -----------------------------------------------------------------

        private static Material MakeColorMaterial(Color c)
        {
            Shader s = Shader.Find("Universal Render Pipeline/Lit");
            if (s == null) s = Shader.Find("Standard");
            if (s == null) s = Shader.Find("Sprites/Default");
            if (s == null)
            {
                Debug.LogWarning("[GisCity] No suitable shader; using fallback.");
                return new Material(Shader.Find("Hidden/InternalErrorShader"));
            }
            var m = new Material(s);
            if (m.HasProperty("_BaseColor")) m.SetColor("_BaseColor", c);
            m.color = c;
            return m;
        }

        private void CreateMaterials()
        {
            _matGround   = MakeColorMaterial(new Color(0.30f, 0.36f, 0.28f)); // coastal grass/dirt
            _matRoad     = MakeColorMaterial(new Color(0.15f, 0.15f, 0.17f)); // asphalt
            _matWater    = MakeColorMaterial(new Color(0.16f, 0.32f, 0.45f)); // harbour blue

            // Per-category building palettes (New Bedford tones) so blocks read as a
            // mix of clapboard houses, brick storefronts, mills and stone civics
            // instead of one uniform grey.
            _matBuildings = new Material[5];
            _matBuildings[(int)BuildingCategory.Default]     = MakeColorMaterial(new Color(0.74f, 0.73f, 0.70f)); // weathered clapboard
            _matBuildings[(int)BuildingCategory.Residential] = MakeColorMaterial(new Color(0.80f, 0.75f, 0.66f)); // painted clapboard
            _matBuildings[(int)BuildingCategory.Commercial]  = MakeColorMaterial(new Color(0.68f, 0.40f, 0.34f)); // brick storefront
            _matBuildings[(int)BuildingCategory.Industrial]  = MakeColorMaterial(new Color(0.52f, 0.34f, 0.30f)); // dark mill brick
            _matBuildings[(int)BuildingCategory.Civic]       = MakeColorMaterial(new Color(0.74f, 0.72f, 0.67f)); // granite/stone
        }

        // -----------------------------------------------------------------
        // Mesh assembly helpers
        // -----------------------------------------------------------------

        /// <summary>
        /// Adds a triangle whose front face points toward <paramref name="desired"/>.
        /// We test the face normal with the same cross-product Unity's
        /// RecalculateNormals uses, then flip winding if needed — so lighting is
        /// correct regardless of source winding.
        /// </summary>
        private static void AddTri(List<Vector3> verts, List<int> tris, int a, int b, int c, Vector3 desired)
        {
            Vector3 n = Vector3.Cross(verts[b] - verts[a], verts[c] - verts[a]);
            if (Vector3.Dot(n, desired) < 0f) { int t = b; b = c; c = t; }
            tris.Add(a); tris.Add(b); tris.Add(c);
        }

        private static void AddQuad(List<Vector3> verts, List<int> tris,
                                    int a, int b, int c, int d, Vector3 desired)
        {
            AddTri(verts, tris, a, b, c, desired);
            AddTri(verts, tris, a, c, d, desired);
        }

        private GameObject Commit(string name, List<Vector3> verts, List<int> tris,
                                  Material mat, bool collider)
        {
            var go = new GameObject(name);
            go.transform.SetParent(transform, false);

            var mesh = new Mesh { name = name + "_Mesh" };
            if (verts.Count > 65000) mesh.indexFormat = IndexFormat.UInt32;
            mesh.SetVertices(verts);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();

            go.AddComponent<MeshFilter>().sharedMesh = mesh;
            go.AddComponent<MeshRenderer>().sharedMaterial = mat;
            if (collider) go.AddComponent<MeshCollider>().sharedMesh = mesh;
            return go;
        }

        // -----------------------------------------------------------------
        // Roads
        // -----------------------------------------------------------------

        private void BuildRoads(List<RoadFeature> roads)
        {
            var verts = new List<Vector3>();
            var tris = new List<int>();
            const float roadY = GroundTopY + 0.03f; // just above the ground to avoid z-fighting

            foreach (var road in roads)
            {
                var pts = new List<Vector3>(road.Line.Count);
                foreach (var ll in road.Line) pts.Add(Project(ll));
                AddRoadRibbon(pts, road.Width, roadY, verts, tris);
            }

            if (verts.Count > 0) Commit("Roads", verts, tris, _matRoad, collider: false);
        }

        private static void AddRoadRibbon(List<Vector3> pts, float width, float y,
                                          List<Vector3> verts, List<int> tris)
        {
            int n = pts.Count;
            if (n < 2) return;
            float half = width * 0.5f;

            var left = new Vector3[n];
            var right = new Vector3[n];
            for (int i = 0; i < n; i++)
            {
                Vector3 fwd;
                if (i == 0) fwd = pts[1] - pts[0];
                else if (i == n - 1) fwd = pts[n - 1] - pts[n - 2];
                else fwd = pts[i + 1] - pts[i - 1];
                fwd.y = 0f;
                if (fwd.sqrMagnitude < 1e-8f) fwd = Vector3.forward;
                fwd.Normalize();

                Vector3 perp = new Vector3(-fwd.z, 0f, fwd.x); // left of travel
                Vector3 c = new Vector3(pts[i].x, y, pts[i].z);
                left[i] = c + perp * half;
                right[i] = c - perp * half;
            }

            for (int i = 0; i < n - 1; i++)
            {
                int b = verts.Count;
                verts.Add(left[i]); verts.Add(right[i]); verts.Add(right[i + 1]); verts.Add(left[i + 1]);
                AddQuad(verts, tris, b, b + 1, b + 2, b + 3, Vector3.up);
            }
        }

        // -----------------------------------------------------------------
        // Buildings
        // -----------------------------------------------------------------

        private void BuildBuildings(List<BuildingFeature> buildings)
        {
            int cats = _matBuildings.Length;
            var verts = new List<Vector3>[cats];
            var tris = new List<int>[cats];
            for (int i = 0; i < cats; i++) { verts[i] = new List<Vector3>(); tris[i] = new List<int>(); }

            foreach (var b in buildings)
            {
                int ci = (int)b.Category;
                if (ci < 0 || ci >= cats) ci = 0;

                var ring = new List<Vector3>(b.Ring.Count);
                foreach (var ll in b.Ring) ring.Add(Project(ll));

                var holes = new List<List<Vector3>>(b.Holes.Count);
                foreach (var h in b.Holes)
                {
                    var hr = new List<Vector3>(h.Count);
                    foreach (var ll in h) hr.Add(Project(ll));
                    holes.Add(hr);
                }

                AddBuilding(ring, holes, b.Height, verts[ci], tris[ci]);
            }

            // One merged mesh per category (a handful of draw calls, WebGL friendly).
            for (int i = 0; i < cats; i++)
                if (verts[i].Count > 0)
                    Commit("Buildings_" + (BuildingCategory)i, verts[i], tris[i], _matBuildings[i], collider: true);
        }

        private static void AddBuilding(List<Vector3> ring, List<List<Vector3>> holes, float height,
                                        List<Vector3> verts, List<int> tris)
        {
            StripClosing(ring);
            int n = ring.Count;
            if (n < 3) return;

            float top = GroundTopY + height;

            // Outer walls (face outward, away from the footprint centroid).
            Vector3 centroid = Vector3.zero;
            for (int i = 0; i < n; i++) centroid += ring[i];
            centroid /= n;
            AddRingWalls(ring, top, centroid, outward: true, verts, tris);

            // Courtyard (hole) walls (face inward, toward the empty courtyard).
            foreach (var hole in holes)
            {
                StripClosing(hole);
                if (hole.Count < 3) continue;
                Vector3 hc = Vector3.zero;
                for (int i = 0; i < hole.Count; i++) hc += hole[i];
                hc /= hole.Count;
                AddRingWalls(hole, top, hc, outward: false, verts, tris);
            }

            // Roof cap (outer minus holes, triangulated in XZ, lifted to the top).
            var outer2d = new Vector2[n];
            for (int i = 0; i < n; i++) outer2d[i] = new Vector2(ring[i].x, ring[i].z);
            var holes2d = new List<Vector2[]>();
            foreach (var hole in holes)
            {
                if (hole.Count < 3) continue;
                var h2 = new Vector2[hole.Count];
                for (int i = 0; i < hole.Count; i++) h2[i] = new Vector2(hole[i].x, hole[i].z);
                holes2d.Add(h2);
            }

            int[] idx = EarClipper.Triangulate(outer2d, holes2d, out Vector2[] merged);
            int baseV = verts.Count;
            for (int i = 0; i < merged.Length; i++) verts.Add(new Vector3(merged[i].x, top, merged[i].y));
            for (int t = 0; t + 2 < idx.Length; t += 3)
                AddTri(verts, tris, baseV + idx[t], baseV + idx[t + 1], baseV + idx[t + 2], Vector3.up);
        }

        /// <summary>Extrudes one closed ring into vertical walls between ground and top.</summary>
        private static void AddRingWalls(List<Vector3> ring, float top, Vector3 facePoint,
                                         bool outward, List<Vector3> verts, List<int> tris)
        {
            int n = ring.Count;
            for (int i = 0; i < n; i++)
            {
                Vector3 a = ring[i];
                Vector3 b = ring[(i + 1) % n];
                Vector3 a0 = new Vector3(a.x, GroundTopY, a.z);
                Vector3 b0 = new Vector3(b.x, GroundTopY, b.z);
                Vector3 b1 = new Vector3(b.x, top, b.z);
                Vector3 a1 = new Vector3(a.x, top, a.z);

                int bi = verts.Count;
                verts.Add(a0); verts.Add(b0); verts.Add(b1); verts.Add(a1);

                Vector3 mid = (a0 + b0) * 0.5f;
                Vector3 desired = outward ? (mid - facePoint) : (facePoint - mid);
                desired.y = 0f;
                if (desired.sqrMagnitude < 1e-8f) desired = Vector3.forward;
                desired.Normalize();
                AddQuad(verts, tris, bi, bi + 1, bi + 2, bi + 3, desired);
            }
        }

        /// <summary>Drops a duplicated closing vertex (ring[0] == ring[last]) if present.</summary>
        private static void StripClosing(List<Vector3> ring)
        {
            if (ring.Count >= 2 && (ring[0] - ring[ring.Count - 1]).sqrMagnitude < 1e-6f)
                ring.RemoveAt(ring.Count - 1);
        }

        // -----------------------------------------------------------------
        // Water
        // -----------------------------------------------------------------

        private void BuildWater(List<AreaFeature> water)
        {
            if (water.Count == 0) return;
            var verts = new List<Vector3>();
            var tris = new List<int>();
            const float waterY = GroundTopY - 0.05f;

            foreach (var w in water)
            {
                var ring = new List<Vector3>(w.Ring.Count);
                foreach (var ll in w.Ring) ring.Add(Project(ll));
                StripClosing(ring);
                int n = ring.Count;
                if (n < 3) continue;

                var outer2d = new Vector2[n];
                for (int i = 0; i < n; i++) outer2d[i] = new Vector2(ring[i].x, ring[i].z);

                // Inner rings are islands — left unfilled so they read as land in water.
                var holes2d = new List<Vector2[]>();
                foreach (var h in w.Holes)
                {
                    var hr = new List<Vector3>(h.Count);
                    foreach (var ll in h) hr.Add(Project(ll));
                    StripClosing(hr);
                    if (hr.Count < 3) continue;
                    var h2 = new Vector2[hr.Count];
                    for (int i = 0; i < hr.Count; i++) h2[i] = new Vector2(hr[i].x, hr[i].z);
                    holes2d.Add(h2);
                }

                int[] idx = EarClipper.Triangulate(outer2d, holes2d, out Vector2[] merged);
                int baseV = verts.Count;
                for (int i = 0; i < merged.Length; i++) verts.Add(new Vector3(merged[i].x, waterY, merged[i].y));
                for (int t = 0; t + 2 < idx.Length; t += 3)
                    AddTri(verts, tris, baseV + idx[t], baseV + idx[t + 1], baseV + idx[t + 2], Vector3.up);
            }

            if (verts.Count > 0) Commit("Water", verts, tris, _matWater, collider: false);
        }

        // -----------------------------------------------------------------
        // Ground + spawns
        // -----------------------------------------------------------------

        private void BuildGround()
        {
            // If nothing set the bounds, centre a default patch on the origin.
            if (_minX > _maxX) { _minX = -50f; _maxX = 50f; _minZ = -50f; _maxZ = 50f; }

            const float margin = 30f;
            float x0 = _minX - margin, x1 = _maxX + margin;
            float z0 = _minZ - margin, z1 = _maxZ + margin;

            var verts = new List<Vector3>
            {
                new Vector3(x0, GroundTopY, z0),
                new Vector3(x1, GroundTopY, z0),
                new Vector3(x1, GroundTopY, z1),
                new Vector3(x0, GroundTopY, z1),
            };
            var tris = new List<int>();
            AddQuad(verts, tris, 0, 1, 2, 3, Vector3.up);
            Commit("Ground", verts, tris, _matGround, collider: true);
        }

        private void ChooseSpawns(List<RoadFeature> roads)
        {
            // Default: centre of the world, on the ground.
            Vector3 spawn = new Vector3((_minX + _maxX) * 0.5f, GroundTopY, (_minZ + _maxZ) * 0.5f);
            Vector3 along = Vector3.forward;

            // Prefer the midpoint of the longest road so the player/car start on tarmac.
            float bestLen = -1f;
            foreach (var road in roads)
            {
                if (road.Line.Count < 2) continue;
                var a = Project(road.Line[0]);
                var b = Project(road.Line[road.Line.Count - 1]);
                float len = (b - a).sqrMagnitude;
                if (len > bestLen)
                {
                    bestLen = len;
                    spawn = (a + b) * 0.5f;
                    along = (b - a);
                    along.y = 0f;
                    if (along.sqrMagnitude < 1e-6f) along = Vector3.forward;
                    along.Normalize();
                }
            }

            PlayerSpawn = new Vector3(spawn.x, GroundTopY + 1f, spawn.z);
            // Put the car a few metres down the same road from the player.
            Vector3 carPos = spawn + along * 6f;
            VehicleSpawn = new Vector3(carPos.x, GroundTopY + 0.5f, carPos.z);
        }
    }
}
