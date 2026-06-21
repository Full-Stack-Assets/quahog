// Minimal input: held-key state + one-shot "tap" consumption, with a virtual
// (touch) layer so on-screen controls feed the same movement/tap pipeline.
const pressed = new Set<string>();
const taps = new Set<string>();
const virtual = { x: 0, y: 0 }; // touch joystick, each axis -1..1

let installed = false;
export function installInput() {
  if (installed || typeof window === "undefined") return;
  installed = true;
  window.addEventListener("keydown", (e) => {
    if (!e.repeat) taps.add(e.code);
    pressed.add(e.code);
  });
  window.addEventListener("keyup", (e) => pressed.delete(e.code));
  window.addEventListener("blur", () => pressed.clear());
}

export const isDown = (code: string) => pressed.has(code);

/** Returns true exactly once per physical key press. */
export const consumeTap = (code: string) => taps.delete(code);

/** Inject a one-shot tap from an on-screen (touch) button. */
export const virtualTap = (code: string) => taps.add(code);

/** Set the touch joystick vector (x = right, y = forward), each -1..1. */
export const setVirtualMove = (x: number, y: number) => { virtual.x = x; virtual.y = y; };

const clamp1 = (n: number) => Math.max(-1, Math.min(1, n));

/** Read a WASD/arrow + touch movement vector. x = right, y = forward. */
export function moveAxis(): { x: number; y: number } {
  let x = 0;
  let y = 0;
  if (isDown("KeyW") || isDown("ArrowUp")) y += 1;
  if (isDown("KeyS") || isDown("ArrowDown")) y -= 1;
  if (isDown("KeyD") || isDown("ArrowRight")) x += 1;
  if (isDown("KeyA") || isDown("ArrowLeft")) x -= 1;
  return { x: clamp1(x + virtual.x), y: clamp1(y + virtual.y) };
}
