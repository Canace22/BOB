// Modulate source-painted blue water; never displace geometry or sample actors.
uniform float clock = 0.0;
uniform float water_strength = 0.0;
uniform float water_phase = 0.0;
vec3 drifting_water(vec3 painted, vec2 uv) {
    float weight = smoothstep(0.025,0.16,painted.b-painted.r);
    float phase = uv.x*7.0+uv.y*4.0+water_phase;
    float second = uv.x*3.0-uv.y*5.0+water_phase;
    float q = clock*6.28318530718/54.0;
    float flow = 0.65*(sin(phase+q*3.0)-sin(phase));
    flow += 0.35*(sin(second-q*2.0)-sin(second));
    return painted*(1.0+flow*weight*water_strength);
}
