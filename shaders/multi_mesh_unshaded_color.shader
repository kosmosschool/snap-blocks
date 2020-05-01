shader_type spatial;

render_mode unshaded, cull_disabled;

uniform bool primary;

void vertex() {
	if (primary) {
		COLOR = INSTANCE_CUSTOM;
	} else {
		// TODO: what happens when value negative?
		COLOR = vec4(INSTANCE_CUSTOM.x - 0.05, INSTANCE_CUSTOM.y - 0.05, INSTANCE_CUSTOM.z - 0.05, 1.0);
	}
}

void fragment() {
	ALBEDO = vec3(COLOR[0],COLOR[1],COLOR[2]);
}
