shader_type spatial;
render_mode unshaded;

// Hint experiment: one 3x1 PNG (greys 64, 128, 192) bound to two samplers.
// One is decoded as sRGB colour, the other is read as stored.

uniform sampler2D tex_as_colour : source_color, filter_nearest;
uniform sampler2D tex_as_data : filter_nearest;
uniform bool read_as_colour = true;

void fragment() {
	vec3 c = read_as_colour ? texture(tex_as_colour, UV).rgb : texture(tex_as_data, UV).rgb;
	ALBEDO = c;
}
