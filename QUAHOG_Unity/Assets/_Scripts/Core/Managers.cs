using System;
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
    // Minimal manager singletons.
    //
    // These are functional stubs that let the bootstrap flow compile and run as
    // a Unity build. They mirror the system surface used by SceneBootstrap and
    // TestSceneBootstrap; flesh each one out by porting its GDScript counterpart
    // from QUAHOG_Godot/ as the project grows.
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

    public class TimeOfDayClock : Singleton<TimeOfDayClock>
    {
        public float CurrentTime { get; private set; }

        /// <summary>Jump the clock to a specific hour (0–24).</summary>
        public void SetTime(float hour)
        {
            CurrentTime = Mathf.Clamp(hour, 0f, 24f);
        }
    }

    public class WeatherController : Singleton<WeatherController>
    {
        public enum WeatherState { Clear, DenseFog, CoastalRain, Noreaster }

        public WeatherState Current { get; private set; } = WeatherState.Clear;

        public void ForceState(WeatherState state)
        {
            Current = state;
        }
    }

    public class HeatManager : Singleton<HeatManager> { }
    public class RevenueManager : Singleton<RevenueManager> { }
    public class AudioBarkManager : Singleton<AudioBarkManager> { }
    public class RadioManager : Singleton<RadioManager> { }
    public class MissionManager : Singleton<MissionManager> { }
    public class HUDManager : Singleton<HUDManager> { }
    public class EmpireDatabaseManager : Singleton<EmpireDatabaseManager> { }
    public class SceneObjectRegistry : Singleton<SceneObjectRegistry> { }
}
