using UnityEngine;

namespace Quahog.SouthCoast
{
    /// <summary>
    /// Scene entry-point bootstrapper. Validates all required singleton instances
    /// are present, then initializes the scene state (time of day, weather,
    /// lighting) for the prologue sequence.
    /// </summary>
    public class SceneBootstrap : MonoBehaviour
    {
        /// <summary>
        /// Unity Start callback — validates all singleton dependencies before
        /// initializing the scene state.
        /// </summary>
        private void Start()
        {
            ValidateSingletons();
            InitializeScene();
        }

        /// <summary>
        /// Validates that every required singleton has been instantiated in the
        /// scene. Logs an error for each missing singleton so that missing
        /// dependencies are surfaced immediately.
        /// </summary>
        public void ValidateSingletons()
        {
            int missingCount = 0;

            missingCount += CheckSingleton(PlayerWallet.Instance, nameof(PlayerWallet));
            missingCount += CheckSingleton(EmpireDatabaseManager.Instance, nameof(EmpireDatabaseManager));
            missingCount += CheckSingleton(GameManager.Instance, nameof(GameManager));
            missingCount += CheckSingleton(WeatherController.Instance, nameof(WeatherController));
            missingCount += CheckSingleton(TimeOfDayClock.Instance, nameof(TimeOfDayClock));
            missingCount += CheckSingleton(RevenueManager.Instance, nameof(RevenueManager));
            missingCount += CheckSingleton(AudioBarkManager.Instance, nameof(AudioBarkManager));
            missingCount += CheckSingleton(RadioManager.Instance, nameof(RadioManager));
            missingCount += CheckSingleton(HeatManager.Instance, nameof(HeatManager));
            missingCount += CheckSingleton(MissionManager.Instance, nameof(MissionManager));
            missingCount += CheckSingleton(HUDManager.Instance, nameof(HUDManager));
            missingCount += CheckSingleton(SceneObjectRegistry.Instance, nameof(SceneObjectRegistry));
            missingCount += CheckSingleton(PostProcessManager.Instance, nameof(PostProcessManager));

            if (missingCount > 0)
            {
                Debug.LogError($"[SceneBootstrap] Singleton validation FAILED: " +
                               $"{missingCount} singleton(s) missing from the scene.");
            }
            else
            {
                Debug.Log("[SceneBootstrap] All singletons validated successfully.");
            }
        }

        /// <summary>
        /// Initializes the scene state for the prologue: locks time to midnight
        /// (00:00) and forces the weather to DenseFog.
        /// </summary>
        public void InitializeScene()
        {
            // Prologue begins at midnight for atmosphere.
            if (TimeOfDayClock.Instance != null)
            {
                TimeOfDayClock.Instance.SetTime(0f);
                Debug.Log("[SceneBootstrap] Time set to midnight (00:00).");
            }

            // Prologue opens with dense coastal fog.
            if (WeatherController.Instance != null)
            {
                WeatherController.Instance.ForceState(WeatherController.WeatherState.DenseFog);
                Debug.Log("[SceneBootstrap] Weather forced to DenseFog for prologue.");
            }
        }

        /// <summary>
        /// Helper that checks whether a singleton instance is null and logs a
        /// descriptive error. Returns 1 if missing, 0 if present.
        /// </summary>
        /// <param name="instance">The singleton instance to validate.</param>
        /// <param name="typeName">The type name of the singleton.</param>
        /// <returns>1 if the singleton is missing, otherwise 0.</returns>
        private int CheckSingleton(Object instance, string typeName)
        {
            if (instance == null)
            {
                Debug.LogError($"[SceneBootstrap] Singleton '{typeName}' is NULL. " +
                               $"Ensure a {typeName} GameObject is present in the scene.");
                return 1;
            }
            return 0;
        }
    }
}
