import * as THREE from "three";

// Small procedural canvas textures (no asset files needed, works offline).

function canvas(size: number): [HTMLCanvasElement, CanvasRenderingContext2D] {
  const c = document.createElement("canvas");
  c.width = c.height = size;
  return [c, c.getContext("2d")!];
}

/** Mottled paved-ground texture (concrete/cobble feel), tiles seamlessly-ish. */
export function makeGroundTexture(): THREE.Texture {
  const [c, ctx] = canvas(256);
  ctx.fillStyle = "#3b3d44";
  ctx.fillRect(0, 0, 256, 256);
  // speckle
  for (let i = 0; i < 2600; i++) {
    const v = 40 + Math.random() * 50;
    ctx.fillStyle = `rgba(${v},${v},${v + 4},${0.25 + Math.random() * 0.25})`;
    const s = 1 + Math.random() * 3;
    ctx.fillRect(Math.random() * 256, Math.random() * 256, s, s);
  }
  // faint paving grid
  ctx.strokeStyle = "rgba(20,20,24,0.5)";
  ctx.lineWidth = 1;
  for (let i = 0; i <= 256; i += 32) {
    ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i, 256); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(0, i); ctx.lineTo(256, i); ctx.stroke();
  }
  const t = new THREE.CanvasTexture(c);
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  t.anisotropy = 4;
  return t;
}

/** Cobblestone texture for the historic district (rounded granite setts). */
export function makeCobbleTexture(): THREE.Texture {
  const [c, ctx] = canvas(256);
  ctx.fillStyle = "#4a4742";
  ctx.fillRect(0, 0, 256, 256);
  const S = 22; // sett spacing
  for (let y = -S; y < 256 + S; y += S) {
    const row = Math.round(y / S);
    for (let x = -S; x < 256 + S; x += S) {
      const ox = (row % 2) * (S / 2); // running-bond offset
      const cx = x + ox + (Math.random() * 4 - 2);
      const cy = y + (Math.random() * 4 - 2);
      const r = S * 0.46 + Math.random() * 2;
      const tone = 70 + Math.random() * 55;
      const g = ctx.createRadialGradient(cx - r * 0.3, cy - r * 0.3, 1, cx, cy, r);
      g.addColorStop(0, `rgb(${tone + 22},${tone + 18},${tone + 12})`);
      g.addColorStop(1, `rgb(${tone - 20},${tone - 22},${tone - 26})`);
      ctx.fillStyle = g;
      ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = "rgba(20,18,16,0.6)"; ctx.lineWidth = 1.5; ctx.stroke();
    }
  }
  const t = new THREE.CanvasTexture(c);
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  t.anisotropy = 8;
  return t;
}

/** Asphalt texture for road ribbons (u across width, v along length). */
export function makeAsphaltTexture(withLanes: boolean): THREE.Texture {
  const [c, ctx] = canvas(128);
  ctx.fillStyle = "#34353c";
  ctx.fillRect(0, 0, 128, 128);
  for (let i = 0; i < 1400; i++) {
    const v = 35 + Math.random() * 35;
    ctx.fillStyle = `rgba(${v},${v},${v},0.4)`;
    ctx.fillRect(Math.random() * 128, Math.random() * 128, 1, 1);
  }
  // dashed centre line along v (texture repeats along length)
  ctx.fillStyle = "#d8c24a";
  if (withLanes) {
    for (let y = 8; y < 128; y += 40) ctx.fillRect(62, y, 4, 22);
    // solid edge lines
    ctx.fillStyle = "#cfcfcf";
    ctx.fillRect(10, 0, 3, 128);
    ctx.fillRect(115, 0, 3, 128);
  } else {
    for (let y = 8; y < 128; y += 40) ctx.fillRect(62, y, 3, 18);
  }
  const t = new THREE.CanvasTexture(c);
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  t.anisotropy = 4;
  return t;
}

/** Bumpy normal-ish map for the water surface (scrolled for shimmer). */
export function makeWaterNormal(): THREE.Texture {
  const [c, ctx] = canvas(128);
  ctx.fillStyle = "#8080ff"; // neutral normal
  ctx.fillRect(0, 0, 128, 128);
  for (let i = 0; i < 900; i++) {
    const x = Math.random() * 128, y = Math.random() * 128;
    const g = ctx.createRadialGradient(x, y, 0, x, y, 4 + Math.random() * 6);
    g.addColorStop(0, "rgba(150,150,255,0.9)");
    g.addColorStop(1, "rgba(128,128,255,0)");
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.arc(x, y, 6, 0, Math.PI * 2); ctx.fill();
  }
  const t = new THREE.CanvasTexture(c);
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  return t;
}
