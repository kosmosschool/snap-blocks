shader_type spatial;

render_mode unshaded;


varying vec3 primary_color;
varying vec3 secondary_color;

void vertex() {
	primary_color = vec3(INSTANCE_CUSTOM.x, INSTANCE_CUSTOM.y, INSTANCE_CUSTOM.z);
	secondary_color = vec3(INSTANCE_CUSTOM.x - 0.05, INSTANCE_CUSTOM.y - 0.05, INSTANCE_CUSTOM.z - 0.05);
}

void fragment() {
	if (UV.x < 0.02 || UV.x > 0.98 || UV.y < 0.02 || UV.y > 0.98) {
		ALBEDO = secondary_color;
	} else {
		ALBEDO = primary_color;
	}
}
