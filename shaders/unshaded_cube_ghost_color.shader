shader_type spatial;

render_mode unshaded;

uniform vec3 color;
uniform float alpha = 0.5;

void fragment() {
	if (UV.x < 0.005 ||
	    (UV.x > 0.3283 && UV.x < 0.3383) ||
	    (UV.x > 0.6616 && UV.x < 0.6716) ||
	    UV.x > 0.995 ||
	    UV.y < 0.010 ||
	    (UV.y > 0.49 && UV.y < 0.510) ||
	    UV.y > 0.99
	) {
		ALBEDO = vec3(color.x - 0.05, color.y - 0.05, color.z - 0.05);
	} else {
		ALBEDO = color;
	}
	
	ALPHA = alpha;
}