shader_type canvas_item;
uniform float wind_time = 0.0;
void vertex() {
    float tip = smoothstep(0.40, 1.0, UV.y);
    VERTEX.x += sin(wind_time * 0.72 + UV.x * 9.0) * tip * 4.0;
}
