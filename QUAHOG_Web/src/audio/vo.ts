// Voice-over client (§33). Routes a spoken line through the server ElevenLabs
// proxy (/api/tts) for a real character voice; if the key isn't configured (503)
// or the request fails, it transparently falls back to the Web Speech API so VO
// always works offline/unconfigured. Character → env-var mapping lives in
// api/tts.ts (voice "mike" → ELEVENLABS_MIKE_VOICE).

let remoteAvailable: boolean | null = null; // null = unknown, false = key absent

export interface VoiceReq {
  text: string;
  voice: string;        // character key, e.g. "mike", "sully", "buddy"
  rate?: number;        // Web Speech fallback tuning
  pitch?: number;
  prefs?: string[];     // Web Speech voice-name fragments
  onend?: () => void;
}

function speakLocal(req: VoiceReq) {
  if (typeof speechSynthesis === "undefined") { req.onend?.(); return; }
  const u = new SpeechSynthesisUtterance(req.text);
  const vs = speechSynthesis.getVoices();
  if (vs.length && req.prefs) {
    for (const p of req.prefs) {
      const v = vs.find((x) => x.name.toLowerCase().includes(p.toLowerCase()));
      if (v) { u.voice = v; break; }
    }
    if (!u.voice) u.voice = vs.find((x) => x.lang.startsWith("en")) || vs[0];
  }
  u.rate = req.rate ?? 1;
  u.pitch = req.pitch ?? 1;
  u.onend = () => req.onend?.();
  u.onerror = u.onend;
  speechSynthesis.speak(u);
}

let audio: HTMLAudioElement | null = null;

/** Speak a line with the best available voice; never throws. */
export async function speak(req: VoiceReq) {
  if (remoteAvailable === false) { speakLocal(req); return; }
  try {
    const r = await fetch("/api/tts", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ text: req.text, voice: req.voice }),
    });
    // 503 == server has no API key at all → stop trying remote for the session.
    // Any other failure (a single voice, a transient upstream error) just falls
    // back for THIS line so one bad call can't mute every host (§33).
    if (r.status === 503) { remoteAvailable = false; speakLocal(req); return; }
    if (!r.ok) { speakLocal(req); return; }
    remoteAvailable = true;
    const url = URL.createObjectURL(await r.blob());
    audio?.pause();
    audio = new Audio(url);
    audio.onended = () => { URL.revokeObjectURL(url); req.onend?.(); };
    audio.onerror = () => { URL.revokeObjectURL(url); speakLocal(req); };
    await audio.play();
  } catch {
    speakLocal(req);
  }
}

/** Stop any in-flight VO (both paths). */
export function stopVO() {
  audio?.pause();
  if (typeof speechSynthesis !== "undefined") speechSynthesis.cancel();
}
