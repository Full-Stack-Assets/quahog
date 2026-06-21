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
        private Material _matBuilding;
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
            _matBuilding = MakeColorMaterial(new Color(0.74f, 0.73f, 0.70f)); // weathered clapboard
            _matWater    = MakeColorMaterial(new Color(0.16f, 0.32f, 0.45f)); // harbour blue
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
            var verts = new List<Vector3>();
            var tris = new List<int>();

            foreach (var b in buildings)
            {
                var ring = new List<Vector3>(b.Ring.Count);
                foreach (var ll in b.Ring) ring.Add(Project(ll));
                AddBuilding(ring, b.Height, verts, tris);
            }

            if (verts.Count > 0) Commit("Buildings", verts, tris, _matBuilding, collider: true);
        }

        private static void AddBuilding(List<Vector3> ring, float height,
                                        List<Vector3> verts, List<int> tris)
        {
            // Drop a duplicated closing vertex if present.
            if (ring.Count >= 2 && (ring[0] - ring[ring.Count - 1]).sqrMagnitude < 1e-6f)
                ring.RemoveAt(ring.Count - 1);
            int n = ring.Count;
            if (n < 3) return;

            float top = GroundTopY + height;

            // Footprint centroid for outward-facing wall orientation.
            Vector3 centroid = Vector3.zero;
            for (int i = 0; i < n; i++) centroid += ring[i];
            centroid /= n;

            // Walls.
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

                Vector3 outward = ((a0 + b0) * 0.5f) - centroid;
                outward.y = 0f;
                if (outward.sqrMagnitude < 1e-8f) outward = Vector3.forward;
                outward.Normalize();
                AddQuad(verts, tris, bi, bi + 1, bi + 2, bi + 3, outward);
            }

            // Roof cap (triangulated in XZ, lifted to the top, facing up).
            var poly2d = new Vector2[n];
            for (int i = 0; i < n; i++) poly2d[i] = new Vector2(ring[i].x, ring[i].z);
            int[] idx = EarClipper.Triangulate(poly2d);

            int baseV = verts.Count;
            for (int i = 0; i < n; i++) verts.Add(new Vector3(ring[i].x, top, ring[i].z));
            for (int t = 0; t + 2 < idx.Length; t += 3)
                AddTri(verts, tris, baseV + idx[t], baseV + idx[t + 1], baseV + idx[t + 2], Vector3.up);
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
                if (ring.Count >= 2 && (ring[0] - ring[ring.Count - 1]).sqrMagnitude < 1e-6f)
                    ring.RemoveAt(ring.Count - 1);
                int n = ring.Count;
                if (n < 3) continue;

                var poly2d = new Vector2[n];
                for (int i = 0; i < n; i++) poly2d[i] = new Vector2(ring[i].x, ring[i].z);
                int[] idx = EarClipper.Triangulate(poly2d);

                int baseV = verts.Count;
                for (int i = 0; i < n; i++) verts.Add(new Vector3(ring[i].x, waterY, ring[i].z));
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
