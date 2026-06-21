using UnityEngine;

namespace Quahog.SouthCoast
{
    /// <summary>
    /// An orbiting follow camera. The mouse drives yaw (Mouse X) and pitch (Mouse Y),
    /// pitch is clamped to a comfortable arc, and the camera is parked behind and above
    /// its target at a fixed distance, re-aimed at the target every LateUpdate so it
    /// trails movement smoothly. Designed to retarget at runtime (e.g. to follow a car).
    /// </summary>
    public class ThirdPersonCamera : MonoBehaviour
    {
        private const float Distance    = 5.5f;  // metres behind the target
        private const float Height      = 2f;    // look-at point above the pivot
        private const float OrbitSpeed  = 180f;  // degrees per unit of mouse delta
        private const float MinPitch    = -30f;
        private const float MaxPitch    = 70f;
        private const float FollowLerp  = 10f;   // how quickly the rig eases to position

        private Transform _target;
        private float _yaw;
        private float _pitch = 15f; // start looking slightly down at the target

        /// <summary>
        /// Attaches a follow camera to <paramref name="target"/>. Uses the existing
        /// Camera.main; if there is none, creates a GameObject tagged "MainCamera"
        /// with a Camera + AudioListener and uses that. Returns the component.
        /// </summary>
        public static ThirdPersonCamera Attach(Transform target)
        {
            var cam = Camera.main;
            if (cam == null)
            {
                var go = new GameObject("MainCamera") { tag = "MainCamera" };
                cam = go.AddComponent<Camera>();
                go.AddComponent<AudioListener>();
            }

            // Reuse an existing rig on this camera if one is already present.
            var rig = cam.GetComponent<ThirdPersonCamera>();
            if (rig == null) rig = cam.gameObject.AddComponent<ThirdPersonCamera>();

            rig.SetTarget(target);
            return rig;
        }

        /// <summary>Retargets the camera onto a new transform (may be null).</summary>
        public void SetTarget(Transform target)
        {
            _target = target;
        }

        private void LateUpdate()
        {
            if (_target == null) return;

            // Orbit from mouse delta. Reading the legacy axes here keeps input simple
            // and allocation-free; no smoothing buffer required.
            _yaw   += Input.GetAxis("Mouse X") * OrbitSpeed * Time.deltaTime;
            _pitch -= Input.GetAxis("Mouse Y") * OrbitSpeed * Time.deltaTime;
            _pitch = Mathf.Clamp(_pitch, MinPitch, MaxPitch);

            // Build the orbit offset, then place the camera behind+above the target.
            Quaternion rotation = Quaternion.Euler(_pitch, _yaw, 0f);
            Vector3 lookAt = _target.position + Vector3.up * Height;
            Vector3 desired = lookAt + rotation * new Vector3(0f, 0f, -Distance);

            // Ease toward the desired position so the rig trails motion smoothly.
            transform.position = Vector3.Lerp(transform.position, desired, FollowLerp * Time.deltaTime);
            transform.LookAt(lookAt);
        }
    }
}
