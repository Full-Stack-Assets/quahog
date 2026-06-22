// Mount Hope radio. Procedural, royalty-free music (Web Audio synth) + scripted
// host voices — real ElevenLabs VO when configured, else Web Speech (see vo.ts).
// No audio files, no copyright. Stations switch live; talk stations speak
// continuously, music stations drop DJ IDs between beds. Must be started from a
// user gesture (a station button) — handled by resuming the AudioContext.
import { speak, stopVO } from "./vo";
import { useStats } from "../game";
import { useGame } from "../store";

export interface Host {
  name: string;
  voice?: string;  // VO character key → ELEVENLABS_<KEY>_VOICE (e.g. "mike")
  prefs: string[]; // preferred speech-synthesis voice name fragments (fallback)
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
      name: "Sully", voice: "sully", prefs: ["Daniel", "Google UK English Male", "Male"], rate: 1.0, pitch: 0.95,
      lines: [
        "WHALE ninety-two point one, the Whaling City's home for classic rock. Sully with ya.",
        "That one's been spinnin' since before the Braga Bridge needed a new coat of green.",
        "Comin' up, a triple shot — but first, keep her between the lines out on Route Eighteen.",
        "Salty air, loud guitars. This is WHALE.",
        "Sixty-one degrees down on the waterfront, fog burnin' off by noon. Beautiful day to do nothin'.",
        "Fishin' fleet's headed out past Palmer's Island — fair winds, fellas. Bring back the haddock.",
        "Dedication goin' out to the third shift at the mill. Hang in there, you're almost home.",
        "Word to the wise: the bridge tender's got her open for a tall mast, so Pope's Island's a parking lot. Sit back, turn it up.",
        "You're ridin' with Sully, and we do not, I repeat, do NOT take requests for disco. Not on this frequency.",
        "Car runnin' rough? Slide it down to the Anvil Garage on the waterfront — tell Sal that Sully sent ya.",
        "It's a long-hair, leather-jacket, windows-down kinda afternoon on the South Coast.",
        "Quick one for ya — last call at the Quohog Republic is whenever the owner falls asleep. Pace yourselves.",
        "We're commercial-free for the next forty minutes 'cause I forgot to cue the cart. You're welcome.",
        "Sun's goin' down over Clark's Cove, sky's the color of a bruised peach. Here's somethin' to match it.",
        "Big weekend ahead — cruise night down County Street, chrome for miles. Don't race past the church, the cops sit there.",
        "This next one goes to my ex-wife. She knows what she did.",
        "Crank it loud enough and you can't hear the rust forming on your Bronco. Science.",
        "Ninety-two point one — if your speakers ain't buzzin', you ain't doin' it right.",
        "Thunderstorm rollin' up Buzzards Bay later, so get the wash off the line, Ma.",
        "Stay greasy, stay gold, South Coast. Sully's outta here — back tomorrow if the transmitter holds.",
      ],
    },
  },
  {
    id: "rage", dial: "1480", name: "The Rage", kind: "talk",
    tempo: 0, root: 0, minor: false, prog: [], scale: [], talkGapMs: 1400,
    host: {
      name: "Buddy Mello", voice: "buddy", prefs: ["Fred", "Google US English", "Male"], rate: 1.16, pitch: 1.0,
      lines: [
        "You're on The Rage with Buddy Mello, and let me TELL ya about the bridge this mornin'.",
        "Forty-five minutes. Forty-five! To go three miles. Somebody explain that to me.",
        "And the potholes — I hit one on Pleasant Street, I think my fillings are still rattlin'.",
        "Caller says lower the speed limit. Lower it? Buddy, we're already PARKED out here!",
        "Alright, alright. Clam roll for lunch. That's the only thing keepin' me sane today.",
        "This is the South Coast, folks. We don't pahk the cah — we sit in it. On the bridge.",
        "Line one, you're on the Rage. Sir — SIR — you cannot blame the seagulls for everything.",
        "They wanna put a parking meter on EVERY corner downtown. What is this, Boston? Get outta here.",
        "My brother-in-law says he caught a striper off the hurricane barrier THIS big. He's a liar. We all know it.",
        "Fourteen-eighty AM, the only station that says what you're all THINKIN' in traffic.",
        "Some genius left the Coggeshall Street bridge open for twenty minutes. Twenty! For one sailboat!",
        "You know what grinds my gears? People who don't wave when you let 'em merge. Where's the respect?",
        "Caller from Fairhaven says we never talk about Fairhaven. We're talkin' about it NOW, ya happy?",
        "The town wants to raise my taxes again. For what? The potholes are eatin' my Buick ALIVE.",
        "Hungry? Linguiça Linq is open all night — best chouriço and eggs this side of the Acushnet. Tell 'em Buddy sent ya, get nothin' off, but tell 'em anyway.",
        "I said it last week, I'll say it again: the rotary is not a SUGGESTION, people!",
        "We got Bobby on the line, he's been holdin' since the last commercial. Bobby, you still alive?",
        "Need a ride and your cah's in the shop again? Whaling City Cab. They'll find ya. Eventually.",
        "Nor'easter comin' Thursday, they say a foot. They ALWAYS say a foot. We'll get a dustin' and they'll close the schools anyway.",
        "That's the show. Be good to each other, and for the love of Pete, use your blinkah. Buddy Mello, signin' off.",
      ],
    },
  },
  {
    id: "anvil", dial: "WBOX", name: "The Anvil", kind: "talk",
    tempo: 0, root: 0, minor: false, prog: [], scale: [], talkGapMs: 1600,
    host: {
      name: "Iron Mike Fontaine", voice: "mike", prefs: ["Lee", "Google UK English Male", "Male"], rate: 0.92, pitch: 0.72,
      lines: [
        "This is The Anvil. Iron Mike Fontaine. City of Champions, baby.",
        "You wanna be great? You get up at five, you run the hill, you hit the bag till it begs.",
        "Champion City Gym — that's where legends get forged. Sweat is just weakness leavin' the body.",
        "They ask me, Mike, what's the secret? Heart. You can't teach heart. You earn it.",
        "Stay hungry, South Coast. Keep your hands up. We go again tomorrow.",
        "Some kid came in my gym yesterday, soft hands, soft eyes. Two weeks later? Different animal. That's the work.",
        "I been hit by guys twice my size and I'm still standin'. You think a Monday's gonna stop me? Please.",
        "Discipline ain't punishment, ya hear me? Discipline is LOVE. Love for who you're gonna become.",
        "Three rounds left in ya. Always. When you got nothin' left, you got three rounds. Dig.",
        "They knocked this city down — the mills closed, the boats slowed — and what'd we do? We got UP. Eight count. We got up.",
        "You skip roadwork, the ring knows. The ring always knows. It can smell a quitter.",
        "Don't tell me about talent. Talent sleeps in. I'll take the hungry kid over the gifted one every single time.",
        "Fear's just a bell, champ. It rings, you answer, you go to work.",
        "Champion City Gym, corner spot, smells like liniment and ambition. Door's always open. Excuses are not.",
        "My old trainer told me: your fists are honest. Everything else'll lie to ya, but your fists tell the truth.",
        "You get dropped? Good. Now we find out what you're made of. Get UP.",
        "I don't believe in cantt. I knew a fella named Cantt once. Glass jaw. Don't be a Cantt.",
        "The body's a tool and pain's the whetstone. You sharpen, or you rust. Your choice.",
        "Somebody asked if I ever lost. Course I lost. Losin' taught me everything winnin' couldn't.",
        "Lights out, hands up, chin down. The Anvil. We forge or we fold — and we don't fold.",
      ],
    },
  },
  {
    id: "mare", dial: "105.3", name: "Maré Alta", kind: "music",
    tempo: 96, root: 110.0, minor: true, prog: [0, -2, -5, -7], scale: PENT_MIN, talkGapMs: 38000,
    host: {
      name: "Tia Conceição", voice: "tia", prefs: ["Luciana", "Google português", "Female"], rate: 0.98, pitch: 1.05,
      lines: [
        "Maré Alta, cento e cinco. Bom dia, my loves — that's high tide on your dial.",
        "A little saudade for the South Coast Portuguese — from Madeira to the South End.",
        "Put the bacalhau on, open the window. This one's for the avós.",
        "Feast season's coming. Save me a malasada. Maré Alta.",
        "For everyone working the docks this morning — força, my dears. The sea gives, the sea takes.",
        "This one's from Conceição in the North End to her filho out fishing on the Georges Bank. Come home safe, querido.",
        "Cape Verde, Açores, Madeira, the continent — todos juntos here on the South Coast. One family, one tide.",
        "The Feast of the Blessed Sacrament, the biggest Portuguese feast in all of America, right here in the Madeira club. I'll see you under the lights.",
        "Carne de espeto on the grill, the smell coming down Acushnet Avenue — ai, that's home.",
        "A song for the saudade — for the village you left and still carry in here, in the heart.",
        "Need the new fado record or a little morna from the islands? Maré Alta Records, downtown — diga que a Tia mandou.",
        "Rain on the way, they say. Good. The garden needs it, and so does my soul. Vamos dançar anyway.",
        "Don't forget the avó's name day on Sunday. Flowers. Real ones. She'll know if they're from the gas station.",
        "From the South End to Clark's Point, from the bridge to the boats — boa tarde, my beautiful people.",
        "A little morna for the heartbroken, a little coladeira for the hopeful. We have both tonight.",
        "They work so hard, our people. Two jobs, three jobs, and still they dance at the feast. That is strength.",
        "This is for the mothers who crossed an ocean so their children could complain about traffic. Obrigada, mães.",
        "High tide at the hurricane barrier, gulls crying over the fish house. The whole city smells like the sea and I love it.",
        "Keep the faith, keep the family, keep the music. Maré Alta, cento e cinco. Até logo, my loves.",
      ],
    },
  },
];

// --- station-agnostic content (§19 radio depth): ads, idents, news/weather,
// and lines that react to the player's wanted level. Read in the host voice.
const pick = <T,>(a: T[]) => a[Math.floor(Math.random() * a.length)];

const ADS = [
  "Engine knockin' like a screen door in a nor'easter? The Anvil Garage, on the waterfront — we'll get her runnin' right, no questions asked.",
  "Quohog Republic. Cold beer, hot chowder, and a jukebox that only knows the seventies. Down on the docks.",
  "Linguiça Linq — chouriço and eggs, twenty-four hours. 'Cause some hungers don't keep banker's hours.",
  "Maré Alta Records, downtown — fado, funaná, rock and roll. If we don't have it, you don't need it.",
  "Whaling City Cab. Two trucks, one that starts. We'll get ya there. Probably.",
  "This weekend at the Madeira Field — carne de espeto, malasadas, and the carousel that's older than your grandfather.",
  "Sal's Marine Supply, Pope's Island. Nets, traps, and lies about the one that got away. All half off.",
  "Buy American, buy local, buy a clam roll the size of your fist. That's the South Coast guarantee.",
];

const IDS = [
  "You're locked in.",
  "All across the South Coast.",
  "From the harbor to the highway.",
  "Turn it up.",
  "Nobody does it like we do it.",
];

const NEWS = [
  "Top of the hour: the harbor commission says dredging's behind schedule again. In other words, water's still wet.",
  "City council voted to study the pothole problem. The study fell in a pothole. We'll keep you posted.",
  "Fish prices up at the auction this mornin' — good news for the fleet, bad news for your Friday supper.",
  "The bridge will be openin' on the half hour all weekend, so plan accordingly, or don't, and suffer.",
];

const WANTED = [
  "Scanner's lightin' up down by the waterfront — sounds like somebody's havin' an exciting evening. Stay clear, folks.",
  "Lotta blue lights downtown tonight. Whatever you did, pal — and somebody did somethin' — knock it off.",
  "Police all over the South End. If that's one of you listenin', maybe ease off the gas, huh?",
];
const RAIN = ["Wipers on, comin' down steady off the bay.", "Roads are slick as a politician's promise tonight — easy out there."];
const FOG = ["Pea-soup fog on the harbor — foghorn's earnin' its keep.", "Can't see the end of the pier in this fog. Drive like it."];

class RadioEngine {
  private ctx?: AudioContext;
  private master?: GainNode;
  private timer?: number;
  private talkTimer?: number;
  private step = 0;
  private lineIdx = 0;
  private seg = 0;
  private station: Station | null = null;
  private music?: HTMLAudioElement;   // real licensed/generated tracks (§19 music)
  private musicTracks: string[] = [];
  private jingles: string[] = [];     // station IDs/bumpers for talk dials
  private jingleAudio?: HTMLAudioElement;
  vol = 0.5;
  muted = false;
  private duck = 1; // adaptive ducking (lowered under police heat)
  /** Subtitle sink (§33): set by the HUD to caption the currently spoken line. */
  onSubtitle: ((s: { name: string; text: string } | null) => void) | null = null;
  private emitSub(s: { name: string; text: string } | null) { try { this.onSubtitle?.(s); } catch { /* no sink */ } }
  /** Now-playing track sink: set by the Radio panel to show the current song. */
  onTrack: ((name: string) => void) | null = null;
  private currentTrack = "";
  private lastUrl = "";
  private emitTrack(name: string) { this.currentTrack = name; try { this.onTrack?.(name); } catch { /* no sink */ } }
  /** Current real track display name ("" when on the synth bed or a talk dial). */
  trackName() { return this.currentTrack; }
  /** Skip to another real track on the current music station (no-op otherwise). */
  skipTrack() { if (this.station?.kind === "music" && this.musicTracks.length) this.playTrack(); }

  setDuck(d: number) {
    this.duck = d;
    if (this.master && this.ctx && !this.muted) this.master.gain.setTargetAtTime(this.vol * d, this.ctx.currentTime, 0.4);
    if (this.music) this.music.volume = this.muted ? 0 : this.vol * d;
  }

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
    this.seg = 0;
    if (s.kind === "music") this.loadMusic(s);
    this.loadJingles(s);
    // talk stations start talking almost immediately; music stations after a bed
    this.scheduleTalk(s.kind === "talk" ? 600 : s.talkGapMs);
  }

  // Station jingles/bumpers (public/music/<id>/jingles/) played between segments.
  private loadJingles(s: Station) {
    this.jingles = [];
    fetch(`music/${s.id}/jingles/manifest.json`)
      .then((r) => (r.ok ? r.json() : null))
      .then((mf: { tracks?: string[] } | null) => {
        if (this.station !== s || !mf?.tracks?.length) return;
        this.jingles = mf.tracks.map((f) => /^(https?:)?\/\//.test(f) ? f : `music/${s.id}/jingles/${f}`);
      })
      .catch(() => { /* no jingles */ });
  }

  // Real music when public/music/<id>/manifest.json exists; else procedural synth.
  private startSynth(s: Station) {
    const beatMs = (60 / s.tempo) * 1000;
    this.timer = window.setInterval(() => this.tick(), beatMs);
  }
  private loadMusic(s: Station) {
    this.musicTracks = [];
    // a track may be a bare filename (public/music/<id>/) or an absolute URL
    // (webhook-delivered to Blob/CDN) — accept both.
    const resolve = (tracks: string[]) => tracks.map((f) => /^(https?:)?\/\//.test(f) ? f : `music/${s.id}/${f}`);
    const play = (tracks?: string[]): boolean => {
      if (this.station !== s || !tracks || !tracks.length) return false;
      this.musicTracks = resolve(tracks);
      this.playTrack();
      return true;
    };
    // 1) Blob-backed manifest (webhook delivery) → 2) static public manifest →
    // 3) procedural synth bed.
    fetch(`api/music?station=${s.id}`)
      .then((r) => (r.ok ? r.json() : null))
      .then((mf: { tracks?: string[] } | null) => {
        if (this.station !== s) return;
        if (play(mf?.tracks)) return;
        fetch(`music/${s.id}/manifest.json`)
          .then((r) => (r.ok ? r.json() : null))
          .then((mf2: { tracks?: string[] } | null) => {
            if (this.station !== s) return;
            if (!play(mf2?.tracks)) this.startSynth(s);
          })
          .catch(() => { if (this.station === s) this.startSynth(s); });
      })
      .catch(() => { if (this.station === s) this.startSynth(s); });
  }
  private playTrack() {
    // avoid replaying the same file back-to-back when there's a choice
    let url = pick(this.musicTracks);
    if (this.musicTracks.length > 1) { let guard = 0; while (url === this.lastUrl && guard++ < 8) url = pick(this.musicTracks); }
    this.lastUrl = url;
    if (!this.music) this.music = new Audio();
    this.music.src = url;
    this.music.loop = false;
    this.music.muted = this.muted;
    this.music.volume = this.vol;
    this.music.onended = () => { if (this.musicTracks.length) this.playTrack(); };
    this.music.play().catch(() => {});
    // publish a clean display name (basename, no extension)
    const base = decodeURIComponent(url.split("/").pop() || "").replace(/\.[a-z0-9]+$/i, "");
    this.emitTrack(base);
  }

  stop() {
    if (this.timer) { clearInterval(this.timer); this.timer = undefined; }
    if (this.talkTimer) { clearTimeout(this.talkTimer); this.talkTimer = undefined; }
    if (this.music) { this.music.pause(); this.music.onended = null; }
    if (this.jingleAudio) { this.jingleAudio.pause(); this.jingleAudio.onended = null; }
    this.musicTracks = [];
    this.jingles = [];
    this.lastUrl = "";
    stopVO();
    this.emitSub(null);
    this.emitTrack("");
    this.station = null;
  }

  setMuted(m: boolean) {
    this.muted = m;
    if (this.master && this.ctx) this.master.gain.setTargetAtTime(m ? 0 : this.vol, this.ctx.currentTime, 0.05);
    if (this.music) this.music.muted = m;
    if (m) { stopVO(); this.emitSub(null); }
  }

  setVolume(v: number) {
    this.vol = Math.max(0, Math.min(1, v));
    if (this.master && this.ctx && !this.muted) this.master.gain.setTargetAtTime(this.vol, this.ctx.currentTime, 0.05);
    if (this.music) this.music.volume = this.vol;
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
    if (!s || this.muted) {
      if (s) this.scheduleTalk(s.talkGapMs);
      return;
    }
    // every so often, drop a station jingle/bumper instead of a spoken line
    if (this.jingles.length && this.seg > 0 && this.seg % 4 === 0) {
      this.seg++;
      const url = pick(this.jingles);
      if (!this.jingleAudio) this.jingleAudio = new Audio();
      const j = this.jingleAudio;
      j.src = url; j.muted = this.muted; j.volume = this.vol;
      if (this.music) this.music.volume = this.muted ? 0 : this.vol * 0.2; // duck bed under the jingle
      this.emitSub({ name: s.name, text: "♪ station ID" });
      const finish = () => {
        if (this.music) this.music.volume = this.muted ? 0 : this.vol;
        this.emitSub(null);
        if (this.station === s) this.scheduleTalk(s.talkGapMs);
      };
      j.onended = finish;
      j.onerror = finish;
      j.play().catch(finish);
      return;
    }
    const line = this.chooseSegment(s);
    // duck the music bed (synth + real track) while the host talks
    if (this.master && this.ctx) this.master.gain.setTargetAtTime(this.muted ? 0 : this.vol * 0.28, this.ctx.currentTime, 0.08);
    if (this.music) this.music.volume = this.muted ? 0 : this.vol * 0.2;
    this.emitSub({ name: s.host.name, text: line }); // caption (§33)
    const done = () => {
      if (this.master && this.ctx) this.master.gain.setTargetAtTime(this.muted ? 0 : this.vol, this.ctx.currentTime, 0.2);
      if (this.music) this.music.volume = this.muted ? 0 : this.vol;
      this.emitSub(null);
      if (this.station === s) this.scheduleTalk(s.talkGapMs);
    };
    // real ElevenLabs voice when configured, else Web Speech (vo.ts handles both)
    speak({
      text: line,
      voice: s.host.voice ?? "narrator",
      rate: s.host.rate,
      pitch: s.host.pitch,
      prefs: s.host.prefs,
      onend: done,
    });
  }

  // Interleave host lines with ads, idents, news, and reactive weather/wanted
  // chatter so the dial feels alive (§19 radio depth).
  private chooseSegment(s: Station): string {
    this.seg++;
    try {
      const police = useStats.getState().police;
      const weather = useGame.getState().weather;
      if (police >= 3 && Math.random() < 0.28) return pick(WANTED);
      if (weather === "rain" && Math.random() < 0.18) return pick(RAIN);
      if (weather === "fog" && Math.random() < 0.18) return pick(FOG);
    } catch { /* stores not ready */ }
    if (this.seg % 4 === 0) return pick(ADS);
    if (this.seg % 9 === 0) return `${s.dial}, ${s.name}. ${pick(IDS)}`;
    if (s.kind === "talk" && this.seg % 6 === 0) return pick(NEWS);
    const line = s.host.lines[this.lineIdx % s.host.lines.length];
    this.lineIdx++;
    return line;
  }
}

export const radio = new RadioEngine();
