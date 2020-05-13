shader_type spatial;

render_mode unshaded;

uniform vec3 color;

void fragment() {
	if (UV.x < 0.01 ||
		(UV.x > 0.3233 && UV.x < 0.3433) ||
		(UV.x > 0.6566 && UV.x < 0.6766) ||
		UV.x > 0.99 ||
		UV.y < 0.015 ||
		(UV.y > 0.485 && UV.y < 0.515) ||
		UV.y > 0.985
	) {
		ALBEDO = vec3(color.x - 0.05, color.y - 0.05, color.z - 0.05);
	} else {
		ALBEDO = color;
	}
}