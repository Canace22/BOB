export class Sound {
  constructor() { this.enabled = true; this.context = null; }
  start() {
    if (!this.enabled) return;
    if (!this.context) {
      this.context = new AudioContext();
      this.master = this.context.createGain(); this.master.gain.value = .13; this.master.connect(this.context.destination);
      for (const frequency of [49, 73.5]) {
        const oscillator = this.context.createOscillator(); const gain = this.context.createGain();
        oscillator.frequency.value = frequency; oscillator.type = 'sine'; gain.gain.value = .12;
        oscillator.connect(gain); gain.connect(this.master); oscillator.start();
      }
    }
    this.context.resume().catch(() => {});
  }
  toggle() { this.enabled = !this.enabled; if (this.master) this.master.gain.value = this.enabled ? .13 : 0; if (this.enabled) this.start(); return this.enabled; }
  note(frequency = 220, duration = .3, type = 'sine', volume = .5) {
    if (!this.enabled || !this.context) return;
    const t = this.context.currentTime, oscillator = this.context.createOscillator(), gain = this.context.createGain();
    oscillator.type = type; oscillator.frequency.setValueAtTime(frequency, t); oscillator.frequency.exponentialRampToValueAtTime(frequency * .75, t + duration);
    gain.gain.setValueAtTime(.001, t); gain.gain.linearRampToValueAtTime(volume, t + .015); gain.gain.exponentialRampToValueAtTime(.001, t + duration);
    oscillator.connect(gain); gain.connect(this.master); oscillator.start(t); oscillator.stop(t + duration + .03);
    oscillator.onended = () => { oscillator.disconnect(); gain.disconnect(); };
  }
}
