// ============================================================
// QUAHOG — Headless-compile stubs for UnityEngine.Rendering.PostProcessing
//
// These stub types mirror the public surface of Unity's Post Processing
// Stack v2 (com.unity.postprocessing) so that QUAHOG C# scripts compile
// outside the Unity editor without a real PPv2 assembly reference.
//
// Rules
//   • Every stub is non-functional (bodies are no-ops or return defaults).
//   • Method/property signatures must match the real PPv2 API exactly.
//   • Do NOT add logic; this is purely a compile target.
// ============================================================

using System;
using UnityEngine;

namespace UnityEngine.Rendering.PostProcessing
{
    // ------------------------------------------------------------------
    // Parameter-override infrastructure
    // ------------------------------------------------------------------

    /// <summary>
    /// Base class for all post-process parameter overrides.
    /// </summary>
    [Serializable]
    public abstract class ParameterOverride
    {
        /// <summary>Whether this override is active and overrides the parent profile value.</summary>
        public bool overrideState;
    }

    /// <summary>
    /// Typed parameter override wrapper used for every post-process setting field.
    /// </summary>
    [Serializable]
    public class ParameterOverride<T> : ParameterOverride
    {
        /// <summary>The overridden value.</summary>
        public T value;

        public ParameterOverride() { }
        public ParameterOverride(T value) { this.value = value; }
        public ParameterOverride(T value, bool overrideState)
        {
            this.value = value;
            this.overrideState = overrideState;
        }
    }

    /// <summary>Float parameter override.</summary>
    [Serializable]
    public sealed class FloatParameter : ParameterOverride<float>
    {
        public FloatParameter() { }
        public FloatParameter(float value, bool overrideState = false)
            : base(value, overrideState) { }
    }

    /// <summary>Integer parameter override.</summary>
    [Serializable]
    public sealed class IntParameter : ParameterOverride<int>
    {
        public IntParameter() { }
        public IntParameter(int value, bool overrideState = false)
            : base(value, overrideState) { }
    }

    /// <summary>Boolean parameter override.</summary>
    [Serializable]
    public sealed class BoolParameter : ParameterOverride<bool>
    {
        public BoolParameter() { }
        public BoolParameter(bool value, bool overrideState = false)
            : base(value, overrideState) { }
    }

    /// <summary>Color parameter override.</summary>
    [Serializable]
    public sealed class ColorParameter : ParameterOverride<Color>
    {
        public ColorParameter() { }
        public ColorParameter(Color value, bool overrideState = false)
            : base(value, overrideState) { }
    }

    /// <summary>Vector2 parameter override.</summary>
    [Serializable]
    public sealed class Vector2Parameter : ParameterOverride<Vector2>
    {
        public Vector2Parameter() { }
        public Vector2Parameter(Vector2 value, bool overrideState = false)
            : base(value, overrideState) { }
    }

    /// <summary>Texture parameter override.</summary>
    [Serializable]
    public sealed class TextureParameter : ParameterOverride<Texture>
    {
        public TextureParameter() { }
        public TextureParameter(Texture value, bool overrideState = false)
            : base(value, overrideState) { }
    }

    // ------------------------------------------------------------------
    // Enumerations
    // ------------------------------------------------------------------

    /// <summary>Color grading mode used by <see cref="ColorGrading"/>.</summary>
    public enum GradingMode
    {
        LowDefinitionRange,
        HighDefinitionRange,
        External
    }

    /// <summary>Kernel size used for <see cref="Bloom"/> iteration.</summary>
    public enum KernelSize
    {
        Small,
        Medium,
        Large,
        VeryLarge
    }

    /// <summary>Ambient occlusion algorithm selection.</summary>
    public enum AmbientOcclusionMode
    {
        ScalableAmbientObscurance,
        MultiScaleVolumetricObscurance
    }

    /// <summary>Vignette style.</summary>
    public enum VignetteMode
    {
        Classic,
        Masked
    }

    // ------------------------------------------------------------------
    // Base effect settings
    // ------------------------------------------------------------------

    /// <summary>
    /// Base class for all post-processing effect setting blocks.
    /// </summary>
    [Serializable]
    public abstract class PostProcessEffectSettings : ScriptableObject
    {
        /// <summary>Whether this effect is enabled in the volume.</summary>
        public BoolParameter enabled = new BoolParameter { value = false };

        /// <summary>Returns true when this effect is active and should be rendered.</summary>
        public virtual bool IsEnabledAndSupported(PostProcessRenderContext context) => enabled.value;
    }

    // ------------------------------------------------------------------
    // Individual effect settings
    // ------------------------------------------------------------------

    /// <summary>Bloom post-processing effect settings.</summary>
    [Serializable]
    public sealed class Bloom : PostProcessEffectSettings
    {
        /// <summary>Luminance threshold above which bloom applies (gamma-space).</summary>
        public FloatParameter threshold = new FloatParameter { value = 1f };

        /// <summary>Strength of the bloom effect.</summary>
        public FloatParameter intensity = new FloatParameter { value = 0f };

        /// <summary>Scatter distance of the bloom filter.</summary>
        public FloatParameter scatter = new FloatParameter { value = 0.7f };

        /// <summary>Tint colour applied to the bloom.</summary>
        public ColorParameter color = new ColorParameter { value = Color.white };

        /// <summary>Fast mode (lower quality, better performance).</summary>
        public BoolParameter fastMode = new BoolParameter { value = false };

        /// <summary>Anamorphic lens ratio (–1 horizontal … +1 vertical).</summary>
        public FloatParameter anamorphicRatio = new FloatParameter { value = 0f };
    }

    /// <summary>Vignette post-processing effect settings.</summary>
    [Serializable]
    public sealed class Vignette : PostProcessEffectSettings
    {
        /// <summary>Classic or Masked vignette mode.</summary>
        public ParameterOverride<VignetteMode> mode =
            new ParameterOverride<VignetteMode> { value = VignetteMode.Classic };

        /// <summary>Vignette colour.</summary>
        public ColorParameter color = new ColorParameter { value = Color.black };

        /// <summary>Sets the vignette center position (screen-space).</summary>
        public Vector2Parameter center = new Vector2Parameter { value = new Vector2(0.5f, 0.5f) };

        /// <summary>Amount of vignetting on screen (0…1).</summary>
        public FloatParameter intensity = new FloatParameter { value = 0f };

        /// <summary>Smoothness of the vignette borders.</summary>
        public FloatParameter smoothness = new FloatParameter { value = 0.2f };

        /// <summary>Lower values result in rounder vignette; higher values are more square.</summary>
        public FloatParameter roundness = new FloatParameter { value = 1f };

        /// <summary>Rounds the vignette when <c>rounded</c> is true.</summary>
        public BoolParameter rounded = new BoolParameter { value = false };
    }

    /// <summary>Color grading post-processing effect settings.</summary>
    [Serializable]
    public sealed class ColorGrading : PostProcessEffectSettings
    {
        /// <summary>The grading mode to use.</summary>
        public ParameterOverride<GradingMode> gradingMode =
            new ParameterOverride<GradingMode> { value = GradingMode.HighDefinitionRange };

        /// <summary>Post-exposure in EV units.</summary>
        public FloatParameter postExposure = new FloatParameter { value = 0f };

        /// <summary>Contrast adjustment (–100 … +100).</summary>
        public FloatParameter contrast = new FloatParameter { value = 0f };

        /// <summary>Colour filter tint.</summary>
        public ColorParameter colorFilter = new ColorParameter { value = Color.white };

        /// <summary>Hue shift in degrees (–180 … +180).</summary>
        public FloatParameter hueShift = new FloatParameter { value = 0f };

        /// <summary>Saturation adjustment (–100 … +100).</summary>
        public FloatParameter saturation = new FloatParameter { value = 0f };

        /// <summary>Temperature shift for white balance.</summary>
        public FloatParameter temperature = new FloatParameter { value = 0f };

        /// <summary>Tint shift for white balance.</summary>
        public FloatParameter tint = new FloatParameter { value = 0f };
    }

    /// <summary>Motion blur post-processing effect settings.</summary>
    [Serializable]
    public sealed class MotionBlur : PostProcessEffectSettings
    {
        /// <summary>Angle of the rotary shutter (degrees, 0…360).</summary>
        public FloatParameter shutterAngle = new FloatParameter { value = 270f };

        /// <summary>Number of sample points (1…32).</summary>
        public IntParameter sampleCount = new IntParameter { value = 10 };
    }

    /// <summary>Depth-of-field post-processing effect settings.</summary>
    [Serializable]
    public sealed class DepthOfField : PostProcessEffectSettings
    {
        /// <summary>Distance to the point of focus (world units).</summary>
        public FloatParameter focusDistance = new FloatParameter { value = 10f };

        /// <summary>Ratio of aperture (known as f-stop or f-number).</summary>
        public FloatParameter aperture = new FloatParameter { value = 5.6f };

        /// <summary>Distance between the lens and the film (mm).</summary>
        public FloatParameter focalLength = new FloatParameter { value = 50f };

        /// <summary>Number of diaphragm blades.</summary>
        public ParameterOverride<KernelSize> kernelSize =
            new ParameterOverride<KernelSize> { value = KernelSize.Medium };
    }

    /// <summary>Ambient occlusion post-processing effect settings.</summary>
    [Serializable]
    public sealed class AmbientOcclusion : PostProcessEffectSettings
    {
        /// <summary>The occlusion estimator algorithm to use.</summary>
        public ParameterOverride<AmbientOcclusionMode> mode =
            new ParameterOverride<AmbientOcclusionMode>
            { value = AmbientOcclusionMode.MultiScaleVolumetricObscurance };

        /// <summary>Degree of darkness added by ambient occlusion (0…4).</summary>
        public FloatParameter intensity = new FloatParameter { value = 0f };

        /// <summary>Radius of sample points (0.01…3).</summary>
        public FloatParameter radius = new FloatParameter { value = 0.3f };

        /// <summary>Number of samples per pixel (1…8).</summary>
        public IntParameter sampleCount = new IntParameter { value = 3 };

        /// <summary>Render ambient occlusion at half resolution to speed things up.</summary>
        public BoolParameter downsampling = new BoolParameter { value = true };

        /// <summary>Runs ambient occlusion in ambient-only mode.</summary>
        public BoolParameter ambientOnly = new BoolParameter { value = false };
    }

    /// <summary>Chromatic aberration post-processing effect settings.</summary>
    [Serializable]
    public sealed class ChromaticAberration : PostProcessEffectSettings
    {
        /// <summary>Fringe texture to use for the aberration.</summary>
        public TextureParameter spectralLut = new TextureParameter { value = null };

        /// <summary>Strength of the aberration effect (0…1).</summary>
        public FloatParameter intensity = new FloatParameter { value = 0f };

        /// <summary>Use a fast low-quality version of the effect.</summary>
        public BoolParameter fastMode = new BoolParameter { value = false };
    }

    /// <summary>Grain (film grain) post-processing effect settings.</summary>
    [Serializable]
    public sealed class Grain : PostProcessEffectSettings
    {
        /// <summary>Enable colored grain.</summary>
        public BoolParameter colored = new BoolParameter { value = true };

        /// <summary>Grain strength (0…1).</summary>
        public FloatParameter intensity = new FloatParameter { value = 0f };

        /// <summary>Size of grain texture tiles (0.3…3).</summary>
        public FloatParameter size = new FloatParameter { value = 1f };

        /// <summary>Controls the noisiness response curve based on scene luminance.</summary>
        public FloatParameter lumContrib = new FloatParameter { value = 0.8f };
    }

    /// <summary>Screen-space reflections post-processing effect settings.</summary>
    [Serializable]
    public sealed class ScreenSpaceReflections : PostProcessEffectSettings
    {
        /// <summary>Maximum iteration count (64…256).</summary>
        public IntParameter maximumIterationCount = new IntParameter { value = 128 };

        /// <summary>Thickness value for object thickness calculation.</summary>
        public FloatParameter thickness = new FloatParameter { value = 8f };

        /// <summary>Screen-space reflection intensity.</summary>
        public FloatParameter intensity = new FloatParameter { value = 0f };

        /// <summary>Fade-out distance from screen edges.</summary>
        public FloatParameter distanceFade = new FloatParameter { value = 0.5f };
    }

    // ------------------------------------------------------------------
    // Post-process profile
    // ------------------------------------------------------------------

    /// <summary>
    /// A reusable post-processing profile asset that stores a collection of
    /// <see cref="PostProcessEffectSettings"/>.
    /// </summary>
    public class PostProcessProfile : ScriptableObject
    {
        /// <summary>List of effect settings stored in this profile.</summary>
        public System.Collections.Generic.List<PostProcessEffectSettings> settings =
            new System.Collections.Generic.List<PostProcessEffectSettings>();

        /// <summary>
        /// Retrieves the settings for the specified effect type, if present.
        /// </summary>
        public bool TryGetSettings<T>(out T outSetting) where T : PostProcessEffectSettings
        {
            foreach (var s in settings)
            {
                if (s is T t) { outSetting = t; return true; }
            }
            outSetting = null;
            return false;
        }

        /// <summary>
        /// Returns <c>true</c> if the profile contains settings for the effect type.
        /// </summary>
        public bool HasSettings<T>() where T : PostProcessEffectSettings
        {
            foreach (var s in settings)
            {
                if (s is T) return true;
            }
            return false;
        }

        /// <summary>
        /// Adds a new settings block of the given type to this profile and returns it.
        /// </summary>
        public T AddSettings<T>() where T : PostProcessEffectSettings
        {
            var setting = ScriptableObject.CreateInstance<T>();
            settings.Add(setting);
            return setting;
        }

        /// <summary>
        /// Removes the settings block of the given type from this profile.
        /// </summary>
        public void RemoveSettings<T>() where T : PostProcessEffectSettings
        {
            settings.RemoveAll(s => s is T);
        }
    }

    // ------------------------------------------------------------------
    // Post-process volume (scene component)
    // ------------------------------------------------------------------

    /// <summary>
    /// A global or local volume that applies post-processing effects to the camera.
    /// Attach to any scene GameObject alongside a <see cref="PostProcessLayer"/>.
    /// </summary>
    public class PostProcessVolume : MonoBehaviour
    {
        /// <summary>When true this volume affects the entire scene regardless of position.</summary>
        public bool isGlobal = false;

        /// <summary>Priority when multiple volumes overlap; highest value wins.</summary>
        public float priority = 0f;

        /// <summary>
        /// Blend weight for local volumes (0 = no effect, 1 = full effect).
        /// For global volumes this is always treated as 1.
        /// </summary>
        public float weight = 1f;

        /// <summary>Blend distance around the volume collider (local volumes only).</summary>
        public float blendDistance = 0f;

        /// <summary>The post-processing profile used by this volume.</summary>
        public PostProcessProfile profile;

        /// <summary>
        /// Returns the shared profile or instantiates a copy for editing at runtime.
        /// </summary>
        public PostProcessProfile sharedProfile => profile;
    }

    // ------------------------------------------------------------------
    // Post-process layer (camera component)
    // ------------------------------------------------------------------

    /// <summary>
    /// Camera component that enables post-processing on the attached camera.
    /// </summary>
    public class PostProcessLayer : MonoBehaviour
    {
        /// <summary>The anti-aliasing mode used by this layer.</summary>
        public Antialiasing antialiasingMode = Antialiasing.None;

        /// <summary>Enumerates anti-aliasing modes available on the post-process layer.</summary>
        public enum Antialiasing
        {
            None,
            FastApproximateAntialiasing,
            SubpixelMorphologicalAntialiasing,
            TemporalAntialiasing
        }
    }

    // ------------------------------------------------------------------
    // Render context (passed to IsEnabledAndSupported)
    // ------------------------------------------------------------------

    /// <summary>Render context data passed to post-process effects during rendering.</summary>
    public class PostProcessRenderContext
    {
        /// <summary>The camera being rendered.</summary>
        public Camera camera;

        /// <summary>Destination render texture (may be null for the back buffer).</summary>
        public RenderTexture destination;
    }
}
