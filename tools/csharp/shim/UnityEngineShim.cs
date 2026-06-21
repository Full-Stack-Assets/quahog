// ---------------------------------------------------------------------------
// UnityEngineShim.cs
//
// A compile-only stand-in for the Unity engine assemblies. It is NOT used by the
// real Unity build (it lives outside QUAHOG_Unity/Assets). Its sole purpose is to
// let our gameplay scripts — which reference UnityEngine / UnityEngine.UI /
// UnityEngine.Rendering — be type-checked headlessly with Roslyn in this sandbox.
//
// Scope is driven by what the project actually uses (see tools/csharp/README.md).
// Method bodies return defaults; the value is catching syntax/type/signature
// errors, plus the ability to RUN pure-logic code (JSON parsing, triangulation,
// GIS projection) against it. Extend as the codebase grows.
// ---------------------------------------------------------------------------
using System;
using System.Collections;
using System.Collections.Generic;

namespace UnityEngine
{
    // ----- Attributes -----------------------------------------------------
    [AttributeUsage(AttributeTargets.Field, AllowMultiple = false)]
    public sealed class SerializeField : Attribute { }
    [AttributeUsage(AttributeTargets.Field | AttributeTargets.Property)]
    public sealed class HideInInspector : Attribute { }
    [AttributeUsage(AttributeTargets.Class, AllowMultiple = true)]
    public sealed class RequireComponent : Attribute
    {
        public RequireComponent(Type a) { }
        public RequireComponent(Type a, Type b) { }
        public RequireComponent(Type a, Type b, Type c) { }
    }
    [AttributeUsage(AttributeTargets.Method)]
    public sealed class ContextMenu : Attribute
    {
        public ContextMenu(string name) { }
        public ContextMenu(string name, bool isValidateFunction) { }
    }
    [AttributeUsage(AttributeTargets.Field | AttributeTargets.Property)]
    public sealed class RangeAttribute : Attribute { public RangeAttribute(float min, float max) { } }
    [AttributeUsage(AttributeTargets.Field | AttributeTargets.Property)]
    public sealed class TooltipAttribute : Attribute { public TooltipAttribute(string t) { } }
    [AttributeUsage(AttributeTargets.Field)]
    public sealed class HeaderAttribute : Attribute { public HeaderAttribute(string h) { } }
    [AttributeUsage(AttributeTargets.Field)]
    public sealed class SpaceAttribute : Attribute { public SpaceAttribute() { } public SpaceAttribute(float h) { } }
    public enum RuntimeInitializeLoadType { AfterSceneLoad, BeforeSceneLoad, AfterAssembliesLoaded, BeforeSplashScreen, SubsystemRegistration }
    [AttributeUsage(AttributeTargets.Method)]
    public sealed class RuntimeInitializeOnLoadMethodAttribute : Attribute
    {
        public RuntimeInitializeOnLoadMethodAttribute() { }
        public RuntimeInitializeOnLoadMethodAttribute(RuntimeInitializeLoadType type) { }
    }

    // ----- Enums ----------------------------------------------------------
    public enum PrimitiveType { Sphere, Capsule, Cylinder, Cube, Plane, Quad }
    public enum Space { World, Self }
    public enum HideFlags { None = 0, HideInHierarchy = 1, HideInInspector = 2, DontSaveInEditor = 4, NotEditable = 8, DontSaveInBuild = 16, DontUnloadUnusedAsset = 32, DontSave = 52, HideAndDontSave = 61 }
    public enum CameraClearFlags { Skybox = 1, Color = 2, SolidColor = 2, Depth = 3, Nothing = 4 }
    public enum LightType { Spot, Directional, Point, Area, Rectangle, Disc }
    public enum LightShadows { None, Hard, Soft }
    public enum TextAnchor { UpperLeft, UpperCenter, UpperRight, MiddleLeft, MiddleCenter, MiddleRight, LowerLeft, LowerCenter, LowerRight }
    public enum FontStyle { Normal, Bold, Italic, BoldAndItalic }
    public enum ForceMode { Force, Acceleration, Impulse, VelocityChange }
    public enum CollisionDetectionMode { Discrete, Continuous, ContinuousDynamic, ContinuousSpeculative }
    [Flags] public enum RigidbodyConstraints { None = 0, FreezePositionX = 2, FreezePositionY = 4, FreezePositionZ = 8, FreezeRotationX = 16, FreezeRotationY = 32, FreezeRotationZ = 64, FreezePosition = 14, FreezeRotation = 112, FreezeAll = 126 }
    public enum RigidbodyInterpolation { None, Interpolate, Extrapolate }
    public enum RenderMode { ScreenSpaceOverlay, ScreenSpaceCamera, WorldSpace }

    // ----- Math: Vector2 --------------------------------------------------
    public struct Vector2
    {
        public float x, y;
        public Vector2(float x, float y) { this.x = x; this.y = y; }
        public float magnitude => Mathf.Sqrt(x * x + y * y);
        public float sqrMagnitude => x * x + y * y;
        public Vector2 normalized { get { float m = magnitude; return m > 1e-9f ? new Vector2(x / m, y / m) : new Vector2(0, 0); } }
        public static Vector2 zero => new Vector2(0, 0);
        public static Vector2 one => new Vector2(1, 1);
        public static Vector2 up => new Vector2(0, 1);
        public static Vector2 down => new Vector2(0, -1);
        public static Vector2 left => new Vector2(-1, 0);
        public static Vector2 right => new Vector2(1, 0);
        public static Vector2 operator +(Vector2 a, Vector2 b) => new Vector2(a.x + b.x, a.y + b.y);
        public static Vector2 operator -(Vector2 a, Vector2 b) => new Vector2(a.x - b.x, a.y - b.y);
        public static Vector2 operator -(Vector2 a) => new Vector2(-a.x, -a.y);
        public static Vector2 operator *(Vector2 a, float d) => new Vector2(a.x * d, a.y * d);
        public static Vector2 operator *(float d, Vector2 a) => new Vector2(a.x * d, a.y * d);
        public static Vector2 operator /(Vector2 a, float d) => new Vector2(a.x / d, a.y / d);
        public static bool operator ==(Vector2 a, Vector2 b) => Mathf.Approximately(a.x, b.x) && Mathf.Approximately(a.y, b.y);
        public static bool operator !=(Vector2 a, Vector2 b) => !(a == b);
        public static float Distance(Vector2 a, Vector2 b) => (a - b).magnitude;
        public static float Dot(Vector2 a, Vector2 b) => a.x * b.x + a.y * b.y;
        public static Vector2 Lerp(Vector2 a, Vector2 b, float t) { t = Mathf.Clamp01(t); return new Vector2(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t); }
        public static implicit operator Vector2(Vector3 v) => new Vector2(v.x, v.y);
        public static implicit operator Vector3(Vector2 v) => new Vector3(v.x, v.y, 0);
        public override bool Equals(object o) => o is Vector2 v && this == v;
        public override int GetHashCode() => x.GetHashCode() ^ (y.GetHashCode() << 2);
        public override string ToString() => $"({x:F1}, {y:F1})";
    }

    // ----- Math: Vector3 --------------------------------------------------
    public struct Vector3
    {
        public float x, y, z;
        public Vector3(float x, float y, float z) { this.x = x; this.y = y; this.z = z; }
        public Vector3(float x, float y) { this.x = x; this.y = y; this.z = 0; }
        public float magnitude => Mathf.Sqrt(x * x + y * y + z * z);
        public float sqrMagnitude => x * x + y * y + z * z;
        public Vector3 normalized { get { float m = magnitude; return m > 1e-9f ? new Vector3(x / m, y / m, z / m) : new Vector3(0, 0, 0); } }
        public void Normalize() { float m = magnitude; if (m > 1e-9f) { x /= m; y /= m; z /= m; } else { x = y = z = 0; } }
        public static Vector3 zero => new Vector3(0, 0, 0);
        public static Vector3 one => new Vector3(1, 1, 1);
        public static Vector3 up => new Vector3(0, 1, 0);
        public static Vector3 down => new Vector3(0, -1, 0);
        public static Vector3 left => new Vector3(-1, 0, 0);
        public static Vector3 right => new Vector3(1, 0, 0);
        public static Vector3 forward => new Vector3(0, 0, 1);
        public static Vector3 back => new Vector3(0, 0, -1);
        public static Vector3 operator +(Vector3 a, Vector3 b) => new Vector3(a.x + b.x, a.y + b.y, a.z + b.z);
        public static Vector3 operator -(Vector3 a, Vector3 b) => new Vector3(a.x - b.x, a.y - b.y, a.z - b.z);
        public static Vector3 operator -(Vector3 a) => new Vector3(-a.x, -a.y, -a.z);
        public static Vector3 operator *(Vector3 a, float d) => new Vector3(a.x * d, a.y * d, a.z * d);
        public static Vector3 operator *(float d, Vector3 a) => new Vector3(a.x * d, a.y * d, a.z * d);
        public static Vector3 operator /(Vector3 a, float d) => new Vector3(a.x / d, a.y / d, a.z / d);
        public static bool operator ==(Vector3 a, Vector3 b) => (a - b).sqrMagnitude < 1e-10f;
        public static bool operator !=(Vector3 a, Vector3 b) => !(a == b);
        public static float Distance(Vector3 a, Vector3 b) => (a - b).magnitude;
        public static float Dot(Vector3 a, Vector3 b) => a.x * b.x + a.y * b.y + a.z * b.z;
        public static Vector3 Cross(Vector3 a, Vector3 b) => new Vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x);
        public static Vector3 Lerp(Vector3 a, Vector3 b, float t) { t = Mathf.Clamp01(t); return a + (b - a) * t; }
        public static Vector3 LerpUnclamped(Vector3 a, Vector3 b, float t) => a + (b - a) * t;
        public static Vector3 Slerp(Vector3 a, Vector3 b, float t) => Lerp(a, b, t);
        public static Vector3 MoveTowards(Vector3 a, Vector3 b, float maxStep) { Vector3 d = b - a; float m = d.magnitude; return m <= maxStep || m < 1e-9f ? b : a + d / m * maxStep; }
        public static Vector3 Scale(Vector3 a, Vector3 b) => new Vector3(a.x * b.x, a.y * b.y, a.z * b.z);
        public static Vector3 Normalize(Vector3 v) => v.normalized;
        public static Vector3 Project(Vector3 v, Vector3 n) { float d = Dot(n, n); return d < 1e-9f ? zero : n * (Dot(v, n) / d); }
        public static Vector3 ProjectOnPlane(Vector3 v, Vector3 n) => v - Project(v, n);
        public static float Angle(Vector3 a, Vector3 b) { float d = a.magnitude * b.magnitude; if (d < 1e-9f) return 0; return Mathf.Acos(Mathf.Clamp(Dot(a, b) / d, -1f, 1f)) * Mathf.Rad2Deg; }
        public static Vector3 ClampMagnitude(Vector3 v, float max) { return v.sqrMagnitude > max * max ? v.normalized * max : v; }
        public override bool Equals(object o) => o is Vector3 v && this == v;
        public override int GetHashCode() => x.GetHashCode() ^ (y.GetHashCode() << 2) ^ (z.GetHashCode() >> 2);
        public override string ToString() => $"({x:F1}, {y:F1}, {z:F1})";
    }

    public struct Vector4
    {
        public float x, y, z, w;
        public Vector4(float x, float y, float z, float w) { this.x = x; this.y = y; this.z = z; this.w = w; }
        public static Vector4 zero => new Vector4(0, 0, 0, 0);
    }

    // ----- Math: Quaternion ----------------------------------------------
    public struct Quaternion
    {
        public float x, y, z, w;
        public Quaternion(float x, float y, float z, float w) { this.x = x; this.y = y; this.z = z; this.w = w; }
        public static Quaternion identity => new Quaternion(0, 0, 0, 1);
        public Vector3 eulerAngles { get => Vector3.zero; set { } }
        public static Quaternion Euler(float x, float y, float z) => identity;
        public static Quaternion Euler(Vector3 e) => identity;
        public static Quaternion AngleAxis(float angle, Vector3 axis) => identity;
        public static Quaternion LookRotation(Vector3 forward) => identity;
        public static Quaternion LookRotation(Vector3 forward, Vector3 up) => identity;
        public static Quaternion Slerp(Quaternion a, Quaternion b, float t) => identity;
        public static Quaternion Lerp(Quaternion a, Quaternion b, float t) => identity;
        public static Quaternion RotateTowards(Quaternion a, Quaternion b, float maxDeg) => identity;
        public static Quaternion FromToRotation(Vector3 a, Vector3 b) => identity;
        public static float Angle(Quaternion a, Quaternion b) => 0f;
        public static Quaternion operator *(Quaternion a, Quaternion b) => identity;
        public static Vector3 operator *(Quaternion q, Vector3 v) => v;
        public override string ToString() => $"({x:F1}, {y:F1}, {z:F1}, {w:F1})";
    }

    // ----- Math: Color ----------------------------------------------------
    public struct Color
    {
        public float r, g, b, a;
        public Color(float r, float g, float b) { this.r = r; this.g = g; this.b = b; this.a = 1f; }
        public Color(float r, float g, float b, float a) { this.r = r; this.g = g; this.b = b; this.a = a; }
        public static Color white => new Color(1, 1, 1, 1);
        public static Color black => new Color(0, 0, 0, 1);
        public static Color clear => new Color(0, 0, 0, 0);
        public static Color red => new Color(1, 0, 0, 1);
        public static Color green => new Color(0, 1, 0, 1);
        public static Color blue => new Color(0, 0, 1, 1);
        public static Color yellow => new Color(1, 0.92f, 0.016f, 1);
        public static Color cyan => new Color(0, 1, 1, 1);
        public static Color magenta => new Color(1, 0, 1, 1);
        public static Color gray => new Color(0.5f, 0.5f, 0.5f, 1);
        public static Color grey => new Color(0.5f, 0.5f, 0.5f, 1);
        public static Color Lerp(Color a, Color b, float t) { t = Mathf.Clamp01(t); return new Color(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t); }
        public static Color operator *(Color c, float d) => new Color(c.r * d, c.g * d, c.b * d, c.a * d);
        public static Color operator *(float d, Color c) => c * d;
        public static Color operator *(Color a, Color b) => new Color(a.r * b.r, a.g * b.g, a.b * b.b, a.a * b.a);
        public static Color operator +(Color a, Color b) => new Color(a.r + b.r, a.g + b.g, a.b + b.b, a.a + b.a);
        public override string ToString() => $"RGBA({r:F2}, {g:F2}, {b:F2}, {a:F2})";
    }

    public struct Color32
    {
        public byte r, g, b, a;
        public Color32(byte r, byte g, byte b, byte a) { this.r = r; this.g = g; this.b = b; this.a = a; }
        public static implicit operator Color(Color32 c) => new Color(c.r / 255f, c.g / 255f, c.b / 255f, c.a / 255f);
        public static implicit operator Color32(Color c) => new Color32((byte)(c.r * 255), (byte)(c.g * 255), (byte)(c.b * 255), (byte)(c.a * 255));
    }

    public struct Bounds
    {
        public Vector3 center, size;
        public Bounds(Vector3 center, Vector3 size) { this.center = center; this.size = size; }
        public Vector3 extents => size * 0.5f;
        public Vector3 min => center - extents;
        public Vector3 max => center + extents;
        public bool Contains(Vector3 p) => true;
        public void Encapsulate(Vector3 p) { }
        public void Encapsulate(Bounds b) { }
    }

    public struct Rect
    {
        public float x, y, width, height;
        public Rect(float x, float y, float width, float height) { this.x = x; this.y = y; this.width = width; this.height = height; }
        public Rect(Vector2 position, Vector2 size) { x = position.x; y = position.y; width = size.x; height = size.y; }
        public float xMin { get => x; set => x = value; }
        public float yMin { get => y; set => y = value; }
        public float xMax { get => x + width; set => width = value - x; }
        public float yMax { get => y + height; set => height = value - y; }
        public Vector2 position { get => new Vector2(x, y); set { x = value.x; y = value.y; } }
        public Vector2 size { get => new Vector2(width, height); set { width = value.x; height = value.y; } }
        public Vector2 center => new Vector2(x + width * 0.5f, y + height * 0.5f);
        public bool Contains(Vector2 p) => p.x >= x && p.x < x + width && p.y >= y && p.y < y + height;
    }

    // ----- Math: Mathf ----------------------------------------------------
    public static class Mathf
    {
        public const float PI = 3.14159265358979f;
        public const float Epsilon = 1.401298E-45f;
        public const float Deg2Rad = PI / 180f;
        public const float Rad2Deg = 180f / PI;
        public const float Infinity = float.PositiveInfinity;
        public const float NegativeInfinity = float.NegativeInfinity;
        public static float Abs(float v) => Math.Abs(v);
        public static int Abs(int v) => Math.Abs(v);
        public static float Min(float a, float b) => a < b ? a : b;
        public static int Min(int a, int b) => a < b ? a : b;
        public static float Max(float a, float b) => a > b ? a : b;
        public static int Max(int a, int b) => a > b ? a : b;
        public static float Clamp(float v, float lo, float hi) => v < lo ? lo : (v > hi ? hi : v);
        public static int Clamp(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
        public static float Clamp01(float v) => v < 0 ? 0 : (v > 1 ? 1 : v);
        public static float Lerp(float a, float b, float t) => a + (b - a) * Clamp01(t);
        public static float LerpUnclamped(float a, float b, float t) => a + (b - a) * t;
        public static float LerpAngle(float a, float b, float t) { float d = Repeat(b - a, 360f); if (d > 180f) d -= 360f; return a + d * Clamp01(t); }
        public static float MoveTowards(float a, float b, float maxDelta) { return Abs(b - a) <= maxDelta ? b : a + Sign(b - a) * maxDelta; }
        public static float Sign(float v) => v >= 0f ? 1f : -1f;
        public static float Sin(float v) => (float)Math.Sin(v);
        public static float Cos(float v) => (float)Math.Cos(v);
        public static float Tan(float v) => (float)Math.Tan(v);
        public static float Asin(float v) => (float)Math.Asin(v);
        public static float Acos(float v) => (float)Math.Acos(v);
        public static float Atan(float v) => (float)Math.Atan(v);
        public static float Atan2(float y, float x) => (float)Math.Atan2(y, x);
        public static float Sqrt(float v) => (float)Math.Sqrt(v);
        public static float Pow(float a, float b) => (float)Math.Pow(a, b);
        public static float Exp(float v) => (float)Math.Exp(v);
        public static float Log(float v) => (float)Math.Log(v);
        public static float Floor(float v) => (float)Math.Floor(v);
        public static float Ceil(float v) => (float)Math.Ceiling(v);
        public static float Round(float v) => (float)Math.Round(v);
        public static int FloorToInt(float v) => (int)Math.Floor(v);
        public static int CeilToInt(float v) => (int)Math.Ceiling(v);
        public static int RoundToInt(float v) => (int)Math.Round(v);
        public static float Repeat(float t, float length) { return Clamp(t - Floor(t / length) * length, 0f, length); }
        public static float PingPong(float t, float length) { t = Repeat(t, length * 2f); return length - Abs(t - length); }
        public static float SmoothStep(float from, float to, float t) { t = Clamp01(t); t = t * t * (3f - 2f * t); return to * t + from * (1f - t); }
        public static float DeltaAngle(float a, float b) { float d = Repeat(b - a, 360f); if (d > 180f) d -= 360f; return d; }
        public static bool Approximately(float a, float b) => Abs(b - a) < Max(1e-6f * Max(Abs(a), Abs(b)), Epsilon * 8f);
    }

    // ----- Time / Random / Debug -----------------------------------------
    public static class Time
    {
        public static float deltaTime = 0.016f;
        public static float fixedDeltaTime = 0.02f;
        public static float unscaledDeltaTime = 0.016f;
        public static float time = 0f;
        public static float unscaledTime = 0f;
        public static float timeScale = 1f;
        public static float realtimeSinceStartup = 0f;
        public static int frameCount = 0;
        public static float smoothDeltaTime = 0.016f;
    }

    public static class Random
    {
        private static readonly System.Random _r = new System.Random(12345);
        public static float value => (float)_r.NextDouble();
        public static int Range(int minInclusive, int maxExclusive) => maxExclusive <= minInclusive ? minInclusive : _r.Next(minInclusive, maxExclusive);
        public static float Range(float min, float max) => min + (float)_r.NextDouble() * (max - min);
        public static Vector3 insideUnitSphere => new Vector3(Range(-1f, 1f), Range(-1f, 1f), Range(-1f, 1f));
        public static Vector2 insideUnitCircle => new Vector2(Range(-1f, 1f), Range(-1f, 1f));
        public static Vector3 onUnitSphere => insideUnitSphere.normalized;
        public static Quaternion rotation => Quaternion.identity;
        public static void InitState(int seed) { }
    }

    public static class Debug
    {
        public static void Log(object message) => Console.WriteLine("[Log] " + message);
        public static void LogWarning(object message) => Console.WriteLine("[Warn] " + message);
        public static void LogError(object message) => Console.WriteLine("[Error] " + message);
        public static void LogException(Exception e) => Console.WriteLine("[Exception] " + e);
        public static void LogFormat(string fmt, params object[] args) => Console.WriteLine("[Log] " + string.Format(fmt, args));
        public static void DrawLine(Vector3 a, Vector3 b) { }
        public static void DrawLine(Vector3 a, Vector3 b, Color c) { }
        public static void DrawLine(Vector3 a, Vector3 b, Color c, float dur) { }
        public static void DrawRay(Vector3 o, Vector3 d) { }
        public static void DrawRay(Vector3 o, Vector3 d, Color c) { }
        public static void Assert(bool condition) { }
    }

    public static class Application
    {
        public static bool isPlaying => true;
        public static bool isEditor => false;
        public static string platform => "Sandbox";
        public static int targetFrameRate = 60;
        public static string persistentDataPath = "/tmp";
        public static string dataPath = "/tmp";
        public static void Quit() { }
    }

    public static class Screen
    {
        public static int width = 1920;
        public static int height = 1080;
        public static bool fullScreen = false;
    }

    public static class QualitySettings
    {
        public static int vSyncCount = 1;
    }

    // ----- Object / Component / GameObject / Transform -------------------
    public class Object
    {
        public string name { get; set; } = "";
        public HideFlags hideFlags { get; set; }
        public int GetInstanceID() => base.GetHashCode();
        public override string ToString() => name;
        public static void Destroy(Object obj) { }
        public static void Destroy(Object obj, float t) { }
        public static void DestroyImmediate(Object obj) { }
        public static void DontDestroyOnLoad(Object target) { }
        public static T Instantiate<T>(T original) where T : Object => original;
        public static T Instantiate<T>(T original, Vector3 pos, Quaternion rot) where T : Object => original;
        public static T FindObjectOfType<T>() where T : Object => null;
        public static T[] FindObjectsOfType<T>() where T : Object => new T[0];
        public static T FindAnyObjectByType<T>() where T : Object => null;
        public static T FindFirstObjectByType<T>() where T : Object => null;
        public static implicit operator bool(Object o) => !ReferenceEquals(o, null);
    }

    public class Component : Object
    {
        internal GameObject _go;
        public GameObject gameObject => _go;
        public Transform transform => _go != null ? _go.transform : null;
        public string tag { get => _go != null ? _go.tag : "Untagged"; set { if (_go != null) _go.tag = value; } }
        public bool CompareTag(string t) => tag == t;
        public T GetComponent<T>() where T : class => _go != null ? _go.GetComponent<T>() : null;
        public Component GetComponent(Type t) => null;
        public T GetComponentInChildren<T>() where T : class => GetComponent<T>();
        public T GetComponentInParent<T>() where T : class => GetComponent<T>();
        public T[] GetComponentsInChildren<T>() where T : class => new T[0];
        public bool TryGetComponent<T>(out T component) where T : class { component = GetComponent<T>(); return component != null; }
        public T AddComponent<T>() where T : Component => _go != null ? _go.AddComponent<T>() : null;
        public void SendMessage(string method) { }
    }

    public class Behaviour : Component
    {
        public bool enabled { get; set; } = true;
        public bool isActiveAndEnabled => enabled;
    }

    public class MonoBehaviour : Behaviour
    {
        public Coroutine StartCoroutine(IEnumerator routine) => new Coroutine();
        public Coroutine StartCoroutine(string methodName) => new Coroutine();
        public void StopCoroutine(IEnumerator routine) { }
        public void StopCoroutine(Coroutine routine) { }
        public void StopAllCoroutines() { }
        public void Invoke(string methodName, float time) { }
        public void InvokeRepeating(string methodName, float time, float repeatRate) { }
        public void CancelInvoke() { }
        public void CancelInvoke(string methodName) { }
        public bool IsInvoking() => false;
        public bool IsInvoking(string methodName) => false;
        public static void print(object message) => Debug.Log(message);
    }

    public sealed class GameObject : Object
    {
        private readonly List<Component> _components = new List<Component>();
        public Transform transform { get; private set; }
        public int layer { get; set; }
        public string tag { get; set; } = "Untagged";
        public bool isStatic { get; set; }
        private bool _active = true;

        public GameObject()
        {
            name = "GameObject";
            transform = new Transform { _go = this };
            _components.Add(transform);
        }
        public GameObject(string name) : this() { this.name = name; }
        public GameObject(string name, params Type[] components) : this(name)
        {
            foreach (var t in components) AddComponent(t);
        }

        public T AddComponent<T>() where T : Component
        {
            var c = (T)Activator.CreateInstance(typeof(T));
            c._go = this;
            _components.Add(c);
            return c;
        }
        public Component AddComponent(Type type)
        {
            var c = (Component)Activator.CreateInstance(type);
            c._go = this;
            _components.Add(c);
            return c;
        }
        public T GetComponent<T>() where T : class
        {
            foreach (var c in _components) if (c is T t) return t;
            return null;
        }
        public Component GetComponent(Type type)
        {
            foreach (var c in _components) if (type.IsInstanceOfType(c)) return c;
            return null;
        }
        public T GetComponentInChildren<T>() where T : class => GetComponent<T>();
        public T GetComponentInParent<T>() where T : class => GetComponent<T>();
        public T[] GetComponentsInChildren<T>() where T : class => new T[0];
        public bool TryGetComponent<T>(out T component) where T : class { component = GetComponent<T>(); return component != null; }
        public void SetActive(bool value) => _active = value;
        public bool activeSelf => _active;
        public bool activeInHierarchy => _active;
        public bool CompareTag(string t) => tag == t;

        public static GameObject CreatePrimitive(PrimitiveType type)
        {
            var go = new GameObject(type.ToString());
            go.AddComponent<MeshFilter>();
            go.AddComponent<MeshRenderer>();
            if (type == PrimitiveType.Plane || type == PrimitiveType.Quad) go.AddComponent<MeshCollider>();
            else if (type == PrimitiveType.Sphere) go.AddComponent<SphereCollider>();
            else if (type == PrimitiveType.Capsule || type == PrimitiveType.Cylinder) go.AddComponent<CapsuleCollider>();
            else go.AddComponent<BoxCollider>();
            return go;
        }
        public static GameObject Find(string name) => null;
        public static GameObject FindWithTag(string tag) => null;
    }

    public class Transform : Component, IEnumerable
    {
        public Vector3 position { get; set; }
        public Vector3 localPosition { get; set; }
        public Quaternion rotation { get; set; } = Quaternion.identity;
        public Quaternion localRotation { get; set; } = Quaternion.identity;
        public Vector3 eulerAngles { get; set; }
        public Vector3 localEulerAngles { get; set; }
        public Vector3 localScale { get; set; } = Vector3.one;
        public Vector3 lossyScale => localScale;
        public Transform parent { get; set; }
        public Transform root => parent == null ? this : parent.root;
        public int childCount => 0;
        public Vector3 forward { get => rotation * Vector3.forward; set { } }
        public Vector3 right { get => rotation * Vector3.right; set { } }
        public Vector3 up { get => rotation * Vector3.up; set { } }

        public void SetParent(Transform p) { parent = p; }
        public void SetParent(Transform p, bool worldPositionStays) { parent = p; }
        public Transform GetChild(int i) => null;
        public Transform Find(string n) => null;
        public void LookAt(Transform target) { }
        public void LookAt(Vector3 worldPosition) { }
        public void LookAt(Vector3 worldPosition, Vector3 worldUp) { }
        public void Translate(Vector3 t) { position += t; }
        public void Translate(Vector3 t, Space s) { position += t; }
        public void Translate(float x, float y, float z) { position += new Vector3(x, y, z); }
        public void Rotate(Vector3 e) { }
        public void Rotate(Vector3 e, Space s) { }
        public void Rotate(float x, float y, float z) { }
        public void RotateAround(Vector3 point, Vector3 axis, float angle) { }
        public void SetPositionAndRotation(Vector3 p, Quaternion r) { position = p; rotation = r; }
        public void SetSiblingIndex(int i) { }
        public void DetachChildren() { }
        public Vector3 TransformPoint(Vector3 p) => position + p;
        public Vector3 InverseTransformPoint(Vector3 p) => p - position;
        public Vector3 TransformDirection(Vector3 d) => d;
        public Vector3 InverseTransformDirection(Vector3 d) => d;
        public IEnumerator GetEnumerator() { yield break; }
    }

    public class RectTransform : Transform
    {
        public Vector2 anchorMin { get; set; }
        public Vector2 anchorMax { get; set; }
        public Vector2 anchoredPosition { get; set; }
        public Vector3 anchoredPosition3D { get; set; }
        public Vector2 sizeDelta { get; set; }
        public Vector2 pivot { get; set; }
        public Vector2 offsetMin { get; set; }
        public Vector2 offsetMax { get; set; }
    }

    // ----- Resources / assets / rendering --------------------------------
    public sealed class TextAsset : Object
    {
        public string text { get; private set; }
        public byte[] bytes => System.Text.Encoding.UTF8.GetBytes(text ?? "");
        public TextAsset() { text = ""; }
        public TextAsset(string content) { text = content; }
        public override string ToString() => text;
    }

    public sealed class Font : Object { }
    public sealed class Sprite : Object { }
    public sealed class Texture : Object { }
    public sealed class Texture2D : Object { public Texture2D(int w, int h) { } }
    public sealed class AudioClip : Object { }

    public static class Resources
    {
        public static T Load<T>(string path) where T : Object => null;
        public static Object Load(string path) => null;
        public static Object[] LoadAll(string path) => new Object[0];
        public static T GetBuiltinResource<T>(string path) where T : Object => null;
        public static void UnloadUnusedAssets() { }
    }

    public sealed class Shader : Object
    {
        public static Shader Find(string name) => new Shader { name = name };
    }

    public sealed class Material : Object
    {
        private readonly Dictionary<string, Color> _colors = new Dictionary<string, Color>();
        private readonly Dictionary<string, float> _floats = new Dictionary<string, float>();
        public Shader shader { get; set; }
        public Color color { get; set; } = Color.white;
        public Texture mainTexture { get; set; }
        public int renderQueue { get; set; }
        public Material(Shader shader) { this.shader = shader; }
        public Material(Material source) { shader = source?.shader; color = source?.color ?? Color.white; }
        public bool HasProperty(string name) => false;
        public void SetColor(string name, Color value) { _colors[name] = value; }
        public Color GetColor(string name) => _colors.TryGetValue(name, out var c) ? c : Color.white;
        public void SetFloat(string name, float value) { _floats[name] = value; }
        public float GetFloat(string name) => _floats.TryGetValue(name, out var f) ? f : 0f;
        public void SetTexture(string name, Texture t) { }
        public void SetVector(string name, Vector4 v) { }
        public void EnableKeyword(string kw) { }
        public void DisableKeyword(string kw) { }
    }

    public sealed class Mesh : Object
    {
        public Vector3[] vertices { get; set; } = new Vector3[0];
        public int[] triangles { get; set; } = new int[0];
        public Vector3[] normals { get; set; } = new Vector3[0];
        public Vector2[] uv { get; set; } = new Vector2[0];
        public Color[] colors { get; set; } = new Color[0];
        public Bounds bounds { get; set; }
        public int vertexCount => vertices?.Length ?? 0;
        public Rendering.IndexFormat indexFormat { get; set; } = Rendering.IndexFormat.UInt16;
        public void Clear() { vertices = new Vector3[0]; triangles = new int[0]; }
        public void SetVertices(List<Vector3> v) { vertices = v.ToArray(); }
        public void SetVertices(Vector3[] v) { vertices = v; }
        public void SetTriangles(List<int> t, int submesh) { triangles = t.ToArray(); }
        public void SetTriangles(int[] t, int submesh) { triangles = t; }
        public void SetNormals(List<Vector3> n) { normals = n.ToArray(); }
        public void SetUVs(int channel, List<Vector2> uvs) { uv = uvs.ToArray(); }
        public void RecalculateNormals() { }
        public void RecalculateBounds() { }
        public void RecalculateTangents() { }
    }

    public class Renderer : Component
    {
        public Material material { get; set; }
        public Material sharedMaterial { get; set; }
        public Material[] materials { get; set; } = new Material[0];
        public Material[] sharedMaterials { get; set; } = new Material[0];
        public bool enabled { get; set; } = true;
        public Bounds bounds { get; set; }
        public bool receiveShadows { get; set; }
    }

    public sealed class MeshFilter : Component
    {
        public Mesh mesh { get; set; }
        public Mesh sharedMesh { get; set; }
    }

    public sealed class MeshRenderer : Renderer { }

    // ----- Physics --------------------------------------------------------
    public class Collider : Component
    {
        public bool enabled { get; set; } = true;
        public bool isTrigger { get; set; }
        public Bounds bounds { get; set; }
        public Material material { get; set; }
        public Rigidbody attachedRigidbody => GetComponent<Rigidbody>();
    }
    public sealed class BoxCollider : Collider { public Vector3 center { get; set; } public Vector3 size { get; set; } = Vector3.one; }
    public sealed class SphereCollider : Collider { public Vector3 center { get; set; } public float radius { get; set; } = 0.5f; }
    public sealed class CapsuleCollider : Collider { public Vector3 center { get; set; } public float radius { get; set; } = 0.5f; public float height { get; set; } = 2f; public int direction { get; set; } = 1; }
    public sealed class MeshCollider : Collider { public Mesh sharedMesh { get; set; } public bool convex { get; set; } }

    public sealed class CharacterController : Collider
    {
        public bool isGrounded { get; private set; }
        public Vector3 velocity { get; private set; }
        public float height { get; set; } = 2f;
        public float radius { get; set; } = 0.5f;
        public Vector3 center { get; set; }
        public float slopeLimit { get; set; } = 45f;
        public float stepOffset { get; set; } = 0.3f;
        public float skinWidth { get; set; } = 0.08f;
        public float minMoveDistance { get; set; } = 0.001f;
        public CollisionFlags collisionFlags { get; private set; }
        public CollisionFlags Move(Vector3 motion) { return CollisionFlags.None; }
        public bool SimpleMove(Vector3 speed) => true;
    }
    [Flags] public enum CollisionFlags { None = 0, Sides = 1, Above = 2, Below = 4 }

    public sealed class Rigidbody : Component
    {
        public Vector3 velocity { get; set; }
        public Vector3 linearVelocity { get; set; }          // Unity 6 rename of velocity
        public Vector3 angularVelocity { get; set; }
        public float mass { get; set; } = 1f;
        public float drag { get; set; }
        public float angularDrag { get; set; } = 0.05f;
        public float linearDamping { get; set; }             // Unity 6 rename of drag
        public float angularDamping { get; set; } = 0.05f;   // Unity 6 rename of angularDrag
        public bool useGravity { get; set; } = true;
        public bool isKinematic { get; set; }
        public bool freezeRotation { get; set; }
        public Vector3 position { get; set; }
        public Quaternion rotation { get; set; } = Quaternion.identity;
        public Vector3 centerOfMass { get; set; }
        public float maxAngularVelocity { get; set; } = 7f;
        public RigidbodyConstraints constraints { get; set; }
        public RigidbodyInterpolation interpolation { get; set; }
        public CollisionDetectionMode collisionDetectionMode { get; set; }
        public void AddForce(Vector3 force) { }
        public void AddForce(Vector3 force, ForceMode mode) { }
        public void AddRelativeForce(Vector3 force, ForceMode mode) { }
        public void AddTorque(Vector3 torque) { }
        public void AddTorque(Vector3 torque, ForceMode mode) { }
        public void AddForceAtPosition(Vector3 force, Vector3 position, ForceMode mode) { }
        public void MovePosition(Vector3 position) { }
        public void MoveRotation(Quaternion rot) { }
        public Vector3 GetPointVelocity(Vector3 worldPoint) => Vector3.zero;
        public Vector3 GetRelativePointVelocity(Vector3 relativePoint) => Vector3.zero;
        public void WakeUp() { }
        public void Sleep() { }
        public bool IsSleeping() => false;
    }

    public struct RaycastHit
    {
        public Vector3 point;
        public Vector3 normal;
        public float distance;
        public Collider collider;
        public Rigidbody rigidbody;
        public Transform transform;
    }

    public struct Ray
    {
        public Vector3 origin;
        public Vector3 direction;
        public Ray(Vector3 origin, Vector3 direction) { this.origin = origin; this.direction = direction; }
        public Vector3 GetPoint(float d) => origin + direction * d;
    }

    public struct LayerMask
    {
        public int value;
        public static int GetMask(params string[] layerNames) => 0;
        public static int NameToLayer(string layerName) => 0;
        public static string LayerToName(int layer) => "";
        public static implicit operator int(LayerMask m) => m.value;
        public static implicit operator LayerMask(int v) => new LayerMask { value = v };
    }

    public static class Physics
    {
        public static Vector3 gravity = new Vector3(0, -9.81f, 0);
        public static bool Raycast(Vector3 origin, Vector3 direction) => false;
        public static bool Raycast(Vector3 origin, Vector3 direction, float maxDistance) => false;
        public static bool Raycast(Vector3 origin, Vector3 direction, out RaycastHit hit) { hit = default; return false; }
        public static bool Raycast(Vector3 origin, Vector3 direction, out RaycastHit hit, float maxDistance) { hit = default; return false; }
        public static bool Raycast(Vector3 origin, Vector3 direction, out RaycastHit hit, float maxDistance, int layerMask) { hit = default; return false; }
        public static bool Raycast(Ray ray, out RaycastHit hit, float maxDistance) { hit = default; return false; }
        public static RaycastHit[] RaycastAll(Vector3 origin, Vector3 direction, float maxDistance) => new RaycastHit[0];
        public static Collider[] OverlapSphere(Vector3 position, float radius) => new Collider[0];
        public static bool CheckSphere(Vector3 position, float radius) => false;
    }

    // ----- Camera / Light / Audio ----------------------------------------
    public sealed class Camera : Behaviour
    {
        public static Camera main { get; set; }
        public float fieldOfView { get; set; } = 60f;
        public float nearClipPlane { get; set; } = 0.3f;
        public float farClipPlane { get; set; } = 1000f;
        public CameraClearFlags clearFlags { get; set; } = CameraClearFlags.Skybox;
        public Color backgroundColor { get; set; }
        public bool orthographic { get; set; }
        public float orthographicSize { get; set; } = 5f;
        public int cullingMask { get; set; } = -1;
        public float depth { get; set; }
        public bool allowHDR { get; set; }
        public Ray ScreenPointToRay(Vector3 pos) => new Ray(Vector3.zero, Vector3.forward);
        public Vector3 WorldToScreenPoint(Vector3 p) => Vector3.zero;
        public Vector3 ScreenToWorldPoint(Vector3 p) => Vector3.zero;
    }

    public sealed class Light : Behaviour
    {
        public LightType type { get; set; } = LightType.Point;
        public Color color { get; set; } = Color.white;
        public float intensity { get; set; } = 1f;
        public float range { get; set; } = 10f;
        public float spotAngle { get; set; } = 30f;
        public LightShadows shadows { get; set; }
        public float shadowStrength { get; set; } = 1f;
    }

    public sealed class AudioSource : Behaviour
    {
        public AudioClip clip { get; set; }
        public float volume { get; set; } = 1f;
        public float pitch { get; set; } = 1f;
        public bool loop { get; set; }
        public bool playOnAwake { get; set; } = true;
        public bool mute { get; set; }
        public float spatialBlend { get; set; }
        public bool isPlaying { get; private set; }
        public void Play() { }
        public void Stop() { }
        public void Pause() { }
        public void PlayOneShot(AudioClip clip) { }
        public void PlayOneShot(AudioClip clip, float volumeScale) { }
    }

    public sealed class AudioListener : Behaviour { }

    // ----- Input ----------------------------------------------------------
    public static class Input
    {
        public static bool GetKey(KeyCode key) => false;
        public static bool GetKeyDown(KeyCode key) => false;
        public static bool GetKeyUp(KeyCode key) => false;
        public static bool GetKey(string name) => false;
        public static bool GetButton(string name) => false;
        public static bool GetButtonDown(string name) => false;
        public static bool GetButtonUp(string name) => false;
        public static float GetAxis(string name) => 0f;
        public static float GetAxisRaw(string name) => 0f;
        public static bool GetMouseButton(int button) => false;
        public static bool GetMouseButtonDown(int button) => false;
        public static bool GetMouseButtonUp(int button) => false;
        public static Vector3 mousePosition => Vector3.zero;
        public static bool anyKey => false;
        public static bool anyKeyDown => false;
    }

    public enum KeyCode
    {
        None = 0, Backspace = 8, Tab = 9, Return = 13, Escape = 27, Space = 32,
        A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
        Alpha0, Alpha1, Alpha2, Alpha3, Alpha4, Alpha5, Alpha6, Alpha7, Alpha8, Alpha9,
        UpArrow, DownArrow, RightArrow, LeftArrow,
        LeftShift, RightShift, LeftControl, RightControl, LeftAlt, RightAlt,
        LeftCommand, RightCommand, Mouse0, Mouse1, Mouse2,
        F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,
        Keypad0, Keypad1, Keypad2, Keypad3, Keypad4, Keypad5, Keypad6, Keypad7, Keypad8, Keypad9,
        Delete, Insert, Home, End, PageUp, PageDown, Comma, Period, Plus, Minus, Equals
    }

    // ----- Gizmos ---------------------------------------------------------
    public static class Gizmos
    {
        public static Color color { get; set; } = Color.white;
        public static void DrawLine(Vector3 from, Vector3 to) { }
        public static void DrawRay(Vector3 from, Vector3 dir) { }
        public static void DrawWireCube(Vector3 center, Vector3 size) { }
        public static void DrawCube(Vector3 center, Vector3 size) { }
        public static void DrawWireSphere(Vector3 center, float radius) { }
        public static void DrawSphere(Vector3 center, float radius) { }
    }

    // ----- IMGUI (OnGUI) --------------------------------------------------
    public sealed class GUIStyle
    {
        public GUIStyle() { }
        public GUIStyle(GUIStyle other) { }
        public TextAnchor alignment { get; set; }
        public int fontSize { get; set; }
        public FontStyle fontStyle { get; set; }
        public bool wordWrap { get; set; }
    }
    public sealed class GUIContent
    {
        public GUIContent() { }
        public GUIContent(string text) { this.text = text; }
        public string text { get; set; }
    }
    public static class GUI
    {
        public static Color color { get; set; } = Color.white;
        public static Color backgroundColor { get; set; } = Color.white;
        public static Color contentColor { get; set; } = Color.white;
        public static int depth { get; set; }
        public static void Label(Rect position, string text) { }
        public static void Label(Rect position, string text, GUIStyle style) { }
        public static void Box(Rect position, string text) { }
        public static bool Button(Rect position, string text) => false;
        public static string TextField(Rect position, string text) => text;
        public static void DrawTexture(Rect position, Texture image) { }
    }
    public static class GUILayout
    {
        public static void Label(string text) { }
        public static bool Button(string text) => false;
        public static void Space(float pixels) { }
    }

    // ----- Canvas (core) + coroutine yields ------------------------------
    public sealed class Canvas : Behaviour
    {
        public RenderMode renderMode { get; set; }
        public int sortingOrder { get; set; }
        public Camera worldCamera { get; set; }
        public float planeDistance { get; set; } = 100f;
        public bool overrideSorting { get; set; }
        public bool pixelPerfect { get; set; }
    }
    public sealed class CanvasRenderer : Component { }
    public sealed class CanvasGroup : Component { public float alpha { get; set; } = 1f; public bool interactable { get; set; } = true; public bool blocksRaycasts { get; set; } = true; }

    public class YieldInstruction { }
    public sealed class Coroutine : YieldInstruction { }
    public sealed class WaitForSeconds : YieldInstruction { public WaitForSeconds(float seconds) { } }
    public sealed class WaitForSecondsRealtime : YieldInstruction { public WaitForSecondsRealtime(float seconds) { } }
    public sealed class WaitForEndOfFrame : YieldInstruction { }
    public sealed class WaitForFixedUpdate : YieldInstruction { }
    public abstract class CustomYieldInstruction : IEnumerator
    {
        public abstract bool keepWaiting { get; }
        public object Current => null;
        public bool MoveNext() => keepWaiting;
        public void Reset() { }
    }
    public sealed class WaitUntil : CustomYieldInstruction { private readonly Func<bool> _p; public WaitUntil(Func<bool> predicate) { _p = predicate; } public override bool keepWaiting => !_p(); }
    public sealed class WaitWhile : CustomYieldInstruction { private readonly Func<bool> _p; public WaitWhile(Func<bool> predicate) { _p = predicate; } public override bool keepWaiting => _p(); }

    public class ScriptableObject : Object
    {
        public static T CreateInstance<T>() where T : ScriptableObject => (T)Activator.CreateInstance(typeof(T));
        public static ScriptableObject CreateInstance(Type type) => (ScriptableObject)Activator.CreateInstance(type);
    }
}

namespace UnityEngine.Rendering
{
    public enum IndexFormat { UInt16, UInt32 }
}

namespace UnityEngine.Events
{
    public delegate void UnityAction();
    public delegate void UnityAction<T0>(T0 arg0);
    public class UnityEventBase { }
    public class UnityEvent : UnityEventBase
    {
        public void AddListener(UnityAction call) { }
        public void RemoveListener(UnityAction call) { }
        public void RemoveAllListeners() { }
        public void Invoke() { }
    }
    public class UnityEvent<T0> : UnityEventBase
    {
        public void AddListener(UnityAction<T0> call) { }
        public void RemoveListener(UnityAction<T0> call) { }
        public void RemoveAllListeners() { }
        public void Invoke(T0 arg0) { }
    }
}

namespace UnityEngine.UI
{
    using UnityEngine;
    using UnityEngine.Events;

    public enum HorizontalWrapMode { Wrap, Overflow }
    public enum VerticalWrapMode { Truncate, Overflow }

    public class Graphic : MonoBehaviour
    {
        public Color color { get; set; } = Color.white;
        public bool raycastTarget { get; set; } = true;
        public RectTransform rectTransform => GetComponent<RectTransform>();
        public Material material { get; set; }
        public virtual void SetAllDirty() { }
        public void CrossFadeColor(Color targetColor, float duration, bool ignoreTimeScale, bool useAlpha) { }
    }

    public class MaskableGraphic : Graphic { public bool maskable { get; set; } = true; }

    public class Text : MaskableGraphic
    {
        public string text { get; set; } = "";
        public Font font { get; set; }
        public int fontSize { get; set; } = 14;
        public FontStyle fontStyle { get; set; }
        public TextAnchor alignment { get; set; }
        public HorizontalWrapMode horizontalOverflow { get; set; }
        public VerticalWrapMode verticalOverflow { get; set; }
        public bool resizeTextForBestFit { get; set; }
        public bool supportRichText { get; set; } = true;
        public float lineSpacing { get; set; } = 1f;
    }

    public enum ImageType { Simple, Sliced, Tiled, Filled }
    public class Image : MaskableGraphic
    {
        public Sprite sprite { get; set; }
        public ImageType type { get; set; }
        public float fillAmount { get; set; } = 1f;
        public bool preserveAspect { get; set; }
    }
    public class RawImage : MaskableGraphic { public Texture texture { get; set; } }

    public struct ColorBlock
    {
        public Color normalColor;
        public Color highlightedColor;
        public Color pressedColor;
        public Color selectedColor;
        public Color disabledColor;
        public float colorMultiplier;
        public float fadeDuration;
    }

    public class Selectable : MonoBehaviour
    {
        public bool interactable { get; set; } = true;
        public Graphic targetGraphic { get; set; }
        public ColorBlock colors { get; set; }
    }

    public enum SliderDirection { LeftToRight, RightToLeft, BottomToTop, TopToBottom }
    public class Slider : Selectable
    {
        public class SliderEvent : UnityEvent<float> { }
        public float value { get; set; }
        public float minValue { get; set; } = 0f;
        public float maxValue { get; set; } = 1f;
        public bool wholeNumbers { get; set; }
        public SliderDirection direction { get; set; }
        public RectTransform fillRect { get; set; }
        public RectTransform handleRect { get; set; }
        public SliderEvent onValueChanged { get; set; } = new SliderEvent();
    }

    public class Button : Selectable
    {
        public class ButtonClickedEvent : UnityEvent { }
        public ButtonClickedEvent onClick { get; set; } = new ButtonClickedEvent();
    }

    public enum CanvasScalerScaleMode { ConstantPixelSize, ScaleWithScreenSize, ConstantPhysicalSize }
    public enum ScreenMatchMode { MatchWidthOrHeight, Expand, Shrink }
    public class CanvasScaler : MonoBehaviour
    {
        public CanvasScalerScaleMode uiScaleMode { get; set; }
        public Vector2 referenceResolution { get; set; } = new Vector2(800, 600);
        public float scaleFactor { get; set; } = 1f;
        public float matchWidthOrHeight { get; set; }
        public ScreenMatchMode screenMatchMode { get; set; }
        public float referencePixelsPerUnit { get; set; } = 100f;
    }

    public class GraphicRaycaster : MonoBehaviour { }
    public class LayoutElement : MonoBehaviour { public float preferredWidth { get; set; } public float preferredHeight { get; set; } }
}
