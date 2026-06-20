using UnityEngine;

namespace Quahog.SouthCoast
{
    /// <summary>
    /// Drives a full-screen backdrop camera whose clear colour reacts to the
    /// living-world systems: a coastal sky that darkens at night and is tinted by
    /// the current weather. With no 3D content yet, this turns the empty play area
    /// from a black void into an atmospheric backdrop — and gives us a real
    /// Camera to build the world on later.
    /// </summary>
    public class WorldBackdrop : MonoBehaviour
    {
        private static readonly Color Night = new Color(0.02f, 0.03f, 0.08f);
        private static readonly Color Day   = new Color(0.45f, 0.62f, 0.78f);

        private Camera _cam;
        private Color _current;

        private void Start()
        {
            _cam = Camera.main;
            if (_cam == null)
            {
                var go = new GameObject("MainCamera") { tag = "MainCamera" };
                _cam = go.AddComponent<Camera>();
                go.AddComponent<AudioListener>();
            }
            _cam.clearFlags = CameraClearFlags.SolidColor;

            _current = TargetColor();
            _cam.backgroundColor = _current;
        }

        private void Update()
        {
            if (_cam == null) return;
            // Ease toward the target so weather/time changes fade in smoothly.
            _current = Color.Lerp(_current, TargetColor(), Time.deltaTime * 2f);
            _cam.backgroundColor = _current;
        }

        private static Color TargetColor()
        {
            float hour = TimeOfDayClock.Instance != null ? TimeOfDayClock.Instance.CurrentTime : 12f;

            // 0 at midnight, peaks at 1 around noon.
            float daylight = Mathf.Clamp01(Mathf.Sin((hour / 24f) * Mathf.PI * 2f - Mathf.PI * 0.5f) * 0.5f + 0.5f);
            Color sky = Color.Lerp(Night, Day, daylight);

            var weather = WeatherController.Instance != null
                ? WeatherController.Instance.Current
                : WeatherController.WeatherState.Clear;

            switch (weather)
            {
                case WeatherController.WeatherState.DenseFog:
                    sky = Color.Lerp(sky, new Color(0.55f, 0.57f, 0.60f), 0.45f);
                    break;
                case WeatherController.WeatherState.CoastalRain:
                    sky = Color.Lerp(sky * 0.6f, new Color(0.30f, 0.34f, 0.40f), 0.40f);
                    break;
                case WeatherController.WeatherState.Noreaster:
                    sky *= 0.4f;
                    break;
            }
            return sky;
        }
    }
}
