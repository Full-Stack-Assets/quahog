using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace Quahog.SouthCoast.Gis
{
    /// <summary>A WGS84 longitude/latitude pair (kept as double until projection).</summary>
    public struct LonLat
    {
        public double Lon;
        public double Lat;
        public LonLat(double lon, double lat) { Lon = lon; Lat = lat; }
    }

    /// <summary>A road centreline plus a metres width derived from its OSM class.</summary>
    public sealed class RoadFeature
    {
        public readonly List<LonLat> Line = new List<LonLat>();
        public float Width = 6f;
        public string Name;
    }

    /// <summary>A building footprint (outer ring) plus an extrusion height in metres.</summary>
    public sealed class BuildingFeature
    {
        public readonly List<LonLat> Ring = new List<LonLat>();
        public float Height = 9f;
    }

    /// <summary>A flat area (e.g. harbour water) defined by an outer ring.</summary>
    public sealed class AreaFeature
    {
        public readonly List<LonLat> Ring = new List<LonLat>();
    }

    /// <summary>The classified contents of one GeoJSON FeatureCollection.</summary>
    public sealed class GeoData
    {
        public readonly List<RoadFeature> Roads = new List<RoadFeature>();
        public readonly List<BuildingFeature> Buildings = new List<BuildingFeature>();
        public readonly List<AreaFeature> Water = new List<AreaFeature>();
    }

    /// <summary>
    /// Parses a standard GeoJSON FeatureCollection (EPSG:4326, lon/lat order) into
    /// typed road / building / water features. It is tolerant: a malformed feature is
    /// skipped rather than aborting the whole import, so a single bad geometry from an
    /// OSM export can't blank the world.
    ///
    /// Recognised tags (OSM-style properties, as exported by overpass-turbo):
    ///   building / building:levels / height  -> building footprint (extruded)
    ///   highway                              -> road centreline (width by class)
    ///   natural=water / water / waterway     -> flat water area
    /// </summary>
    public static class GeoJson
    {
        public static GeoData Parse(string text)
        {
            var data = new GeoData();
            object root = MiniJson.Parse(text);
            var rootObj = root as Dictionary<string, object>;
            if (rootObj == null) return data;

            // Accept either a FeatureCollection or a bare feature array.
            List<object> features = AsList(GetValue(rootObj, "features"));
            if (features == null)
            {
                // Maybe the root is itself a single Feature.
                if (GetValue(rootObj, "geometry") != null)
                    features = new List<object> { rootObj };
                else
                    return data;
            }

            foreach (var f in features)
            {
                try { ParseFeature(f as Dictionary<string, object>, data); }
                catch { /* skip a single malformed feature */ }
            }
            return data;
        }

        private static void ParseFeature(Dictionary<string, object> feature, GeoData data)
        {
            if (feature == null) return;
            var geom = GetValue(feature, "geometry") as Dictionary<string, object>;
            if (geom == null) return;
            var props = GetValue(feature, "properties") as Dictionary<string, object>
                        ?? new Dictionary<string, object>();

            string gtype = GetString(geom, "type");
            object coords = GetValue(geom, "coordinates");
            if (gtype == null || coords == null) return;

            // ---- Building? (polygon-like with a building tag) ----
            if (IsBuilding(props))
            {
                float height = BuildingHeight(props);
                foreach (var ring in OuterRings(gtype, coords))
                {
                    if (ring.Count < 3) continue;
                    var b = new BuildingFeature { Height = height };
                    b.Ring.AddRange(ring);
                    data.Buildings.Add(b);
                }
                return;
            }

            // ---- Road? (line-like with a highway tag) ----
            string highway = GetString(props, "highway");
            if (highway != null)
            {
                float width = RoadWidth(highway);
                foreach (var line in Lines(gtype, coords))
                {
                    if (line.Count < 2) continue;
                    var r = new RoadFeature { Width = width, Name = GetString(props, "name") };
                    r.Line.AddRange(line);
                    data.Roads.Add(r);
                }
                return;
            }

            // ---- Water area? ----
            if (IsWater(props))
            {
                foreach (var ring in OuterRings(gtype, coords))
                {
                    if (ring.Count < 3) continue;
                    var w = new AreaFeature();
                    w.Ring.AddRange(ring);
                    data.Water.Add(w);
                }
            }
        }

        // -----------------------------------------------------------------
        // Geometry coordinate readers
        // -----------------------------------------------------------------

        /// <summary>Outer rings for Polygon / MultiPolygon (inner holes ignored for v1).</summary>
        private static IEnumerable<List<LonLat>> OuterRings(string gtype, object coords)
        {
            if (gtype == "Polygon")
            {
                var rings = AsList(coords);
                if (rings != null && rings.Count > 0)
                    yield return ReadRing(rings[0]);
            }
            else if (gtype == "MultiPolygon")
            {
                var polys = AsList(coords);
                if (polys != null)
                    foreach (var poly in polys)
                    {
                        var rings = AsList(poly);
                        if (rings != null && rings.Count > 0)
                            yield return ReadRing(rings[0]);
                    }
            }
        }

        /// <summary>Polylines for LineString / MultiLineString.</summary>
        private static IEnumerable<List<LonLat>> Lines(string gtype, object coords)
        {
            if (gtype == "LineString")
            {
                yield return ReadRing(coords);
            }
            else if (gtype == "MultiLineString")
            {
                var lines = AsList(coords);
                if (lines != null)
                    foreach (var line in lines)
                        yield return ReadRing(line);
            }
        }

        /// <summary>Reads a list of [lon,lat] pairs.</summary>
        private static List<LonLat> ReadRing(object ringObj)
        {
            var result = new List<LonLat>();
            var pts = AsList(ringObj);
            if (pts == null) return result;
            foreach (var p in pts)
            {
                var pair = AsList(p);
                if (pair == null || pair.Count < 2) continue;
                if (TryNum(pair[0], out double lon) && TryNum(pair[1], out double lat))
                    result.Add(new LonLat(lon, lat));
            }
            return result;
        }

        // -----------------------------------------------------------------
        // Tag interpretation
        // -----------------------------------------------------------------

        private static bool IsBuilding(Dictionary<string, object> props)
        {
            if (!props.TryGetValue("building", out object v) || v == null) return false;
            string s = v as string;
            if (s != null && (s == "no" || s == "false")) return false;
            if (v is bool b && !b) return false;
            return true;
        }

        private static bool IsWater(Dictionary<string, object> props)
        {
            if (string.Equals(GetString(props, "natural"), "water", StringComparison.OrdinalIgnoreCase)) return true;
            if (props.ContainsKey("water")) return true;
            if (props.ContainsKey("waterway")) return true;
            return false;
        }

        private static float BuildingHeight(Dictionary<string, object> props)
        {
            // Explicit metric height wins.
            string hs = GetString(props, "height");
            if (hs != null && double.TryParse(StripUnits(hs), NumberStyles.Float, CultureInfo.InvariantCulture, out double h) && h > 0)
                return Mathf2.Clamp((float)h, 3f, 120f);

            // Else derive from storey count (~3.2 m per level).
            string lvl = GetString(props, "building:levels");
            if (lvl != null && double.TryParse(StripUnits(lvl), NumberStyles.Float, CultureInfo.InvariantCulture, out double levels) && levels > 0)
                return Mathf2.Clamp((float)(levels * 3.2), 3f, 120f);

            return 9f; // ~3 storeys default
        }

        /// <summary>Reasonable carriageway widths (metres) by OSM highway class.</summary>
        private static float RoadWidth(string highway)
        {
            switch (highway)
            {
                case "motorway": case "trunk": return 16f;
                case "primary": return 12f;
                case "secondary": return 10f;
                case "tertiary": return 9f;
                case "residential": case "unclassified": case "living_street": return 7f;
                case "service": return 5f;
                case "pedestrian": return 6f;
                case "footway": case "path": case "cycleway": case "steps": return 2.5f;
                default: return 6f;
            }
        }

        private static string StripUnits(string s)
        {
            // "12 m", "12m", "40'" -> numeric prefix only.
            var sb = new StringBuilder();
            foreach (char c in s)
            {
                if ((c >= '0' && c <= '9') || c == '.' || c == '-') sb.Append(c);
                else break;
            }
            return sb.Length > 0 ? sb.ToString() : s;
        }

        // -----------------------------------------------------------------
        // Small dynamic-tree helpers
        // -----------------------------------------------------------------

        private static object GetValue(Dictionary<string, object> obj, string key)
            => (obj != null && obj.TryGetValue(key, out object v)) ? v : null;

        private static string GetString(Dictionary<string, object> obj, string key)
        {
            object v = GetValue(obj, key);
            if (v == null) return null;
            return v as string ?? Convert.ToString(v, CultureInfo.InvariantCulture);
        }

        private static List<object> AsList(object o) => o as List<object>;

        private static bool TryNum(object o, out double value)
        {
            if (o is double d) { value = d; return true; }
            if (o is int i) { value = i; return true; }
            if (o is string s) return double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out value);
            value = 0;
            return false;
        }
    }

    /// <summary>Tiny clamp helper so this file has no UnityEngine dependency in its logic.</summary>
    internal static class Mathf2
    {
        public static float Clamp(float v, float lo, float hi) => v < lo ? lo : (v > hi ? hi : v);
    }

    /// <summary>
    /// Minimal recursive-descent JSON parser. Returns Dictionary&lt;string,object&gt;,
    /// List&lt;object&gt;, string, double, bool, or null. Tolerant, not a validator —
    /// enough to read GeoJSON without pulling in a package.
    /// </summary>
    internal static class MiniJson
    {
        public static object Parse(string json)
        {
            if (string.IsNullOrEmpty(json)) return null;
            int i = 0;
            return ParseValue(json, ref i);
        }

        private static void SkipWs(string s, ref int i)
        {
            while (i < s.Length)
            {
                char c = s[i];
                if (c == ' ' || c == '\t' || c == '\n' || c == '\r') i++;
                else break;
            }
        }

        private static object ParseValue(string s, ref int i)
        {
            SkipWs(s, ref i);
            if (i >= s.Length) throw new FormatException("Unexpected end of JSON");
            char c = s[i];
            switch (c)
            {
                case '{': return ParseObject(s, ref i);
                case '[': return ParseArray(s, ref i);
                case '"': return ParseString(s, ref i);
                case 't': i += 4; return true;          // true
                case 'f': i += 5; return false;         // false
                case 'n': i += 4; return null;          // null
                default:  return ParseNumber(s, ref i);
            }
        }

        private static Dictionary<string, object> ParseObject(string s, ref int i)
        {
            var obj = new Dictionary<string, object>();
            i++; // consume '{'
            SkipWs(s, ref i);
            if (i < s.Length && s[i] == '}') { i++; return obj; }
            while (true)
            {
                SkipWs(s, ref i);
                string key = ParseString(s, ref i);
                SkipWs(s, ref i);
                if (i >= s.Length || s[i] != ':') throw new FormatException("Expected ':'");
                i++;
                obj[key] = ParseValue(s, ref i);
                SkipWs(s, ref i);
                if (i >= s.Length) throw new FormatException("Unterminated object");
                if (s[i] == ',') { i++; continue; }
                if (s[i] == '}') { i++; break; }
                throw new FormatException("Expected ',' or '}'");
            }
            return obj;
        }

        private static List<object> ParseArray(string s, ref int i)
        {
            var arr = new List<object>();
            i++; // consume '['
            SkipWs(s, ref i);
            if (i < s.Length && s[i] == ']') { i++; return arr; }
            while (true)
            {
                arr.Add(ParseValue(s, ref i));
                SkipWs(s, ref i);
                if (i >= s.Length) throw new FormatException("Unterminated array");
                if (s[i] == ',') { i++; continue; }
                if (s[i] == ']') { i++; break; }
                throw new FormatException("Expected ',' or ']'");
            }
            return arr;
        }

        private static string ParseString(string s, ref int i)
        {
            if (i >= s.Length || s[i] != '"') throw new FormatException("Expected string");
            i++;
            var sb = new StringBuilder();
            while (i < s.Length)
            {
                char c = s[i++];
                if (c == '"') return sb.ToString();
                if (c == '\\')
                {
                    if (i >= s.Length) break;
                    char e = s[i++];
                    switch (e)
                    {
                        case '"': sb.Append('"'); break;
                        case '\\': sb.Append('\\'); break;
                        case '/': sb.Append('/'); break;
                        case 'b': sb.Append('\b'); break;
                        case 'f': sb.Append('\f'); break;
                        case 'n': sb.Append('\n'); break;
                        case 'r': sb.Append('\r'); break;
                        case 't': sb.Append('\t'); break;
                        case 'u':
                            if (i + 4 <= s.Length)
                            {
                                if (ushort.TryParse(s.Substring(i, 4), NumberStyles.HexNumber,
                                        CultureInfo.InvariantCulture, out ushort code))
                                    sb.Append((char)code);
                                i += 4;
                            }
                            break;
                        default: sb.Append(e); break;
                    }
                }
                else sb.Append(c);
            }
            throw new FormatException("Unterminated string");
        }

        private static object ParseNumber(string s, ref int i)
        {
            int start = i;
            while (i < s.Length)
            {
                char c = s[i];
                if ((c >= '0' && c <= '9') || c == '-' || c == '+' || c == '.' || c == 'e' || c == 'E') i++;
                else break;
            }
            string num = s.Substring(start, i - start);
            return double.Parse(num, CultureInfo.InvariantCulture);
        }
    }
}
