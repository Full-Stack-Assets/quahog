// Minimal keyboard input: held-key state + one-shot "tap" consumption.
const pressed = new Set<string>();
const taps = new Set<string>();

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

/** Read a WASD/arrow movement vector. x = right, y = forward. */
export function moveAxis(): { x: number; y: number } {
  let x = 0;
  let y = 0;
  if (isDown("KeyW") || isDown("ArrowUp")) y += 1;
  if (isDown("KeyS") || isDown("ArrowDown")) y -= 1;
  if (isDown("KeyD") || isDown("ArrowRight")) x += 1;
  if (isDown("KeyA") || isDown("ArrowLeft")) x -= 1;
  return { x, y };
}
