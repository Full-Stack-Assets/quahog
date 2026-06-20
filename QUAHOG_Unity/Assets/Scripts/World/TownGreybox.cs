using UnityEngine;

namespace Quahog.SouthCoast
{
    /// <summary>
    /// Procedurally builds a small low-poly greybox of a New-England South-Coast
    /// town block entirely from runtime primitives — no prefabs, no editor assets,
    /// no packages. Everything lives under one "Town" root so the integration layer
    /// can move or destroy it as a unit.
    ///
    /// The layout is deterministic (fixed coordinates) so builds are reproducible.
    /// It is intentionally modest in piece/material count because this ships to
    /// WebGL: a handful of shared materials are reused across many objects.
    ///
    /// Coordinate convention: X = east/west, Z = north/south, Y = up. The waterfront
    /// runs along the +Z (north) edge; the plaza sits near the world origin.
    /// </summary>
    public class TownGreybox : MonoBehaviour
    {
        // ---- Public API the integration layer depends on (exact members). ----

        /// <summary>A sensible on-ground standing spot in the plaza, ~1m above ground.</summary>
        public Vector3 PlayerSpawn { get; private set; }

        /// <summary>A spot on a street near the plaza, ~0.5m above ground (for a vehicle).</summary>
        public Vector3 VehicleSpawn { get; private set; }

        // ---- Shared materials (created once, reused to keep draw/material count low). ----

        private Material _matGrass;   // ground
        private Material _matRoad;    // asphalt road strips + plaza
        private Material _matWater;   // waterfront
        private Material _matWood;    // pier + crates
        private Material _matMetal;   // lamp posts

        // A tiny coastal-clapboard palette for the buildings (whites/greys/muted red+blue).
        private Material[] _buildingMats;

        // Ground top sits at y = 0 so spawns can be expressed simply.
        private const float GroundTopY = 0f;

        /// <summary>
        /// Construct the entire town and return the component on the "Town" root.
        /// </summary>
        public static TownGreybox Build()
        {
            var root = new GameObject("Town");
            var town = root.AddComponent<TownGreybox>();
            town.BuildInternal();
            return town;
        }

        private void BuildInternal()
        {
            CreateMaterials();
            BuildGround();
            BuildRoads();
            BuildBuildings();
            BuildWaterfront();
            BuildProps();

            // Plaza centre is at the origin; stand the player there, 1m up.
            PlayerSpawn  = new Vector3(0f, GroundTopY + 1f, 0f);
            // Put the vehicle on the north-south street just west of the plaza, 0.5m up.
            VehicleSpawn = new Vector3(-6f, GroundTopY + 0.5f, -4f);
        }

        // -----------------------------------------------------------------
        // Materials
        // -----------------------------------------------------------------

        /// <summary>
        /// Creates a coloured material that works across render pipelines. URP/Lit
        /// reads "_BaseColor"; the legacy Standard shader reads ".color". We set both
        /// so the same material looks right regardless of which shader was found.
        /// </summary>
        private static Material MakeColorMaterial(Color c)
        {
            Shader s = Shader.Find("Universal Render Pipeline/Lit");
            if (s == null) s = Shader.Find("Standard");
            if (s == null) s = Shader.Find("Sprites/Default");

            // Guard against a totally missing shader (e.g. stripped build): fall back
            // to whatever the engine hands us so we never construct a null-shader mat.
            if (s == null)
            {
                Debug.LogWarning("[TownGreybox] No suitable shader found; using fallback magenta.");
                var fallback = new Material(Shader.Find("Hidden/InternalErrorShader"));
                return fallback;
            }

            var m = new Material(s);
            // Set both so it works on URP/Lit ("_BaseColor") or Standard (".color").
            if (m.HasProperty("_BaseColor")) m.SetColor("_BaseColor", c);
            m.color = c;
            return m;
        }

        private void CreateMaterials()
        {
            _matGrass = MakeColorMaterial(new Color(0.34f, 0.42f, 0.30f)); // muted coastal grass
            _matRoad  = MakeColorMaterial(new Color(0.16f, 0.16f, 0.18f)); // dark asphalt
            _matWater = MakeColorMaterial(new Color(0.18f, 0.34f, 0.46f)); // harbour blue
            _matWood  = MakeColorMaterial(new Color(0.45f, 0.34f, 0.24f)); // weathered wood
            _matMetal = MakeColorMaterial(new Color(0.22f, 0.22f, 0.24f)); // dark lamp metal

            _buildingMats = new[]
            {
                MakeColorMaterial(new Color(0.88f, 0.88f, 0.84f)), // clapboard white
                MakeColorMaterial(new Color(0.62f, 0.64f, 0.66f)), // weathered grey
                MakeColorMaterial(new Color(0.55f, 0.24f, 0.22f)), // muted barn red
                MakeColorMaterial(new Color(0.28f, 0.38f, 0.50f)), // muted slate blue
                MakeColorMaterial(new Color(0.78f, 0.74f, 0.66f)), // sandy beige
            };
        }

        // -----------------------------------------------------------------
        // Primitive helpers
        // -----------------------------------------------------------------

        /// <summary>
        /// Spawns a primitive, parents it under the Town root, and positions/scales it.
        /// Cubes/cylinders from CreatePrimitive already carry colliders.
        /// </summary>
        private GameObject Spawn(PrimitiveType type, string name, Vector3 pos, Vector3 scale, Material mat)
        {
            var go = GameObject.CreatePrimitive(type);
            go.name = name;
            go.transform.SetParent(transform, false);
            go.transform.localPosition = pos;
            go.transform.localScale = scale;

            var renderer = go.GetComponent<Renderer>();
            if (renderer != null && mat != null) renderer.sharedMaterial = mat;
            return go;
        }

        // -----------------------------------------------------------------
        // World pieces
        // -----------------------------------------------------------------

        /// <summary>A large flat ground plane with a collider. (Plane is 10x10 units at scale 1.)</summary>
        private void BuildGround()
        {
            // Unity's Plane is 10x10m at scale 1; scale 8 => 80x80m. Its top is at y=0.
            var ground = Spawn(PrimitiveType.Plane, "Ground",
                new Vector3(0f, GroundTopY, 0f),
                new Vector3(8f, 1f, 8f),
                _matGrass);
            // Plane already includes a MeshCollider; nothing more to do.
            _ = ground;
        }

        /// <summary>
        /// A simple road grid: two streets crossing at a plaza near the origin.
        /// Roads are thin flat boxes laid just above the ground so they don't z-fight.
        /// </summary>
        private void BuildRoads()
        {
            const float y = GroundTopY + 0.02f; // a hair above the grass
            const float roadThickness = 0.04f;

            // East-west street running through the origin.
            Spawn(PrimitiveType.Cube, "Street_EW",
                new Vector3(0f, y, 0f),
                new Vector3(60f, roadThickness, 6f),
                _matRoad);

            // North-south street running through the origin.
            Spawn(PrimitiveType.Cube, "Street_NS",
                new Vector3(0f, y, 0f),
                new Vector3(6f, roadThickness, 50f),
                _matRoad);

            // A square plaza at the intersection (slightly raised palette tone reuse).
            Spawn(PrimitiveType.Cube, "Plaza",
                new Vector3(0f, y + 0.01f, 0f),
                new Vector3(12f, roadThickness, 12f),
                _matRoad);
        }

        /// <summary>
        /// Several scaled-box buildings of varying footprint/height along the streets,
        /// in the coastal clapboard palette. Deterministic placement on both sides of
        /// the east-west street, set back from the plaza.
        /// </summary>
        private void BuildBuildings()
        {
            // Each entry: centre X/Z (footprint centre), footprint (w,d), height, palette index.
            // Z = +9 row sits north of the EW street, Z = -9 row sits south of it.
            BuildingSpec[] specs =
            {
                // North side of the east-west street.
                new BuildingSpec(-22f,  10f, 6f, 7f,  8f, 0),
                new BuildingSpec(-13f,   9f, 5f, 6f,  5f, 2),
                new BuildingSpec( 11f,   9f, 7f, 8f, 10f, 1),
                new BuildingSpec( 21f,  10f, 6f, 6f,  6f, 3),

                // South side of the east-west street.
                new BuildingSpec(-21f,  -9f, 7f, 7f,  9f, 4),
                new BuildingSpec(-12f, -10f, 5f, 6f,  5f, 1),
                new BuildingSpec( 12f,  -9f, 6f, 7f,  7f, 0),
                new BuildingSpec( 22f, -10f, 8f, 7f, 12f, 3),
            };

            foreach (var b in specs)
            {
                // Cube is 1m; scale.y = height, centre raised to half-height so it sits on the ground.
                Spawn(PrimitiveType.Cube, "Building",
                    new Vector3(b.X, GroundTopY + b.Height * 0.5f, b.Z),
                    new Vector3(b.Width, b.Height, b.Depth),
                    _buildingMats[b.MatIndex % _buildingMats.Length]);
            }
        }

        /// <summary>
        /// A blue water strip along the north (+Z) edge plus a simple wooden pier
        /// (a deck and a couple of pilings) extending out over it from the plaza.
        /// </summary>
        private void BuildWaterfront()
        {
            // Water surface just below ground level, along the far north edge.
            const float waterZ = 34f;
            Spawn(PrimitiveType.Cube, "Water",
                new Vector3(0f, GroundTopY - 0.05f, waterZ),
                new Vector3(80f, 0.1f, 24f),
                _matWater);

            // Pier deck reaching north from the end of the NS street out over the water.
            const float deckY = GroundTopY + 0.3f;
            Spawn(PrimitiveType.Cube, "Pier_Deck",
                new Vector3(0f, deckY, waterZ - 6f),
                new Vector3(4f, 0.3f, 18f),
                _matWood);

            // A few pilings holding the deck up over the water.
            for (int i = 0; i < 3; i++)
            {
                float pz = (waterZ - 6f) - 6f + i * 6f; // spaced along the deck
                Spawn(PrimitiveType.Cube, "Pier_Piling_L",
                    new Vector3(-1.6f, GroundTopY - 0.4f, pz),
                    new Vector3(0.4f, 1.6f, 0.4f),
                    _matWood);
                Spawn(PrimitiveType.Cube, "Pier_Piling_R",
                    new Vector3(1.6f, GroundTopY - 0.4f, pz),
                    new Vector3(0.4f, 1.6f, 0.4f),
                    _matWood);
            }
        }

        /// <summary>
        /// A few props for scale near the plaza: lamp posts (thin cylinders) at the
        /// plaza corners and a small stack of crates (cubes).
        /// </summary>
        private void BuildProps()
        {
            // Lamp posts at the four plaza corners. Cylinder default height is 2m at
            // scale 1 (it spans -1..+1), so scale.y = 1.6 => a ~3.2m post; raise it
            // so its base meets the ground.
            float[] sx = { -6.5f, 6.5f };
            float[] sz = { -6.5f, 6.5f };
            foreach (float x in sx)
            {
                foreach (float z in sz)
                {
                    Spawn(PrimitiveType.Cylinder, "LampPost",
                        new Vector3(x, GroundTopY + 1.6f, z),
                        new Vector3(0.16f, 1.6f, 0.16f),
                        _matMetal);
                    // Lamp head: a small cube atop the post.
                    Spawn(PrimitiveType.Cube, "LampHead",
                        new Vector3(x, GroundTopY + 3.2f, z),
                        new Vector3(0.4f, 0.3f, 0.4f),
                        _matMetal);
                }
            }

            // A small deterministic stack of crates near the plaza's southeast corner.
            Vector3[] crateOffsets =
            {
                new Vector3(5.0f, 0.5f, -5.0f),
                new Vector3(5.9f, 0.5f, -5.0f),
                new Vector3(5.0f, 0.5f, -5.9f),
                new Vector3(5.45f, 1.4f, -5.45f), // one stacked on top
            };
            foreach (var off in crateOffsets)
            {
                Spawn(PrimitiveType.Cube, "Crate",
                    new Vector3(off.x, GroundTopY + off.y, off.z),
                    new Vector3(0.9f, 0.9f, 0.9f),
                    _matWood);
            }
        }

        /// <summary>Plain data holder describing one greybox building.</summary>
        private struct BuildingSpec
        {
            public readonly float X;
            public readonly float Z;
            public readonly float Width;
            public readonly float Depth;
            public readonly float Height;
            public readonly int MatIndex;

            public BuildingSpec(float x, float z, float width, float depth, float height, int matIndex)
            {
                X = x;
                Z = z;
                Width = width;
                Depth = depth;
                Height = height;
                MatIndex = matIndex;
            }
        }
    }
}
