// Shared by simulation and renderer: facilities always use the same game clock.
export function getLiftPosition(lift, time, flags = new Set()) {
  const powered = !lift.requires || flags.has(lift.requires);
  const phase = powered ? (1 - Math.cos(time * Math.PI * 2 / lift.period)) / 2 : 0;
  return { x: lift.x, y: lift.maxY - (lift.maxY - lift.minY) * phase, w: lift.w, h: lift.h };
}

export function getSwingPosition(swing, time) {
  const frequency = Math.PI * 2 / swing.period;
  const angle = Math.sin(time * frequency) * swing.amplitude;
  const angularVelocity = Math.cos(time * frequency) * swing.amplitude * frequency;
  return {
    x: swing.x + Math.sin(angle) * swing.length,
    y: swing.y + Math.cos(angle) * swing.length,
    vx: Math.cos(angle) * swing.length * angularVelocity,
    vy: -Math.sin(angle) * swing.length * angularVelocity,
  };
}
