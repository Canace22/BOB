shader_type canvas_item;
// 仅接缝透明度，不再次乘贴图；骨骼与器官本体保持静止。
void fragment() {
    COLOR.a *= smoothstep(0.0, 0.12, UV.x) * smoothstep(0.0, 0.12, 1.0 - UV.x);
}
