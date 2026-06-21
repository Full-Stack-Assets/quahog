// Mount Hope radio. Procedural, royalty-free music (Web Audio synth) + scripted
// host voices (Web Speech API). No audio files, no copyright. Stations switch
// live; talk stations speak continuously, music stations drop DJ IDs between
// beds. Must be started from a user gesture (a station button) — handled by
// resuming the AudioContext on setStation.

export interface Host {
  name: string;
  prefs: string[]; // preferred speech-synthesis voice name fragments
  rate: number;
  pitch: number;
  lines: string[];
}

export interface Station {
  id: string;
  dial: string;
  name: string;
  kind: "talk" | "music";
  host: Host;
  tempo: number; // bpm (music)
  root: number; // base freq (Hz)
  minor: boolean;
  prog: number[]; // chord roots (semitones from root)
  scale: number[]; // arp scale (semitones)
  talkGapMs: number; // pause between spoken lines
}

const PENT_MAJ = [0, 2, 4, 7, 9, 12];
const PENT_MIN = [0, 3, 5, 7, 10, 12];

export const STATIONS: Station[] = [
  {
    id: "whale", dial: "92.1", name: "WHALE", kind: "music",
    tempo: 112, root: 130.81, minor: false, prog: [0, -3, 5, 0], scale: PENT_MAJ, talkGapMs: 34000,
    host: {
      name: "Sully", prefs: ["Daniel", "Google UK English Male", "Male"], rate: 1.0, pitch: 0.95,
      lines: [
        "WHALE ninety-two point one, the Whaling City's home for classic rock. Sully with ya.",
        "That one's been spinnin' since before the Braga Bridge needed a new coat of green.",
        "Coming up, a triple shot — but first, keep her between the lines out on Route Eighteen.",
        "Salty air, loud guitars. This is WHALE.",
      ],
    },
  },
  {
    id: "rage", dial: "1480", name: "The Rage", kind: "talk",
    tempo: 0, root: 0, minor: false, prog: [], scale: [], talkGapMs: 1400,
    host: {
      name: "Buddy Mello", prefs: ["Fred", "Google US English", "Male"], rate: 1.16, pitch: 1.0,
      lines: [
        "You're on The Rage with Buddy Mello, and let me TELL ya about the bridge this mornin'.",
        "Forty-five minutes. Forty-five! To go three miles. Somebody explain that to me.",
        "And the potholes — I hit one on Pleasant Street, I think my fillings are still rattlin'.",
        "Caller says lower the speed limit. Lower it? Buddy, we're already PARKED out here!",
        "Alright, alright. Clam roll for lunch. That's the only thing keepin' me sane today.",
        "This is the South Coast, folks. We don't pahk the cah — we sit in it. On the bridge.",
      ],
    },
  },
  {
    id: "anvil", dial: "WBOX", name: "The Anvil", kind: "talk",
    tempo: 0, root: 0, minor: false, prog: [], scale: [], talkGapMs: 1600,
    host: {
      name: "Iron Mike Fontaine", prefs: ["Lee", "Google UK English Male", "Male"], rate: 0.92, pitch: 0.72,
      lines: [
        "This is The Anvil. Iron Mike Fontaine. City of Champions, baby.",
        "You wanna be great? You get up at five, you run the hill, you hit the bag till it begs.",
        "Champion City Gym — that's where legends get forged. Sweat is just weakness leavin' the body.",
        "They ask me, Mike, what's the secret? Heart. You can't teach heart. You earn it.",
        "Stay hungry, South Coast. Keep your hands up. We go again tomorrow.",
      ],
    },
  },
  {
    id: "mare", dial: "105.3", name: "Maré Alta", kind: "music",
    tempo: 96, root: 110.0, minor: true, prog: [0, -2, -5, -7], scale: PENT_MIN, talkGapMs: 38000,
    host: {
      name: "Tia Conceição", prefs: ["Luciana", "Google português", "Female"], rate: 0.98, pitch: 1.05,
      lines: [
        "Maré Alta, cento e cinco. Bom dia, my loves — that's high tide on your dial.",
        "A little saudade for the South Coast Portuguese — from Madeira to the South End.",
        "Put the bacalhau on, open the window. This one's for the avós.",
        "Feast season's coming. Save me a malasada. Maré Alta.",
      ],
    },
  },
];

class RadioEngine {
  private ctx?: AudioContext;
  private master?: GainNode;
  private timer?: number;
  private talkTimer?: number;
  private step = 0;
  private lineIdx = 0;
  private station: Station | null = null;
  vol = 0.5;
  muted = false;

  private ensure() {
    if (!this.ctx) {
      const AC = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      this.ctx = new AC();
      this.master = this.ctx.createGain();
      const filter = this.ctx.createBiquadFilter();
      filter.type = "lowpass";
      filter.frequency.value = 2400;
      this.master.connect(filter);
      filter.connect(this.ctx.destination);
      this.master.gain.value = this.muted ? 0 : this.vol;
    }
    this.ctx.resume();
  }

  current(): Station | null { return this.station; }

  setStation(s: Station | null) {
    this.stop();
    if (!s) return;
    this.ensure();
    this.station = s;
    this.step = 0;
    this.lineIdx = 0;
    if (s.kind === "music") {
      const beatMs = (60 / s.tempo) * 1000;
      this.timer = window.setInterval(() => this.tick(), beatMs);
    }
    // talk stations start talking almost immediately; music stations after a bed
    this.scheduleTalk(s.kind === "talk" ? 600 : s.talkGapMs);
  }

  stop() {
    if (this.timer) { clearInterval(this.timer); this.timer = undefined; }
    if (this.talkTimer) { clearTimeout(this.talkTimer); this.talkTimer = undefined; }
    if (typeof speechSynthesis !== "undefined") speechSynthesis.cancel();
    this.station = null;
  }

  setMuted(m: boolean) {
    this.muted = m;
    if (this.master && this.ctx) this.master.gain.setTargetAtTime(m ? 0 : this.vol, this.ctx.currentTime, 0.05);
    if (m && typeof speechSynthesis !== "undefined") speechSynthesis.cancel();
  }

  // --- music ---
  private tick() {
    const s = this.station;
    const ctx = this.ctx;
    if (!s || !ctx || s.kind !== "music") return;
    const t = ctx.currentTime + 0.03;
    const beat = 60 / s.tempo;
    const chord = s.prog[this.step % s.prog.length];
    const base = s.root * Math.pow(2, chord / 12);
    const third = s.minor ? 3 : 4;
    this.note(base, t, beat * 1.9, 0.05, "triangle");
    this.note(base * Math.pow(2, third / 12), t, beat * 1.9, 0.045, "triangle");
    this.note(base * Math.pow(2, 7 / 12), t, beat * 1.9, 0.04, "sine");
    this.note(base / 2, t, beat * 0.9, 0.11, "sawtooth"); // bass
    const arp = s.scale[this.step % s.scale.length];
    this.note(s.root * 2 * Math.pow(2, arp / 12), t + beat * 0.5, beat * 0.4, 0.035, "square");
    this.step++;
  }

  private note(freq: number, when: number, dur: number, gain: number, type: OscillatorType) {
    const ctx = this.ctx!;
    const o = ctx.createOscillator();
    const g = ctx.createGain();
    o.type = type;
    o.frequency.value = freq;
    o.connect(g);
    g.connect(this.master!);
    g.gain.setValueAtTime(0.0001, when);
    g.gain.linearRampToValueAtTime(gain, when + 0.02);
    g.gain.exponentialRampToValueAtTime(0.0001, when + dur);
    o.start(when);
    o.stop(when + dur + 0.05);
  }

  // --- talk ---
  private scheduleTalk(delay: number) {
    if (this.talkTimer) clearTimeout(this.talkTimer);
    this.talkTimer = window.setTimeout(() => this.speakNext(), delay);
  }

  private speakNext() {
    const s = this.station;
    if (!s || this.muted || typeof speechSynthesis === "undefined") {
      if (s) this.scheduleTalk(s.talkGapMs);
      return;
    }
    const line = s.host.lines[this.lineIdx % s.host.lines.length];
    this.lineIdx++;
    const u = new SpeechSynthesisUtterance(line);
    const v = this.pickVoice(s.host.prefs);
    if (v) u.voice = v;
    u.rate = s.host.rate;
    u.pitch = s.host.pitch;
    u.volume = 1;
    // duck the music bed while the host talks
    if (this.master && this.ctx) this.master.gain.setTargetAtTime(this.muted ? 0 : this.vol * 0.28, this.ctx.currentTime, 0.08);
    u.onend = () => {
      if (this.master && this.ctx) this.master.gain.setTargetAtTime(this.muted ? 0 : this.vol, this.ctx.currentTime, 0.2);
      if (this.station === s) this.scheduleTalk(s.talkGapMs);
    };
    u.onerror = u.onend;
    speechSynthesis.speak(u);
  }

  private pickVoice(prefs: string[]): SpeechSynthesisVoice | null {
    const vs = speechSynthesis.getVoices();
    if (!vs.length) return null;
    for (const p of prefs) {
      const v = vs.find((x) => x.name.toLowerCase().includes(p.toLowerCase()));
      if (v) return v;
    }
    return vs.find((x) => x.lang.startsWith("en")) || vs[0];
  }
}

export const radio = new RadioEngine();
