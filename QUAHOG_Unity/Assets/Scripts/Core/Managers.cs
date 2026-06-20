using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Quahog.SouthCoast
{
    /// <summary>
    /// Generic MonoBehaviour singleton base. The first instance to Awake wins;
    /// later duplicates destroy themselves.
    /// </summary>
    public abstract class Singleton<T> : MonoBehaviour where T : Singleton<T>
    {
        public static T Instance { get; private set; }

        protected virtual void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = (T)this;
        }
    }

    // -----------------------------------------------------------------------
    // Manager singletons.
    //
    // The three living-world systems below (TimeOfDayClock, WeatherController,
    // HeatManager) are full ports of their GDScript counterparts in
    // QUAHOG_Godot/autoloads/. The remaining managers are still functional
    // stubs — port each one from Godot as the project grows.
    // -----------------------------------------------------------------------

    public class GameManager : Singleton<GameManager> { }

    public class PlayerWallet : Singleton<PlayerWallet>
    {
        [SerializeField] private float _balance;

        public float Balance => _balance;
        public event Action<float> OnBalanceChanged;

        public void AddFunds(float amount)
        {
            if (amount < 0f) return;
            _balance += amount;
            OnBalanceChanged?.Invoke(_balance);
        }

        public bool Deduct(float amount)
        {
            if (amount < 0f || _balance < amount) return false;
            _balance -= amount;
            OnBalanceChanged?.Invoke(_balance);
            return true;
        }

        public void SetBalance(float amount)
        {
            _balance = Mathf.Max(0f, amount);
            OnBalanceChanged?.Invoke(_balance);
        }
    }

    /// <summary>
    /// Tracks in-game time (0.0–24.0 hours) and the current day, advancing in
    /// real time and firing events on hour/day boundaries. Ported from
    /// QUAHOG_Godot/autoloads/TimeOfDayClock.gd.
    /// </summary>
    public class TimeOfDayClock : Singleton<TimeOfDayClock>
    {
        [SerializeField] private float _secondsPerGameHour = 60f;

        /// <summary>Real-world seconds that correspond to one in-game hour.</summary>
        public float SecondsPerGameHour
        {
            get => _secondsPerGameHour;
            set => _secondsPerGameHour = Mathf.Max(0.01f, value);
        }

        /// <summary>Current game time in fractional hours, range [0.0, 24.0).</summary>
        public float CurrentTime { get; private set; }

        /// <summary>Current in-game day (1-indexed).</summary>
        public int CurrentDay { get; private set; } = 1;

        private int _lastHour;

        public event Action<int> OnHourChanged;
        public event Action OnMidnight;
        public event Action<int> OnDayChanged;

        protected override void Awake()
        {
            base.Awake();
            _lastHour = (int)CurrentTime;
        }

        private void Update()
        {
            float hoursPerSecond = 1f / _secondsPerGameHour;
            CurrentTime += Time.deltaTime * hoursPerSecond;

            int newHour = (int)CurrentTime % 24;
            if (newHour != _lastHour)
            {
                _lastHour = newHour;
                OnHourChanged?.Invoke(newHour);
            }

            if (CurrentTime >= 24f)
            {
                CurrentTime %= 24f;
                CurrentDay++;
                OnMidnight?.Invoke();
                OnDayChanged?.Invoke(CurrentDay);
                _lastHour = (int)CurrentTime;
            }
        }

        /// <summary>Jump the clock to a specific hour (0–24).</summary>
        public void SetTime(float hour)
        {
            CurrentTime = Mathf.Clamp(hour, 0f, 23.9999f);
            _lastHour = (int)CurrentTime;
            OnHourChanged?.Invoke(_lastHour);
        }

        /// <summary>Override the current day counter (minimum 1).</summary>
        public void SetDay(int day)
        {
            CurrentDay = Mathf.Max(1, day);
            OnDayChanged?.Invoke(CurrentDay);
        }

        /// <summary>Advance the clock by whole in-game hours, rolling over midnight.</summary>
        public void AdvanceHours(int hours)
        {
            CurrentTime += hours;
            while (CurrentTime >= 24f)
            {
                CurrentTime -= 24f;
                CurrentDay++;
                OnMidnight?.Invoke();
                OnDayChanged?.Invoke(CurrentDay);
            }
            _lastHour = (int)CurrentTime;
            OnHourChanged?.Invoke(_lastHour);
        }

        /// <summary>Current time as a formatted "HH:MM" string.</summary>
        public string GetTimeString()
        {
            int h = (int)CurrentTime % 24;
            int m = (int)((CurrentTime - (int)CurrentTime) * 60f);
            return $"{h:D2}:{m:D2}";
        }
    }

    /// <summary>
    /// 4-state weather FSM (Clear, DenseFog, CoastalRain, Noreaster) that rolls
    /// for a new weighted state on an interval and blends into it. Ported from
    /// QUAHOG_Godot/autoloads/WeatherController.gd. Visual application (fog,
    /// ambient) is left to listeners — this build surfaces it on the HUD.
    /// </summary>
    public class WeatherController : Singleton<WeatherController>
    {
        public enum WeatherState { Clear, DenseFog, CoastalRain, Noreaster }

        public WeatherState Current { get; private set; } = WeatherState.Clear;

        [SerializeField] private float _stateCheckInterval = 60f;
        [SerializeField] private float _blendDuration = 6f;

        // Default odds: mostly clear, some fog, occasional rain, rare nor'easter.
        private float[] _stateWeights = { 0.45f, 0.25f, 0.20f, 0.10f };

        private bool _isTransitioning;
        private float _timer;

        /// <summary>Seconds between weather-roll checks.</summary>
        public float StateCheckInterval
        {
            get => _stateCheckInterval;
            set => _stateCheckInterval = Mathf.Max(1f, value);
        }

        /// <summary>Seconds to blend from one state into the next.</summary>
        public float BlendDuration
        {
            get => _blendDuration;
            set => _blendDuration = Mathf.Max(0f, value);
        }

        public event Action<WeatherState> OnWeatherChanged;
        public event Action<float> OnBlendProgress;

        private void Update()
        {
            _timer += Time.deltaTime;
            if (_timer < _stateCheckInterval) return;

            _timer = 0f;
            if (_isTransitioning) return;

            WeatherState next = PickWeightedState();
            if (next != Current) BeginTransition(next);
        }

        /// <summary>Force a specific state (begins a blend; ignored mid-transition).</summary>
        public void ForceState(WeatherState state)
        {
            if (_isTransitioning) return;
            BeginTransition(state);
        }

        /// <summary>Replace the state-probability weights (exactly 4, &gt; 0 total).</summary>
        public void SetStateWeights(float[] weights)
        {
            if (weights == null || weights.Length != 4)
            {
                Debug.LogWarning("WeatherController: SetStateWeights requires exactly 4 elements.");
                return;
            }
            _stateWeights = weights;
        }

        /// <summary>Push a thematic weather state for a story phase/chapter.</summary>
        public void ApplyPhaseWeather(int phase)
        {
            switch (phase)
            {
                case 0: ForceState(WeatherState.Clear); break;
                case 1: ForceState(WeatherState.CoastalRain); break;
                case 2: ForceState(WeatherState.DenseFog); break;
                case 3: ForceState(WeatherState.Noreaster); break;
                default:
                    Debug.LogWarning($"WeatherController: Unknown phase {phase} — defaulting to Clear.");
                    ForceState(WeatherState.Clear);
                    break;
            }
        }

        private WeatherState PickWeightedState()
        {
            float total = 0f;
            foreach (float w in _stateWeights) total += w;

            float roll = UnityEngine.Random.value * total;
            float cumulative = 0f;
            for (int i = 0; i < _stateWeights.Length; i++)
            {
                cumulative += _stateWeights[i];
                if (roll < cumulative) return (WeatherState)i;
            }
            return WeatherState.Clear;
        }

        private void BeginTransition(WeatherState target)
        {
            _isTransitioning = true;
            StartCoroutine(TransitionRoutine(target));
        }

        private IEnumerator TransitionRoutine(WeatherState target)
        {
            float elapsed = 0f;
            float duration = Mathf.Max(0.0001f, _blendDuration);
            while (elapsed < _blendDuration)
            {
                yield return null;
                elapsed += Time.deltaTime;
                OnBlendProgress?.Invoke(Mathf.Clamp01(elapsed / duration));
            }

            Current = target;
            OnWeatherChanged?.Invoke(Current);
            _isTransitioning = false;
        }
    }

    /// <summary>
    /// Wanted level (0–5) with smooth real-time decay, plus per-faction aggro.
    /// Ported from QUAHOG_Godot/autoloads/HeatManager.gd.
    /// </summary>
    public class HeatManager : Singleton<HeatManager>
    {
        public class FactionAggro
        {
            public string FactionId;
            public float Aggro;

            public FactionAggro(string factionId, float aggro = 0f)
            {
                FactionId = factionId;
                Aggro = aggro;
            }
        }

        [SerializeField] private float _wantedDecayRate = 0.5f;

        /// <summary>Wanted levels shed per second once heat is active.</summary>
        public float WantedDecayRate
        {
            get => _wantedDecayRate;
            set => _wantedDecayRate = value;
        }

        public int WantedLevel { get; private set; }

        private float _heat;             // smooth 0.0–5.0 backing value
        private float _decayAccumulator;
        private readonly List<FactionAggro> _factionAggros = new();

        /// <summary>Smooth heat value; setting it re-derives the wanted level.</summary>
        public float CurrentHeat
        {
            get => _heat;
            set => SetHeat(value);
        }

        public event Action<int> OnWantedLevelChanged;
        public event Action<string, float> OnFactionAggroChanged;
        public event Action OnHeatCleared;

        private void Update()
        {
            if (_heat <= 0f) return;

            _decayAccumulator += _wantedDecayRate * Time.deltaTime;
            while (_decayAccumulator >= 1f)
            {
                _decayAccumulator -= 1f;
                _heat = Mathf.Max(_heat - 1f, 0f);
            }

            int newLevel = (int)_heat;
            if (newLevel != WantedLevel)
            {
                WantedLevel = newLevel;
                OnWantedLevelChanged?.Invoke(WantedLevel);
            }

            if (_heat <= 0f)
            {
                _heat = 0f;
                _decayAccumulator = 0f;
            }
        }

        public void AddWantedLevel(int amount) => SetWantedLevel(WantedLevel + amount);

        public void SetWantedLevel(int level)
        {
            WantedLevel = Mathf.Clamp(level, 0, 5);
            _heat = WantedLevel;
            _decayAccumulator = 0f;
            OnWantedLevelChanged?.Invoke(WantedLevel);
        }

        public void AddFactionAggro(string factionId, float amount)
        {
            FactionAggro entry = GetOrCreateFactionAggro(factionId);
            entry.Aggro = Mathf.Clamp(entry.Aggro + amount, 0f, 100f);
            OnFactionAggroChanged?.Invoke(factionId, entry.Aggro);
        }

        public float GetFactionAggro(string factionId)
        {
            foreach (FactionAggro entry in _factionAggros)
                if (entry.FactionId == factionId) return entry.Aggro;
            return 0f;
        }

        public bool IsHeatActive() => WantedLevel > 0;

        public void ClearHeat()
        {
            WantedLevel = 0;
            _heat = 0f;
            _decayAccumulator = 0f;
            foreach (FactionAggro entry in _factionAggros) entry.Aggro = 0f;
            OnHeatCleared?.Invoke();
            OnWantedLevelChanged?.Invoke(0);
        }

        public void SetHeat(float heat)
        {
            _heat = Mathf.Clamp(heat, 0f, 5f);
            _decayAccumulator = 0f;
            int newLevel = (int)_heat;
            if (newLevel != WantedLevel)
            {
                WantedLevel = newLevel;
                OnWantedLevelChanged?.Invoke(WantedLevel);
            }
        }

        private FactionAggro GetOrCreateFactionAggro(string factionId)
        {
            foreach (FactionAggro entry in _factionAggros)
                if (entry.FactionId == factionId) return entry;

            var newEntry = new FactionAggro(factionId, 0f);
            _factionAggros.Add(newEntry);
            return newEntry;
        }
    }

    public class RevenueManager : Singleton<RevenueManager> { }
    public class AudioBarkManager : Singleton<AudioBarkManager> { }
    public class RadioManager : Singleton<RadioManager> { }
    public class MissionManager : Singleton<MissionManager> { }
    public class HUDManager : Singleton<HUDManager> { }
    public class EmpireDatabaseManager : Singleton<EmpireDatabaseManager> { }
    public class SceneObjectRegistry : Singleton<SceneObjectRegistry> { }
}
