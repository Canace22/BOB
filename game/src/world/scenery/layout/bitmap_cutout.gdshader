shader_type canvas_item;
// Imagegen exterior low-alpha bloom is not a piece of the physical wall.
void fragment(){
	vec4 painted = COLOR;
	if (painted.a < 0.08) { discard; }
	COLOR = painted;
}
