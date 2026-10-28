/** A quiet procedural soundscape. Audio only starts after an explicit player gesture. */
export class Soundscape {
  constructor() {
    this.context = null;
    this.master = null;
    this.muted = false;
    this.started = false;
    this.voices = [];
  }

  start() {
    const AudioContext = globalThis.AudioContext || globalThis.webkitAudioContext;
    if (!AudioContext) return;
    try {
      if (!this.context) {
        this.context = new AudioContext();
        this.master = this.context.createGain();
        this.master.gain.value = this.muted ? 0 : 0.21;
        this.master.connect(this.context.destination);
        // Open fifths with very slow modulation suggest distant water and whale song.
        [55, 82.41, 110.08].forEach((frequency, i) => {
          const oscillator = this.context.createOscillator();
          const gain = this.context.createGain();
          oscillator.type = 'sine';
          oscillator.frequency.value = frequency;
          gain.gain.value = [0.07, 0.035, 0.018][i];
          oscillator.connect(gain).connect(this.master);
          oscillator.start();
          const lfo = this.context.createOscillator();
          const modulation = this.context.createGain();
          lfo.frequency.value = 0.05 + i * 0.023;
          modulation.gain.value = 0.45 + i * 0.22;
          lfo.connect(modulation).connect(oscillator.frequency);
          lfo.start();
          this.voices.push(oscillator, lfo);
        });
      }
      this.context.resume().catch(() => {});
      this.started = true;
    } catch { /* Audio is optional; exploration remains fully playable without it. */ }
  }

  setMuted(value) {
    this.muted = Boolean(value);
    if (this.context && this.master) {
      this.master.gain.setTargetAtTime(this.muted ? 0 : 0.21, this.context.currentTime, 0.12);
    }
  }

  cue(type = 'interact') {
    if (!this.context || this.muted) return;
    const patterns = {
      short: [[330, 0, 0.38], [495, 0.08, 0.3]],
      long: [[164.81, 0, 1], [247, 0.14, 0.9], [330, 0.25, 0.8]],
      resonate: [[330, 0, 0.38], [495, 0.08, 0.3]],
      memory: [[329.63, 0, 0.7], [440, 0.16, 0.7], [659.25, 0.32, 1.1]],
      collect: [[329.63, 0, 0.7], [440, 0.16, 0.7], [659.25, 0.32, 1.1]],
      unlock: [[220, 0, 0.8], [329.63, 0.17, 0.9], [440, 0.34, 1.2]],
      success: [[220, 0, 0.8], [329.63, 0.17, 0.9], [440, 0.34, 1.2]],
      ending: [[164.81, 0, 1.6], [247, 0.3, 1.7], [329.63, 0.6, 2], [440, 0.9, 2.4]],
      jump: [[180, 0, 0.14]],
      fail: [[146.83, 0, 0.6], [110, 0.15, 0.7]],
      reset: [[146.83, 0, 0.6], [110, 0.15, 0.7]],
      interact: [[220, 0, 0.3], [330, 0.09, 0.35]],
      save: [[440, 0, 0.3], [554.37, 0.12, 0.45]],
    };
    const now = this.context.currentTime;
    for (const [frequency, delay, duration] of patterns[type] || patterns.interact) {
      const tone = this.context.createOscillator();
      const envelope = this.context.createGain();
      tone.type = 'sine';
      tone.frequency.setValueAtTime(frequency * 0.985, now + delay);
      tone.frequency.exponentialRampToValueAtTime(frequency, now + delay + Math.min(0.2, duration));
      envelope.gain.setValueAtTime(0, now + delay);
      envelope.gain.linearRampToValueAtTime(0.17, now + delay + 0.025);
      envelope.gain.exponentialRampToValueAtTime(0.001, now + delay + duration);
      tone.connect(envelope).connect(this.master);
      tone.start(now + delay);
      tone.stop(now + delay + duration + 0.05);
      tone.onended = () => { tone.disconnect(); envelope.disconnect(); };
    }
  }

  update() {}
}

export default Soundscape;
