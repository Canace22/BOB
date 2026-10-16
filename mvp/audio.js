// Quiet, self-contained underwater ambience. Call start() from a user gesture.
export class Soundscape {
  constructor() {
    this.context = null;
    this.master = null;
    this.room = 0;
    this._muted = false;
    this.drones = [];
    this.lastPlayed = new Map();
  }

  get muted() {
    return this._muted;
  }

  async start() {
    try {
      if (!this.context) {
        if (navigator.userActivation && !navigator.userActivation.isActive) return false;
        const AudioContext = window.AudioContext || window.webkitAudioContext;
        if (!AudioContext) return false;
        this.context = new AudioContext();
        this.master = this.context.createGain();
        this.master.gain.value = this._muted ? 0 : 0.22;
        this.master.connect(this.context.destination);
        this._startAmbience();
      }
      if (this.context.state === "suspended") await this.context.resume();
      return this.context.state === "running";
    } catch {
      return false;
    }
  }

  setMuted(muted) {
    this._muted = Boolean(muted);
    if (!this.context) return;
    const now = this.context.currentTime;
    this.master.gain.cancelScheduledValues(now);
    this.master.gain.setValueAtTime(this.master.gain.value, now);
    this.master.gain.linearRampToValueAtTime(this._muted ? 0 : 0.22, now + 0.06);
  }

  setRoom(index) {
    this.room = Number.isFinite(index) ? Math.max(0, Math.floor(index)) : 0;
    if (!this.context) return;
    const base = [46.25, 43.65, 49, 55][this.room % 4];
    this.drones.forEach((oscillator, index) => {
      oscillator.frequency.setTargetAtTime(base * (index ? 1.501 : 1), this.context.currentTime, 2);
    });
  }

  play(kind) {
    if (!this.context || this.context.state !== "running" || this._muted) return;
    const now = this.context.currentTime;
    const gap = kind === "resonance" ? 0.32 : 0.08;
    if (now - (this.lastPlayed.get(kind) ?? -Infinity) < gap) return;
    this.lastPlayed.set(kind, now);

    const tone = (from, to, duration, volume = 0.12, delay = 0, type = "sine") => {
      this._tone(from, to, duration, volume, now + delay, type);
    };
    switch (kind) {
      case "resonance":
        tone(164.81, 82.41, 1.3, 0.15);
        tone(247.22, 123.61, 1.6, 0.06, 0.06);
        break;
      case "jump":
        tone(125, 220, 0.22, 0.07);
        break;
      case "collect":
        tone(329.63, 329.63, 0.4, 0.1);
        tone(493.88, 493.88, 0.6, 0.08, 0.12);
        break;
      case "activate":
        [130.81, 196, 261.63].forEach((pitch, index) => tone(pitch, pitch, 1.3, 0.09, index * 0.12));
        break;
      case "hurt":
        tone(105, 48, 0.45, 0.12, 0, "triangle");
        break;
      case "complete":
        [174.61, 220, 261.63, 349.23].forEach((pitch, index) => tone(pitch, pitch, 2, 0.1, index * 0.2));
        break;
    }
  }

  _tone(from, to, duration, volume, start, type = "sine") {
    const oscillator = this.context.createOscillator();
    const envelope = this.context.createGain();
    oscillator.type = type;
    oscillator.frequency.setValueAtTime(from, start);
    oscillator.frequency.exponentialRampToValueAtTime(to, start + duration);
    envelope.gain.setValueAtTime(0.0001, start);
    envelope.gain.exponentialRampToValueAtTime(volume, start + Math.min(0.08, duration * 0.2));
    envelope.gain.exponentialRampToValueAtTime(0.0001, start + duration);
    oscillator.connect(envelope);
    envelope.connect(this.master);
    oscillator.onended = () => {
      oscillator.disconnect();
      envelope.disconnect();
    };
    oscillator.start(start);
    oscillator.stop(start + duration + 0.03);
  }

  _startAmbience() {
    const now = this.context.currentTime;
    [0.055, 0.02].forEach((volume, index) => {
      const oscillator = this.context.createOscillator();
      const gain = this.context.createGain();
      oscillator.type = "sine";
      oscillator.frequency.value = [46.25, 43.65, 49, 55][this.room % 4] * (index ? 1.501 : 1);
      gain.gain.setValueAtTime(0, now);
      gain.gain.linearRampToValueAtTime(volume, now + 3);
      oscillator.connect(gain);
      gain.connect(this.master);
      oscillator.start();
      this.drones.push(oscillator);
    });
    this.setRoom(this.room);
    let nextWhale = now + 2;
    this.ambienceTimer = window.setInterval(() => {
      if (this.context.state !== "running" || this._muted) return;
      const time = this.context.currentTime;
      if (time >= nextWhale) {
        const pitch = 92 + this.room * 3;
        this._tone(pitch, pitch * 0.68, 4.5, 0.035, time);
        this._tone(pitch * 1.49, pitch * 1.12, 3.5, 0.012, time + 0.5);
        nextWhale = time + 13 + Math.random() * 7;
      }
      if (Math.random() < 0.55) {
        const pitch = 220 + Math.random() * 160;
        this._tone(pitch, pitch * 1.25, 0.18, 0.018, time + 0.1);
        this._tone(pitch * 0.8, pitch, 0.15, 0.01, time + 0.4);
      }
    }, 2400);
  }
}
