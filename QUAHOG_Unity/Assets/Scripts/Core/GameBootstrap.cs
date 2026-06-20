using UnityEngine;

namespace Quahog.SouthCoast
{
    /// <summary>
    /// Code-driven entry point. Runs automatically in every build and in play
    /// mode via [RuntimeInitializeOnLoadMethod], so it needs no scene wiring —
    /// the build scene can be empty. It spawns the manager singletons, runs the
    /// ported SceneBootstrap validation/init pass, and stands up a minimal HUD
    /// (cash counter + health bar) as a visible proof-of-life.
    /// </summary>
    public static class GameBootstrap
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Boot()
        {
            var root = new GameObject("QUAHOG_Managers");
            Object.DontDestroyOnLoad(root);

            // Spawn the core singletons (their Awake registers Instance).
            root.AddComponent<GameManager>();
            root.AddComponent<PlayerWallet>();
            root.AddComponent<TimeOfDayClock>();
            root.AddComponent<WeatherController>();
            root.AddComponent<HeatManager>();
            root.AddComponent<RevenueManager>();
            root.AddComponent<AudioBarkManager>();
            root.AddComponent<RadioManager>();
            root.AddComponent<MissionManager>();
            root.AddComponent<HUDManager>();
            root.AddComponent<EmpireDatabaseManager>();
            root.AddComponent<SceneObjectRegistry>();
            root.AddComponent<PostProcessManager>();

            // Demo-friendly cadence so the living-world systems are visibly
            // moving in a build (the GDScript defaults are tuned for real play).
            TimeOfDayClock.Instance.SecondsPerGameHour = 3f;      // a full day ~72s
            WeatherController.Instance.StateCheckInterval = 12f;  // roll weather often
            WeatherController.Instance.BlendDuration = 1.5f;      // snappy transitions

            // Run the ported bootstrap (validates singletons, sets prologue state).
            root.AddComponent<SceneBootstrap>();

            // Visible proof-of-life HUD, and some starting cash to show it ticking.
            root.AddComponent<TestSceneBootstrap>().InitTestScene();
            PlayerWallet.Instance.SetBalance(500f);

            // Backdrop camera: an atmospheric sky that reacts to time + weather
            // (so the empty play area isn't a black void), and a Camera to build on.
            root.AddComponent<WorldBackdrop>();

            // Living-world HUD: day/time clock, weather, and wanted-level stars.
            root.AddComponent<WorldHud>();

            // ----- Playable slice: greybox coastal town + on-foot player + drivable car.
            // Build the world first so the ground/colliders exist, then drop the player
            // into the plaza and a car on the street. Walk up to the car and press F.
            var town = TownGreybox.Build();
            var player = PlayerCharacter.Spawn(town.PlayerSpawn);
            var followCam = ThirdPersonCamera.Attach(player.transform);
            var car = CarController.Spawn(town.VehicleSpawn);
            root.AddComponent<PlayerVehicleInteractor>().Init(player, followCam, car);

            // Street life: wandering pedestrians + a few decorative AI cars (kinematic,
            // so they never disturb the player's physics car).
            StreetLife.Spawn();

            Debug.Log("[GameBootstrap] QUAHOG online — managers spawned, HUD up, $500 in the wallet.");
        }
    }
}
