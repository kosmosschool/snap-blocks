shader_type spatial;

render_mode unshaded, cull_disabled;


void vertex() {
	COLOR = INSTANCE_CUSTOM;
}

void fragment() {
	ALBEDO = vec3(COLOR[0],COLOR[1],COLOR[2]);
}
