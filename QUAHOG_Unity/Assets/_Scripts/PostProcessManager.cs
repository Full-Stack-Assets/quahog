using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

namespace Quahog.SouthCoast
{
    /// <summary>
    /// Singleton manager for the full post-processing stack.
    /// Controls Bloom, Depth of Field, Color Grading, and Vignette effects.
    /// Exposes per-district profiles and responds to weather/time-of-day changes.
    /// Requires a PostProcessVolume component on the same GameObject with a
    /// PostProcessProfile that contains Bloom, DepthOfField, ColorGrading,
    /// and Vignette effect overrides.
    /// </summary>
    [RequireComponent(typeof(PostProcessVolume))]
    public class PostProcessManager : MonoBehaviour
    {
        // ------------------------------------------------------------------
        // Singleton
        // ------------------------------------------------------------------

        /// <summary>Global singleton instance.</summary>
        public static PostProcessManager Instance { get; private set; }

        // ------------------------------------------------------------------
        // Enums
        // ------------------------------------------------------------------

        /// <summary>
        /// In-game districts, each carrying its own post-process colour grade.
        /// </summary>
        public enum District
        {
            NewSefton,
            Dighton,
            TauntonHill,
            Sawyer
        }

        /// <summary>
        /// Weather state that drives atmospheric post-process overrides.
        /// Must match WeatherController.WeatherState ordinal values.
        /// </summary>
        public enum WeatherState
        {
            Clear,
            DenseFog,
            CoastalRain,
            Noreaster
        }

        // ------------------------------------------------------------------
        // Inspector — Volume reference
        // ------------------------------------------------------------------

        [Header("Post-Process Volume")]
        [Tooltip("PostProcessVolume used for runtime parameter overrides. " +
                 "Populated from the component on this GameObject if left empty.")]
        [SerializeField] private PostProcessVolume postProcessVolume;

        // ------------------------------------------------------------------
        // Inspector — Transition
        // ------------------------------------------------------------------

        [Header("Transition")]
        [Tooltip("Seconds to blend between district or weather profiles.")]
        [SerializeField] private float blendDuration = 1.5f;

        // ------------------------------------------------------------------
        // Inspector — Bloom
        // ------------------------------------------------------------------

        [Header("Bloom — Base")]
        [Tooltip("Bloom intensity used during Clear weather at noon.")]
        [SerializeField] private float bloomBaseIntensity = 1.0f;

        [Tooltip("Bloom threshold (luminance cut-off).")]
        [SerializeField] private float bloomThreshold = 1.1f;

        [Header("Bloom — Weather Overrides")]
        [Tooltip("Bloom intensity multiplier during DenseFog.")]
        [SerializeField] private float bloomFogMultiplier = 0.5f;

        [Tooltip("Bloom intensity multiplier during CoastalRain.")]
        [SerializeField] private float bloomRainMultiplier = 0.7f;

        [Tooltip("Bloom intensity multiplier during Noreaster.")]
        [SerializeField] private float bloomNoreasterMultiplier = 0.3f;

        [Header("Bloom — Time of Day")]
        [Tooltip("Bloom intensity multiplier at night (hour 20–06).")]
        [SerializeField] private float bloomNightMultiplier = 1.8f;

        // ------------------------------------------------------------------
        // Inspector — Depth of Field
        // ------------------------------------------------------------------

        [Header("Depth of Field")]
        [Tooltip("Enable depth-of-field during aiming / cutscenes.")]
        [SerializeField] private bool dofEnabled = false;

        [Tooltip("Focal distance in world units.")]
        [SerializeField] private float dofFocalLength = 70f;

        [Tooltip("Lens aperture (lower = shallower depth of field).")]
        [SerializeField] private float dofAperture = 5.6f;

        // ------------------------------------------------------------------
        // Inspector — Color Grading (per-district)
        // ------------------------------------------------------------------

        [Header("Color Grading — New Sefton (harbour, blue-white)")]
        [SerializeField] private float newSeftonTemperature  = -8f;
        [SerializeField] private float newSeftonTint         = 2f;
        [SerializeField] private float newSeftonSaturation   = 10f;
        [SerializeField] private float newSeftonContrast     = 5f;

        [Header("Color Grading — Dighton (amber/copper)")]
        [SerializeField] private float dightonTemperature    = 12f;
        [SerializeField] private float dightonTint           = -3f;
        [SerializeField] private float dightonSaturation     = 15f;
        [SerializeField] private float dightonContrast       = 8f;

        [Header("Color Grading — Taunton Hill (cyan/industrial)")]
        [SerializeField] private float tauntonTemperature    = -15f;
        [SerializeField] private float tauntonTint           = 5f;
        [SerializeField] private float tauntonSaturation     = -5f;
        [SerializeField] private float tauntonContrast       = 12f;

        [Header("Color Grading — Sawyer (violet/underground)")]
        [SerializeField] private float sawyerTemperature     = -20f;
        [SerializeField] private float sawyerTint            = 10f;
        [SerializeField] private float sawyerSaturation      = 20f;
        [SerializeField] private float sawyerContrast        = 15f;

        // ------------------------------------------------------------------
        // Inspector — Vignette
        // ------------------------------------------------------------------

        [Header("Vignette")]
        [Tooltip("Vignette intensity at rest.")]
        [SerializeField] private float vignetteBaseIntensity = 0.25f;

        [Tooltip("Vignette intensity during combat (raised by HeatManager).")]
        [SerializeField] private float vignetteCombatIntensity = 0.45f;

        // ------------------------------------------------------------------
        // Runtime state
        // ------------------------------------------------------------------

        private District     _currentDistrict = District.NewSefton;
        private WeatherState _currentWeather  = WeatherState.Clear;

        // Cached effect handles (set in Awake; null-safe guarded throughout).
        private Bloom        _bloom;
        private DepthOfField _dof;
        private ColorGrading _colorGrading;
        private Vignette     _vignette;

        // Lerp state for smooth district transitions.
        private float _blendT        = 1f;
        private bool  _isTransitioning = false;

        // Snapshot of the color-grading values we are blending FROM.
        private float _fromTemperature;
        private float _fromTint;
        private float _fromSaturation;
        private float _fromContrast;

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

            if (postProcessVolume == null)
                postProcessVolume = GetComponent<PostProcessVolume>();

            CacheEffects();
            ApplyDistrict(_currentDistrict, instant: true);
            ApplyWeather(_currentWeather);
        }

        private void Update()
        {
            if (_isTransitioning)
                TickBlend();
        }

        // ------------------------------------------------------------------
        // Public API — District
        // ------------------------------------------------------------------

        /// <summary>
        /// Transition to a new district's color grade, blending over
        /// <see cref="blendDuration"/> seconds.
        /// </summary>
        public void SetDistrict(District district)
        {
            if (district == _currentDistrict && !_isTransitioning)
                return;

            SnapshotCurrentGrade();
            _currentDistrict  = district;
            _blendT           = 0f;
            _isTransitioning  = true;
        }

        /// <returns>The currently active district.</returns>
        public District GetDistrict() => _currentDistrict;

        // ------------------------------------------------------------------
        // Public API — Weather
        // ------------------------------------------------------------------

        /// <summary>
        /// Apply a weather-driven bloom and vignette override immediately.
        /// </summary>
        public void SetWeather(WeatherState weather)
        {
            _currentWeather = weather;
            ApplyWeather(weather);
        }

        /// <returns>The currently active weather state.</returns>
        public WeatherState GetWeather() => _currentWeather;

        // ------------------------------------------------------------------
        // Public API — Time of Day
        // ------------------------------------------------------------------

        /// <summary>
        /// Called by TimeOfDayClock when the in-game hour changes.
        /// Adjusts bloom intensity for day / night cycle.
        /// </summary>
        /// <param name="hour">In-game hour (0–23).</param>
        public void OnHourChanged(int hour)
        {
            if (_bloom == null)
                return;

            bool isNight = hour >= 20 || hour < 6;
            float weatherMultiplier = WeatherBloomMultiplier(_currentWeather);
            float targetIntensity   = bloomBaseIntensity
                                      * weatherMultiplier
                                      * (isNight ? bloomNightMultiplier : 1f);

            _bloom.intensity.Override(targetIntensity);
        }

        // ------------------------------------------------------------------
        // Public API — Depth of Field
        // ------------------------------------------------------------------

        /// <summary>Enable or disable depth-of-field (e.g. during aiming).</summary>
        public void SetDepthOfField(bool enabled, float focalLength = -1f, float aperture = -1f)
        {
            if (_dof == null)
                return;

            _dof.active = enabled;
            if (enabled)
            {
                _dof.focusDistance.Override(focalLength > 0f ? focalLength : dofFocalLength);
                _dof.aperture.Override(aperture > 0f ? aperture : dofAperture);
            }
        }

        // ------------------------------------------------------------------
        // Public API — Vignette
        // ------------------------------------------------------------------

        /// <summary>
        /// Elevate vignette intensity to signal combat tension, then restore
        /// the base value when calm.
        /// </summary>
        public void SetCombatVignette(bool active)
        {
            if (_vignette == null)
                return;

            _vignette.intensity.Override(active ? vignetteCombatIntensity : vignetteBaseIntensity);
        }

        // ------------------------------------------------------------------
        // Internal — Effect cache
        // ------------------------------------------------------------------

        private void CacheEffects()
        {
            if (postProcessVolume == null || postProcessVolume.profile == null)
            {
                Debug.LogWarning("[PostProcessManager] No PostProcessVolume or profile assigned.");
                return;
            }

            postProcessVolume.profile.TryGetSettings(out _bloom);
            postProcessVolume.profile.TryGetSettings(out _dof);
            postProcessVolume.profile.TryGetSettings(out _colorGrading);
            postProcessVolume.profile.TryGetSettings(out _vignette);
        }

        // ------------------------------------------------------------------
        // Internal — District color grade application
        // ------------------------------------------------------------------

        private void ApplyDistrict(District district, bool instant = false)
        {
            if (_colorGrading == null)
                return;

            GetDistrictGradeValues(district,
                out float temperature, out float tint,
                out float saturation,  out float contrast);

            if (instant)
            {
                _colorGrading.temperature.Override(temperature);
                _colorGrading.tint.Override(tint);
                _colorGrading.saturation.Override(saturation);
                _colorGrading.contrast.Override(contrast);
            }
        }

        private void TickBlend()
        {
            _blendT += Time.deltaTime / Mathf.Max(blendDuration, 0.001f);

            if (_blendT >= 1f)
            {
                _blendT          = 1f;
                _isTransitioning = false;
            }

            GetDistrictGradeValues(_currentDistrict,
                out float toTemp, out float toTint,
                out float toSat,  out float toCon);

            float t = Mathf.SmoothStep(0f, 1f, _blendT);

            if (_colorGrading != null)
            {
                _colorGrading.temperature.Override(Mathf.Lerp(_fromTemperature, toTemp, t));
                _colorGrading.tint.Override(Mathf.Lerp(_fromTint, toTint, t));
                _colorGrading.saturation.Override(Mathf.Lerp(_fromSaturation, toSat, t));
                _colorGrading.contrast.Override(Mathf.Lerp(_fromContrast, toCon, t));
            }
        }

        private void SnapshotCurrentGrade()
        {
            if (_colorGrading != null)
            {
                _fromTemperature = _colorGrading.temperature.value;
                _fromTint        = _colorGrading.tint.value;
                _fromSaturation  = _colorGrading.saturation.value;
                _fromContrast    = _colorGrading.contrast.value;
            }
            else
            {
                GetDistrictGradeValues(_currentDistrict,
                    out _fromTemperature, out _fromTint,
                    out _fromSaturation,  out _fromContrast);
            }
        }

        private void GetDistrictGradeValues(District district,
            out float temperature, out float tint,
            out float saturation,  out float contrast)
        {
            switch (district)
            {
                case District.Dighton:
                    temperature = dightonTemperature;
                    tint        = dightonTint;
                    saturation  = dightonSaturation;
                    contrast    = dightonContrast;
                    break;
                case District.TauntonHill:
                    temperature = tauntonTemperature;
                    tint        = tauntonTint;
                    saturation  = tauntonSaturation;
                    contrast    = tauntonContrast;
                    break;
                case District.Sawyer:
                    temperature = sawyerTemperature;
                    tint        = sawyerTint;
                    saturation  = sawyerSaturation;
                    contrast    = sawyerContrast;
                    break;
                default: // NewSefton
                    temperature = newSeftonTemperature;
                    tint        = newSeftonTint;
                    saturation  = newSeftonSaturation;
                    contrast    = newSeftonContrast;
                    break;
            }
        }

        // ------------------------------------------------------------------
        // Internal — Weather bloom / vignette
        // ------------------------------------------------------------------

        private void ApplyWeather(WeatherState weather)
        {
            if (_bloom == null)
                return;

            float multiplier = WeatherBloomMultiplier(weather);
            _bloom.intensity.Override(bloomBaseIntensity * multiplier);
            _bloom.threshold.Override(bloomThreshold);

            if (_vignette != null)
                _vignette.intensity.Override(vignetteBaseIntensity);
        }

        private float WeatherBloomMultiplier(WeatherState weather)
        {
            switch (weather)
            {
                case WeatherState.DenseFog:    return bloomFogMultiplier;
                case WeatherState.CoastalRain: return bloomRainMultiplier;
                case WeatherState.Noreaster:   return bloomNoreasterMultiplier;
                default:                       return 1f;
            }
        }
    }
}
