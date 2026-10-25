shader_type spatial;
// Factory floor: gritty concrete slabs with seams and rust/oil stains, all
// in world space so any floor mesh tiles seamlessly.

uniform sampler2D grit : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D stains : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform vec3 base_color : source_color = vec3(0.30, 0.31, 0.30);
uniform vec3 rust_color : source_color = vec3(0.42, 0.20, 0.10);
uniform vec3 oil_color : source_color = vec3(0.05, 0.05, 0.05);
uniform float slab_size = 4.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float g = texture(grit, p * 0.21).r;
	float s = texture(stains, p * 0.043).r;
	float o = texture(stains, p * 0.031 + vec2(0.37, 0.71)).r;
	vec2 f = abs(fract(p / slab_size + 0.5) - 0.5) * slab_size;
	float seam = 1.0 - smoothstep(0.015, 0.05, min(f.x, f.y));
	vec3 c = base_color * (0.7 + 0.6 * g);
	float rust = smoothstep(0.58, 0.82, s);
	float oil = smoothstep(0.66, 0.8, o);
	c = mix(c, rust_color * (0.6 + 0.5 * g), rust * 0.75);
	c = mix(c, oil_color, oil * 0.7);
	c *= 1.0 - seam * 0.65;
	ALBEDO = c;
	ROUGHNESS = mix(0.92, 0.35, oil);
	SPECULAR = 0.4;
}
