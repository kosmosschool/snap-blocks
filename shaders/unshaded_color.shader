shader_type spatial;

render_mode unshaded;

uniform vec3 color;


void fragment() {
	ALBEDO = color;
}

