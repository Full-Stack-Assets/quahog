using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

namespace Quahog.SouthCoast
{
    /// <summary>
    /// PostProcessManager controls the full post-processing stack for QUAHOG.
    /// Effects are adapted dynamically based on the current weather state,
    /// time of day, wanted level, and player health to reinforce atmosphere.
    ///
    /// Requires a <see cref="PostProcessVolume"/> (global, priority 100) to be
    /// present in the scene or configured via the inspector. The manager adds
    /// one automatically if none is assigned.
    /// </summary>
    public sealed class PostProcessManager : MonoBehaviour
    {
        // ------------------------------------------------------------------
        // Singleton
        // ------------------------------------------------------------------

        /// <summary>The active PostProcessManager instance.</summary>
        public static PostProcessManager Instance { get; private set; }

        // ------------------------------------------------------------------
        // Inspector fields
        // ------------------------------------------------------------------

        [Header("Volume")]
        [Tooltip("Global PostProcessVolume to drive. Created at runtime if not assigned.")]
        [SerializeField] private PostProcessVolume _globalVolume;

        // ------------------------------------------------------------------
        // Cached effect references
        // ------------------------------------------------------------------

        private Bloom _bloom;
        private Vignette _vignette;
        private ColorGrading _colorGrading;
        private MotionBlur _motionBlur;
        private DepthOfField _depthOfField;
        private AmbientOcclusion _ambientOcclusion;
        private ChromaticAberration _chromaticAberration;
        private Grain _grain;

        // ------------------------------------------------------------------
        // Runtime state
        // ------------------------------------------------------------------

        private WeatherController.WeatherState _currentWeather =
            WeatherController.WeatherState.Clear;

        // ------------------------------------------------------------------
        // Unity lifecycle
        // ------------------------------------------------------------------

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        private void Start()
        {
            InitializeVolume();
            CacheEffects();
            ApplyClearDay();
            SubscribeToEvents();
            Debug.Log("[PostProcessManager] Post-processing stack initialized.");
        }

        private void OnDestroy()
        {
            UnsubscribeFromEvents();

            if (Instance == this)
                Instance = null;
        }

        // ------------------------------------------------------------------
        // Initialization helpers
        // ------------------------------------------------------------------

        /// <summary>
        /// Ensures a global <see cref="PostProcessVolume"/> with a fresh profile
        /// exists. Creates one programmatically if the inspector field is empty.
        /// </summary>
        private void InitializeVolume()
        {
            if (_globalVolume == null)
            {
                _globalVolume = gameObject.AddComponent<PostProcessVolume>();
                _globalVolume.isGlobal = true;
                _globalVolume.priority = 100f;
            }

            if (_globalVolume.profile == null)
                _globalVolume.profile = ScriptableObject.CreateInstance<PostProcessProfile>();
        }

        /// <summary>
        /// Retrieves each effect from the volume profile, adding it if absent.
        /// </summary>
        private void CacheEffects()
        {
            _bloom = GetOrAddEffect<Bloom>();
            _vignette = GetOrAddEffect<Vignette>();
            _colorGrading = GetOrAddEffect<ColorGrading>();
            _motionBlur = GetOrAddEffect<MotionBlur>();
            _depthOfField = GetOrAddEffect<DepthOfField>();
            _ambientOcclusion = GetOrAddEffect<AmbientOcclusion>();
            _chromaticAberration = GetOrAddEffect<ChromaticAberration>();
            _grain = GetOrAddEffect<Grain>();
        }

        private T GetOrAddEffect<T>() where T : PostProcessEffectSettings
        {
            if (!_globalVolume.profile.TryGetSettings(out T effect))
                effect = _globalVolume.profile.AddSettings<T>();
            return effect;
        }

        // ------------------------------------------------------------------
        // Event wiring
        // ------------------------------------------------------------------

        private void SubscribeToEvents()
        {
            if (WeatherController.Instance != null)
                WeatherController.Instance.OnWeatherChanged += OnWeatherChanged;

            if (TimeOfDayClock.Instance != null)
                TimeOfDayClock.Instance.OnTimeChanged += OnTimeChanged;

            if (HeatManager.Instance != null)
                HeatManager.Instance.OnWantedLevelChanged += OnWantedLevelChanged;
        }

        private void UnsubscribeFromEvents()
        {
            if (WeatherController.Instance != null)
                WeatherController.Instance.OnWeatherChanged -= OnWeatherChanged;

            if (TimeOfDayClock.Instance != null)
                TimeOfDayClock.Instance.OnTimeChanged -= OnTimeChanged;

            if (HeatManager.Instance != null)
                HeatManager.Instance.OnWantedLevelChanged -= OnWantedLevelChanged;
        }

        // ------------------------------------------------------------------
        // Event handlers
        // ------------------------------------------------------------------

        /// <summary>Reacts to weather transitions by blending to a matching preset.</summary>
        private void OnWeatherChanged(WeatherController.WeatherState newState)
        {
            _currentWeather = newState;

            switch (newState)
            {
                case WeatherController.WeatherState.Clear:
                    ApplyClearDay();
                    break;
                case WeatherController.WeatherState.CoastalRain:
                    ApplyCoastalRain();
                    break;
                case WeatherController.WeatherState.Noreaster:
                    ApplyNoreaster();
                    break;
                case WeatherController.WeatherState.DenseFog:
                    ApplyDenseFog();
                    break;
                default:
                    ApplyClearDay();
                    break;
            }
        }

        /// <summary>Adjusts color grading warmth/coolness with the time of day (0–24 h).</summary>
        private void OnTimeChanged(float hour)
        {
            if (_colorGrading == null) return;

            // Dawn (5–7 h): warm amber tones
            // Noon (10–14 h): neutral with a slight warm tint
            // Dusk (17–19 h): deep orange
            // Night (20–4 h): cool blue tones
            float temperature;
            if (hour >= 5f && hour < 7f)
                temperature = Mathf.Lerp(0f, 20f, (hour - 5f) / 2f);    // dawn warm-up
            else if (hour >= 7f && hour < 10f)
                temperature = Mathf.Lerp(20f, 5f, (hour - 7f) / 3f);    // morning
            else if (hour >= 10f && hour < 17f)
                temperature = 5f;                                          // neutral day
            else if (hour >= 17f && hour < 19f)
                temperature = Mathf.Lerp(5f, 30f, (hour - 17f) / 2f);   // dusk
            else if (hour >= 19f && hour < 21f)
                temperature = Mathf.Lerp(30f, -20f, (hour - 19f) / 2f); // twilight
            else
                temperature = -20f;                                        // night

            _colorGrading.enabled.value = true;
            _colorGrading.enabled.overrideState = true;
            _colorGrading.temperature.value = temperature;
            _colorGrading.temperature.overrideState = true;
        }

        /// <summary>Intensifies vignette and chromatic aberration with wanted level.</summary>
        private void OnWantedLevelChanged(int wantedLevel)
        {
            if (_vignette == null || _chromaticAberration == null) return;

            // Vignette tightens as heat rises (0 → 5 stars)
            float vignetteIntensity = Mathf.Lerp(0.2f, 0.55f, wantedLevel / 5f);
            _vignette.enabled.value = true;
            _vignette.enabled.overrideState = true;
            _vignette.intensity.value = vignetteIntensity;
            _vignette.intensity.overrideState = true;

            // Chromatic aberration adds a "panic" feel at high wanted levels
            float aberration = wantedLevel >= 4 ? Mathf.Lerp(0f, 0.6f, (wantedLevel - 3f) / 2f) : 0f;
            _chromaticAberration.enabled.value = aberration > 0f;
            _chromaticAberration.enabled.overrideState = true;
            _chromaticAberration.intensity.value = aberration;
            _chromaticAberration.intensity.overrideState = true;
        }

        // ------------------------------------------------------------------
        // Weather presets
        // ------------------------------------------------------------------

        /// <summary>
        /// Applies the clear-day post-processing preset: subtle bloom, light vignette,
        /// neutral colour grading, no grain.
        /// </summary>
        public void ApplyClearDay()
        {
            SetBloom(enabled: true, threshold: 1.1f, intensity: 0.4f, scatter: 0.7f);
            SetVignette(enabled: true, intensity: 0.25f, smoothness: 0.35f);
            SetColorGrading(enabled: true, postExposure: 0f, contrast: 5f,
                            saturation: 10f, temperature: 5f);
            SetAmbientOcclusion(enabled: true, intensity: 0.5f, radius: 0.3f);
            SetGrain(enabled: false, intensity: 0f);
            SetMotionBlur(enabled: false, shutterAngle: 270f);

            Debug.Log("[PostProcessManager] Applied ClearDay post-process preset.");
        }

        /// <summary>
        /// Applies the coastal-rain preset: desaturated palette, elevated grain,
        /// stronger vignette, and reduced bloom to mimic overcast light.
        /// </summary>
        public void ApplyCoastalRain()
        {
            SetBloom(enabled: true, threshold: 1.0f, intensity: 0.6f, scatter: 0.8f);
            SetVignette(enabled: true, intensity: 0.38f, smoothness: 0.5f);
            SetColorGrading(enabled: true, postExposure: -0.15f, contrast: 10f,
                            saturation: -20f, temperature: -5f);
            SetAmbientOcclusion(enabled: true, intensity: 0.7f, radius: 0.4f);
            SetGrain(enabled: true, intensity: 0.2f, size: 1.2f);
            SetMotionBlur(enabled: true, shutterAngle: 180f);

            Debug.Log("[PostProcessManager] Applied CoastalRain post-process preset.");
        }

        /// <summary>
        /// Applies the nor'easter preset: heavy desaturation, intense grain,
        /// strong motion blur and vignette to convey storm chaos.
        /// </summary>
        public void ApplyNoreaster()
        {
            SetBloom(enabled: true, threshold: 0.9f, intensity: 1.0f, scatter: 0.9f);
            SetVignette(enabled: true, intensity: 0.5f, smoothness: 0.6f);
            SetColorGrading(enabled: true, postExposure: -0.3f, contrast: 15f,
                            saturation: -40f, temperature: -10f);
            SetAmbientOcclusion(enabled: true, intensity: 0.8f, radius: 0.5f);
            SetGrain(enabled: true, intensity: 0.4f, size: 1.5f);
            SetMotionBlur(enabled: true, shutterAngle: 240f);

            Debug.Log("[PostProcessManager] Applied Noreaster post-process preset.");
        }

        /// <summary>
        /// Applies the dense-fog preset: heavily desaturated, diffuse bloom,
        /// reduced depth clarity, and a strong cool colour shift.
        /// </summary>
        public void ApplyDenseFog()
        {
            SetBloom(enabled: true, threshold: 0.8f, intensity: 1.2f, scatter: 0.95f);
            SetVignette(enabled: true, intensity: 0.42f, smoothness: 0.8f);
            SetColorGrading(enabled: true, postExposure: -0.2f, contrast: -5f,
                            saturation: -30f, temperature: -15f);
            SetAmbientOcclusion(enabled: false, intensity: 0f, radius: 0.3f);
            SetGrain(enabled: true, intensity: 0.15f, size: 1.0f);
            SetMotionBlur(enabled: false, shutterAngle: 270f);

            Debug.Log("[PostProcessManager] Applied DenseFog post-process preset.");
        }

        // ------------------------------------------------------------------
        // Public API — direct effect control
        // ------------------------------------------------------------------

        /// <summary>
        /// Applies a temporary health-critical vignette pulse (e.g., when the
        /// player drops below 25 % health).
        /// </summary>
        /// <param name="healthNormalized">Player health ratio in [0, 1].</param>
        public void ApplyHealthVignette(float healthNormalized)
        {
            if (_vignette == null) return;

            bool critical = healthNormalized < 0.25f;
            _vignette.enabled.value = true;
            _vignette.enabled.overrideState = true;
            _vignette.color.value = critical ? new Color(0.5f, 0f, 0f, 1f) : Color.black;
            _vignette.color.overrideState = true;

            float baseIntensity = _currentWeather == WeatherController.WeatherState.DenseFog
                ? 0.42f : 0.25f;
            _vignette.intensity.value = critical
                ? Mathf.Lerp(0.6f, 0.8f, 1f - healthNormalized / 0.25f)
                : baseIntensity;
            _vignette.intensity.overrideState = true;
        }

        /// <summary>
        /// Triggers a brief chromatic-aberration and screen-shake stand-in for
        /// impact feedback (e.g., after receiving damage).
        /// </summary>
        public void TriggerImpactFlash()
        {
            if (_chromaticAberration == null) return;

            _chromaticAberration.enabled.value = true;
            _chromaticAberration.enabled.overrideState = true;
            _chromaticAberration.intensity.value = 0.8f;
            _chromaticAberration.intensity.overrideState = true;

            // Restore after one frame via coroutine (kept minimal, no Invoke dependency)
            StartCoroutine(ResetChromaticAberrationAfterFrames(3));
        }

        // ------------------------------------------------------------------
        // Internal setters
        // ------------------------------------------------------------------

        private void SetBloom(bool enabled, float threshold, float intensity, float scatter)
        {
            if (_bloom == null) return;
            _bloom.enabled.value = enabled;
            _bloom.enabled.overrideState = true;
            _bloom.threshold.value = threshold;
            _bloom.threshold.overrideState = true;
            _bloom.intensity.value = intensity;
            _bloom.intensity.overrideState = true;
            _bloom.scatter.value = scatter;
            _bloom.scatter.overrideState = true;
        }

        private void SetVignette(bool enabled, float intensity, float smoothness)
        {
            if (_vignette == null) return;
            _vignette.enabled.value = enabled;
            _vignette.enabled.overrideState = true;
            _vignette.intensity.value = intensity;
            _vignette.intensity.overrideState = true;
            _vignette.smoothness.value = smoothness;
            _vignette.smoothness.overrideState = true;
        }

        private void SetColorGrading(bool enabled, float postExposure, float contrast,
                                     float saturation, float temperature)
        {
            if (_colorGrading == null) return;
            _colorGrading.enabled.value = enabled;
            _colorGrading.enabled.overrideState = true;
            _colorGrading.postExposure.value = postExposure;
            _colorGrading.postExposure.overrideState = true;
            _colorGrading.contrast.value = contrast;
            _colorGrading.contrast.overrideState = true;
            _colorGrading.saturation.value = saturation;
            _colorGrading.saturation.overrideState = true;
            _colorGrading.temperature.value = temperature;
            _colorGrading.temperature.overrideState = true;
        }

        private void SetAmbientOcclusion(bool enabled, float intensity, float radius)
        {
            if (_ambientOcclusion == null) return;
            _ambientOcclusion.enabled.value = enabled;
            _ambientOcclusion.enabled.overrideState = true;
            _ambientOcclusion.intensity.value = intensity;
            _ambientOcclusion.intensity.overrideState = true;
            _ambientOcclusion.radius.value = radius;
            _ambientOcclusion.radius.overrideState = true;
        }

        private void SetGrain(bool enabled, float intensity, float size = 1f)
        {
            if (_grain == null) return;
            _grain.enabled.value = enabled;
            _grain.enabled.overrideState = true;
            _grain.intensity.value = intensity;
            _grain.intensity.overrideState = true;
            _grain.size.value = size;
            _grain.size.overrideState = true;
        }

        private void SetMotionBlur(bool enabled, float shutterAngle)
        {
            if (_motionBlur == null) return;
            _motionBlur.enabled.value = enabled;
            _motionBlur.enabled.overrideState = true;
            _motionBlur.shutterAngle.value = shutterAngle;
            _motionBlur.shutterAngle.overrideState = true;
        }

        private System.Collections.IEnumerator ResetChromaticAberrationAfterFrames(int frames)
        {
            // Cache wanted level before yielding; HeatManager may be destroyed by the time
            // the coroutine resumes.
            int wantedLevel = HeatManager.Instance != null ? HeatManager.Instance.WantedLevel : 0;

            for (int i = 0; i < frames; i++)
                yield return null;

            if (_chromaticAberration == null) yield break;

            // Restore to the wanted-level-appropriate value captured before the yield.
            float restored = wantedLevel >= 4 ? Mathf.Lerp(0f, 0.6f, (wantedLevel - 3f) / 2f) : 0f;
            _chromaticAberration.intensity.value = restored;
            _chromaticAberration.enabled.value = restored > 0f;
        }
    }
}
