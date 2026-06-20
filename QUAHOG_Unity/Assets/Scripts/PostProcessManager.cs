using UnityEngine;

namespace Quahog.SouthCoast
{
    /// <summary>
    /// Atmosphere coordinator placeholder.
    ///
    /// The previous implementation depended on the legacy Post Processing Stack
    /// v2 (<c>UnityEngine.Rendering.PostProcessing</c>), which is not installed
    /// and is not compatible with URP — URP drives post-processing through its
    /// own Volume framework. To keep the project building, this is intentionally
    /// a no-op shim: it preserves the singleton the rest of the game expects and
    /// gives us one place to reimplement weather/time-of-day atmosphere on URP
    /// Volumes later (see roadmap "M6 — polish").
    /// </summary>
    public sealed class PostProcessManager : MonoBehaviour
    {
        /// <summary>The active PostProcessManager instance.</summary>
        public static PostProcessManager Instance { get; private set; }

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(this);
                return;
            }
            Instance = this;
        }

        private void OnDestroy()
        {
            if (Instance == this) Instance = null;
        }

        /// <summary>
        /// Hook for future URP-Volume-based atmosphere. No-op until the Volume
        /// stack is wired up; kept so callers can target a stable API now.
        /// </summary>
        public void ApplyWeather(WeatherController.WeatherState weather)
        {
            // Intentionally empty — URP Volume post-processing not yet implemented.
        }
    }
}
