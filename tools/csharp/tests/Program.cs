// Runnable verification of the project's pure-logic code, executed against the
// UnityEngine shim. Run via tools/csharp/run-tests.sh (passes the sample GeoJSON
// path as arg 0). Exit code is non-zero if any assertion fails.
using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using Quahog.SouthCoast.Gis;

internal static class Program
{
    private static int _passed;
    private static int _failed;

    private static void Check(string name, bool cond)
    {
        if (cond) { _passed++; Console.WriteLine($"  PASS  {name}"); }
        else { _failed++; Console.WriteLine($"  FAIL  {name}"); }
    }

    private static int Main(string[] args)
    {
        Console.WriteLine("=== QUAHOG sandbox tests ===");

        TestMiniJsonAndGeoJson(args);
        TestEarClipper();
        TestGisCityBuild(args);

        Console.WriteLine($"\n=== {_passed} passed, {_failed} failed ===");
        return _failed == 0 ? 0 : 1;
    }

    // ---- GeoJSON parsing -------------------------------------------------
    private static void TestMiniJsonAndGeoJson(string[] args)
    {
        Console.WriteLine("\n[GeoJSON parse]");
        string json = LoadSample(args);
        if (json == null) { Check("sample GeoJSON found", false); return; }
        Check("sample GeoJSON found", true);

        GeoData data = GeoJson.Parse(json);
        // The placeholder New Bedford sample has 6 streets, 8 buildings, 1 water area.
        Check($"roads == 6 (got {data.Roads.Count})", data.Roads.Count == 6);
        Check($"buildings == 8 (got {data.Buildings.Count})", data.Buildings.Count == 8);
        Check($"water == 1 (got {data.Water.Count})", data.Water.Count == 1);

        // Spot-check tag interpretation: the "height":"30" feature should be ~30m,
        // and a "building:levels":"5" feature should be 5 * 3.2 = 16m.
        bool sawTall = false, sawLevels = false;
        foreach (var b in data.Buildings)
        {
            if (Math.Abs(b.Height - 30f) < 0.01f) sawTall = true;
            if (Math.Abs(b.Height - 16f) < 0.01f) sawLevels = true;
        }
        Check("explicit height=30 parsed", sawTall);
        Check("building:levels=5 -> 16m", sawLevels);

        // A primary road should be wider than a residential one.
        float primary = 0, residential = 0;
        foreach (var r in data.Roads)
        {
            if (r.Name == "Union St") primary = r.Width;       // primary
            if (r.Name == "Water St") residential = r.Width;   // residential
        }
        Check($"primary wider than residential ({primary} > {residential})", primary > residential);
    }

    // ---- Ear clipping ----------------------------------------------------
    private static void TestEarClipper()
    {
        Console.WriteLine("\n[Ear clipping]");

        // A convex square -> 2 triangles (6 indices).
        var square = new[]
        {
            new Vector2(0, 0), new Vector2(10, 0), new Vector2(10, 10), new Vector2(0, 10)
        };
        int[] sq = EarClipper.Triangulate(square);
        Check($"square -> 6 indices (got {sq.Length})", sq.Length == 6);
        Check("square indices in range", AllInRange(sq, square.Length));

        // A concave L-shape (6 vertices) -> 4 triangles (12 indices).
        var lshape = new[]
        {
            new Vector2(0, 0), new Vector2(20, 0), new Vector2(20, 10),
            new Vector2(10, 10), new Vector2(10, 20), new Vector2(0, 20)
        };
        int[] ls = EarClipper.Triangulate(lshape);
        Check($"L-shape -> 12 indices (got {ls.Length})", ls.Length == 12);
        Check("L-shape indices in range", AllInRange(ls, lshape.Length));

        // Degenerate (2 points) -> no triangles, no crash.
        int[] degen = EarClipper.Triangulate(new[] { new Vector2(0, 0), new Vector2(1, 1) });
        Check("degenerate -> 0 indices", degen.Length == 0);

        // Clockwise winding still triangulates (auto-orient).
        var cw = new[] { new Vector2(0, 0), new Vector2(0, 10), new Vector2(10, 10), new Vector2(10, 0) };
        Check("clockwise square -> 6 indices", EarClipper.Triangulate(cw).Length == 6);
    }

    // ---- Full GIS city build (smoke) ------------------------------------
    private static void TestGisCityBuild(string[] args)
    {
        Console.WriteLine("\n[GisCity build]");
        string json = LoadSample(args);
        if (json == null) { Check("sample for build", false); return; }

        GisCity city = null;
        Exception err = null;
        try { city = GisCity.Build(json); }
        catch (Exception e) { err = e; }

        Check("GisCity.Build did not throw", err == null);
        if (err != null) { Console.WriteLine("    " + err.Message); return; }
        Check("GisCity.Build returned a city", city != null);
        if (city == null) return;

        // Spawns must be finite and lifted off the ground.
        Check("PlayerSpawn finite", IsFinite(city.PlayerSpawn));
        Check("VehicleSpawn finite", IsFinite(city.VehicleSpawn));
        Check("PlayerSpawn ~1m up", Math.Abs(city.PlayerSpawn.y - 1f) < 0.001f);
        Check("VehicleSpawn ~0.5m up", Math.Abs(city.VehicleSpawn.y - 0.5f) < 0.001f);

        // Empty data should return null (fallback path), not throw.
        GisCity empty = GisCity.Build("{\"type\":\"FeatureCollection\",\"features\":[]}");
        Check("empty FeatureCollection -> null (greybox fallback)", empty == null);
    }

    // ---- helpers ---------------------------------------------------------
    private static bool AllInRange(int[] idx, int n)
    {
        foreach (int i in idx) if (i < 0 || i >= n) return false;
        return true;
    }

    private static bool IsFinite(Vector3 v)
        => !(float.IsNaN(v.x) || float.IsNaN(v.y) || float.IsNaN(v.z)
             || float.IsInfinity(v.x) || float.IsInfinity(v.y) || float.IsInfinity(v.z));

    private static string LoadSample(string[] args)
    {
        if (args != null && args.Length > 0 && File.Exists(args[0])) return File.ReadAllText(args[0]);
        // Fall back to a path relative to the repo layout.
        string guess = Path.Combine(AppContext.BaseDirectory,
            "../../../../../QUAHOG_Unity/Assets/Resources/gis/newbedford.json");
        guess = Path.GetFullPath(guess);
        return File.Exists(guess) ? File.ReadAllText(guess) : null;
    }
}
