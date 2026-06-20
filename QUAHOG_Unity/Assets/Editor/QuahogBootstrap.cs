#if UNITY_EDITOR
using System;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Quahog.SouthCoast.EditorTools
{
    /// <summary>
    /// Editor-only project bootstrap. Configures the project for a URP build so
    /// Unity Build Automation produces a correctly-rendered player without a
    /// human opening the editor:
    ///   - creates the URP pipeline + renderer assets in Assets/Settings/ if missing
    ///   - assigns them as the active pipeline in Graphics + Quality settings
    ///   - stamps product name / company / Android bundle id
    ///
    /// It runs on editor load AND as a pre-build step (so UBA picks it up). The
    /// whole file is wrapped in UNITY_EDITOR and lives under Assets/Editor/, so it
    /// is never compiled into the player build (no "UnityEditor namespace not
    /// found"). Generating the URP assets via URP's own API avoids committing
    /// hand-authored .asset YAML that could fail to import.
    /// </summary>
    [InitializeOnLoad]
    public static class QuahogBootstrap
    {
        const string SettingsDir  = "Assets/Settings";
        const string UrpAssetPath = SettingsDir + "/URP-Quahog.asset";
        const string RendererPath = SettingsDir + "/URP-Quahog-Renderer.asset";

        static QuahogBootstrap()
        {
            // Defer until the AssetDatabase is ready (also fires in batch builds).
            EditorApplication.delayCall += EnsureProjectConfigured;
        }

        [MenuItem("QUAHOG/Configure Project (URP + identity)")]
        public static void EnsureProjectConfigured()
        {
            try
            {
                EnsureUrp();
                EnsureIdentity();
                AssetDatabase.SaveAssets();
            }
            catch (Exception e)
            {
                // Never fail the build over configuration — the uGUI HUD renders
                // regardless of the 3D pipeline.
                Debug.LogWarning("[QuahogBootstrap] Project configuration skipped: " + e.Message);
            }
        }

        static void EnsureUrp()
        {
            if (GraphicsSettings.defaultRenderPipeline is UniversalRenderPipelineAsset)
                return; // already configured

            if (!AssetDatabase.IsValidFolder(SettingsDir))
                AssetDatabase.CreateFolder("Assets", "Settings");

            var urp = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(UrpAssetPath);
            if (urp == null)
            {
                var rendererData = ScriptableObject.CreateInstance<UniversalRendererData>();
                AssetDatabase.CreateAsset(rendererData, RendererPath);

                urp = UniversalRenderPipelineAsset.Create(rendererData);
                AssetDatabase.CreateAsset(urp, UrpAssetPath);
                AssetDatabase.SaveAssets();
            }

            GraphicsSettings.defaultRenderPipeline = urp;
            QualitySettings.renderPipeline = urp;
            Debug.Log("[QuahogBootstrap] URP pipeline ensured and assigned.");
        }

        static void EnsureIdentity()
        {
            if (string.IsNullOrEmpty(PlayerSettings.productName) ||
                PlayerSettings.productName == "QUAHOG_Unity")
            {
                PlayerSettings.productName = "Project QUAHOG";
            }
            if (string.IsNullOrEmpty(PlayerSettings.companyName) ||
                PlayerSettings.companyName == "DefaultCompany")
            {
                PlayerSettings.companyName = "Rockwharf Games";
            }
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, "com.rockwharf.quahog");
        }

        /// <summary>Runs right before any build, including Unity Build Automation.</summary>
        private class BuildHook : IPreprocessBuildWithReport
        {
            public int callbackOrder => 0;
            public void OnPreprocessBuild(BuildReport report) => EnsureProjectConfigured();
        }
    }
}
#endif
