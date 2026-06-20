using System.Text;
using UnityEngine;
using UnityEngine.UI;

namespace Quahog.SouthCoast
{
    /// <summary>
    /// Top-right "living world" HUD: the day/time clock, the current weather, and
    /// the wanted-level stars, all driven by the manager singletons. A few
    /// keyboard controls make the systems easy to exercise in a player build:
    ///   [W] cycle weather   [Up] +wanted   [Down] clear heat   [T] +1 hour
    /// </summary>
    public class WorldHud : MonoBehaviour
    {
        private Text _timeText;
        private Text _weatherText;
        private Text _wantedText;
        private Font _font;

        private GameObject _controlsPanel;   // holds the four action buttons
        private Text _toggleLabel;           // label on the show/hide toggle
        private bool _controlsVisible = true;

        private void Start()
        {
            _font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            BuildUi();
            Hook();

            RefreshWeather(WeatherController.Instance != null
                ? WeatherController.Instance.Current
                : WeatherController.WeatherState.Clear);
            RefreshWanted(HeatManager.Instance != null ? HeatManager.Instance.WantedLevel : 0);
        }

        private void OnDestroy() => Unhook();

        private void Update()
        {
            // The clock advances continuously, so refresh it every frame.
            if (TimeOfDayClock.Instance != null && _timeText != null)
            {
                _timeText.text =
                    $"DAY {TimeOfDayClock.Instance.CurrentDay} · {TimeOfDayClock.Instance.GetTimeString()}";
            }

            HandleInput();
        }

        // -- UI construction -------------------------------------------------

        private void BuildUi()
        {
            var canvasGo = new GameObject("WorldHud_Canvas");
            canvasGo.transform.SetParent(transform, false);
            var canvas = canvasGo.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 90;
            canvasGo.AddComponent<CanvasScaler>();
            canvasGo.AddComponent<GraphicRaycaster>();

            _timeText    = MakeLabel(canvasGo, "TimeText",    new Vector2(-20f, -20f),  28, new Color(1f, 0.95f, 0.6f));
            _weatherText = MakeLabel(canvasGo, "WeatherText", new Vector2(-20f, -56f),  20, new Color(0.7f, 0.85f, 1f));
            _wantedText  = MakeLabel(canvasGo, "WantedText",  new Vector2(-20f, -88f),  24, new Color(1f, 0.85f, 0.2f));

            Text help = MakeLabel(canvasGo, "HelpText", new Vector2(-20f, -124f), 14, new Color(0.7f, 0.7f, 0.7f));
            help.text = "tap a button, or use:  [W]  [↑]  [↓]  [T]";

            // Tap controls live in a panel that can be hidden via the toggle below.
            _controlsPanel = new GameObject("ControlButtons");
            _controlsPanel.transform.SetParent(canvasGo.transform, false);
            var panelRt = _controlsPanel.AddComponent<RectTransform>();
            panelRt.anchorMin = Vector2.zero;
            panelRt.anchorMax = Vector2.one;
            panelRt.offsetMin = panelRt.offsetMax = Vector2.zero;

            MakeButton(_controlsPanel, "Weather",  new Vector2(-20f, 200f), CycleWeather);
            MakeButton(_controlsPanel, "+ Wanted", new Vector2(-20f, 152f), AddWanted);
            MakeButton(_controlsPanel, "Clear",    new Vector2(-20f, 104f), ClearHeat);
            MakeButton(_controlsPanel, "+1 Hour",  new Vector2(-20f, 56f),  AdvanceHour);

            // Always-visible toggle that hides/shows the panel above it.
            GameObject toggle = MakeButton(canvasGo, ControlsLabel(true), new Vector2(-20f, 8f), ToggleControls);
            _toggleLabel = toggle.GetComponentInChildren<Text>();
        }

        private GameObject MakeButton(GameObject parent, string label, Vector2 pos, UnityEngine.Events.UnityAction action)
        {
            var go = new GameObject(label + "_Btn");
            go.transform.SetParent(parent.transform, false);

            var rt = go.AddComponent<RectTransform>();
            rt.anchorMin = rt.anchorMax = rt.pivot = Vector2.right; // bottom-right (1,0)
            rt.anchoredPosition = pos;
            rt.sizeDelta = new Vector2(140f, 42f);

            var img = go.AddComponent<Image>();
            img.color = new Color(0.10f, 0.15f, 0.20f, 0.92f);

            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            btn.onClick.AddListener(action);
            ColorBlock cb = btn.colors;
            cb.highlightedColor = new Color(0.20f, 0.30f, 0.40f, 1f);
            cb.pressedColor = new Color(0.30f, 0.45f, 0.60f, 1f);
            btn.colors = cb;

            var txtGo = new GameObject("Label");
            txtGo.transform.SetParent(go.transform, false);
            var trt = txtGo.AddComponent<RectTransform>();
            trt.anchorMin = Vector2.zero;
            trt.anchorMax = Vector2.one;
            trt.offsetMin = trt.offsetMax = Vector2.zero;

            var t = txtGo.AddComponent<Text>();
            t.font = _font;
            t.fontSize = 18;
            t.color = new Color(0.85f, 0.92f, 0.97f);
            t.alignment = TextAnchor.MiddleCenter;
            t.text = label;
            return go;
        }

        private void ToggleControls()
        {
            _controlsVisible = !_controlsVisible;
            if (_controlsPanel != null) _controlsPanel.SetActive(_controlsVisible);
            if (_toggleLabel != null) _toggleLabel.text = ControlsLabel(_controlsVisible);
        }

        private static string ControlsLabel(bool visible) => visible ? "Controls ▾" : "Controls ▴";

        private Text MakeLabel(GameObject parent, string name, Vector2 pos, int size, Color color)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent.transform, false);

            var rt = go.AddComponent<RectTransform>();
            rt.anchorMin = rt.anchorMax = rt.pivot = Vector2.one; // anchor to top-right
            rt.anchoredPosition = pos;
            rt.sizeDelta = new Vector2(380f, 34f);

            var t = go.AddComponent<Text>();
            t.font = _font;
            t.fontSize = size;
            t.color = color;
            t.alignment = TextAnchor.UpperRight;
            t.horizontalOverflow = HorizontalWrapMode.Overflow;
            return t;
        }

        // -- Input demo controls ---------------------------------------------

        private void HandleInput()
        {
            if (Input.GetKeyDown(KeyCode.W)) CycleWeather();
            if (Input.GetKeyDown(KeyCode.UpArrow)) AddWanted();
            if (Input.GetKeyDown(KeyCode.DownArrow)) ClearHeat();
            if (Input.GetKeyDown(KeyCode.T)) AdvanceHour();
        }

        // Shared actions driven by both keyboard and the on-screen buttons.

        private void CycleWeather()
        {
            if (WeatherController.Instance == null) return;
            var next = (WeatherController.WeatherState)
                (((int)WeatherController.Instance.Current + 1) % 4);
            WeatherController.Instance.ForceState(next);
        }

        private void AddWanted()
        {
            if (HeatManager.Instance != null) HeatManager.Instance.AddWantedLevel(1);
        }

        private void ClearHeat()
        {
            if (HeatManager.Instance != null) HeatManager.Instance.ClearHeat();
        }

        private void AdvanceHour()
        {
            if (TimeOfDayClock.Instance != null) TimeOfDayClock.Instance.AdvanceHours(1);
        }

        // -- Event listeners -------------------------------------------------

        private void Hook()
        {
            if (WeatherController.Instance != null)
                WeatherController.Instance.OnWeatherChanged += RefreshWeather;
            if (HeatManager.Instance != null)
                HeatManager.Instance.OnWantedLevelChanged += RefreshWanted;
        }

        private void Unhook()
        {
            if (WeatherController.Instance != null)
                WeatherController.Instance.OnWeatherChanged -= RefreshWeather;
            if (HeatManager.Instance != null)
                HeatManager.Instance.OnWantedLevelChanged -= RefreshWanted;
        }

        private void RefreshWeather(WeatherController.WeatherState state)
        {
            if (_weatherText != null) _weatherText.text = WeatherLabel(state);
        }

        private static string WeatherLabel(WeatherController.WeatherState state)
        {
            switch (state)
            {
                case WeatherController.WeatherState.Clear:       return "CLEAR SKIES";
                case WeatherController.WeatherState.DenseFog:    return "DENSE FOG";
                case WeatherController.WeatherState.CoastalRain: return "COASTAL RAIN";
                case WeatherController.WeatherState.Noreaster:   return "NOR'EASTER";
                default:                                         return "CLEAR SKIES";
            }
        }

        private void RefreshWanted(int level)
        {
            if (_wantedText == null) return;

            var sb = new StringBuilder("WANTED  ");
            for (int i = 0; i < 5; i++) sb.Append(i < level ? '★' : '☆'); // ★ / ☆
            _wantedText.text = sb.ToString();
        }
    }
}
