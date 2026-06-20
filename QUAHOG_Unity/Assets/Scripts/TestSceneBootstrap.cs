using UnityEngine;
using UnityEngine.UI;

namespace Quahog.SouthCoast
{
    /// <summary>Minimal test-scene initializer for core systems + basic UI.</summary>
    public class TestSceneBootstrap : MonoBehaviour
    {
        /// <summary>Ensures wallet, time, weather, and heat singletons exist.</summary>
        public void InitCoreSystems()
        {
            GameObject mgr = new GameObject("TestScene_Managers");
            mgr.hideFlags = HideFlags.HideInHierarchy;
            EnsureSingleton<PlayerWallet>(mgr);
            EnsureSingleton<TimeOfDayClock>(mgr);
            EnsureSingleton<WeatherController>(mgr);
            EnsureSingleton<HeatManager>(mgr);
            Debug.Log("[TestSceneBootstrap] Core systems initialized.");
        }

        /// <summary>Creates Canvas with cash counter (top-left) + health bar (bottom-left).</summary>
        public void InitMinimalUI()
        {
            GameObject c = new GameObject("TestUI_Canvas");
            Canvas cv = c.AddComponent<Canvas>();
            cv.renderMode = RenderMode.ScreenSpaceOverlay;
            cv.sortingOrder = 100;
            c.AddComponent<CanvasScaler>();
            c.AddComponent<GraphicRaycaster>();

            // Cash counter
            Text cash = MakeText(c, "CashCounter", new Vector2(20f, -20f), Vector2.up, 24, Color.green);
            CashBinder b = cash.gameObject.AddComponent<CashBinder>();
            b.target = cash;

            // Health bar
            GameObject bar = MakePanel(c, "HealthBar", new Vector2(20f, 20f), Vector2.zero, new Color(0.2f, 0.2f, 0.2f, 0.8f));
            GameObject fill = MakePanel(bar, "HealthFill", Vector2.zero, Vector2.zero, Color.red);
            fill.GetComponent<RectTransform>().anchorMax = Vector2.one;
            Slider s = bar.AddComponent<Slider>();
            s.fillRect = fill.GetComponent<RectTransform>();
            s.value = 1f;

            Debug.Log("[TestSceneBootstrap] Minimal UI initialized.");
        }

        /// <summary>Full test-scene setup: core systems then minimal UI.</summary>
        [ContextMenu("Debug/Init Test Scene")]
        public void InitTestScene() { InitCoreSystems(); InitMinimalUI(); }

        // --- Helpers ---

        private void EnsureSingleton<T>(GameObject host) where T : MonoBehaviour
        {
            if (FindAnyObjectByType<T>() != null) return;
            GameObject go = new GameObject(typeof(T).Name);
            go.transform.SetParent(host.transform);
            go.AddComponent<T>();
        }

        private Text MakeText(GameObject parent, string name, Vector2 pos, Vector2 anchor, int fontSize, Color color)
        {
            GameObject go = new GameObject(name);
            go.transform.SetParent(parent.transform, false);
            RectTransform rt = go.AddComponent<RectTransform>();
            rt.anchorMin = rt.anchorMax = rt.pivot = anchor;
            rt.anchoredPosition = pos;
            rt.sizeDelta = new Vector2(200f, 40f);
            Text t = go.AddComponent<Text>();
            t.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            t.fontSize = fontSize;
            t.color = color;
            t.alignment = TextAnchor.UpperLeft;
            return t;
        }

        private GameObject MakePanel(GameObject parent, string name, Vector2 pos, Vector2 anchor, Color color)
        {
            GameObject go = new GameObject(name);
            go.transform.SetParent(parent.transform, false);
            RectTransform rt = go.AddComponent<RectTransform>();
            rt.anchorMin = rt.anchorMax = anchor;
            rt.pivot = anchor;
            rt.anchoredPosition = pos;
            rt.sizeDelta = new Vector2(200f, 20f);
            Image img = go.AddComponent<Image>();
            img.color = color;
            return go;
        }

        /// <summary>Binds Text to PlayerWallet for live cash display updates.</summary>
        private class CashBinder : MonoBehaviour
        {
            [HideInInspector] public Text target;
            void Start()
            {
                if (PlayerWallet.Instance == null) return;
                Refresh(PlayerWallet.Instance.Balance);
                PlayerWallet.Instance.OnBalanceChanged += Refresh;
            }
            void OnDestroy()
            {
                if (PlayerWallet.Instance != null)
                    PlayerWallet.Instance.OnBalanceChanged -= Refresh;
            }
            void Refresh(float balance) { if (target != null) target.text = $"${balance:F0}"; }
        }
    }
}
