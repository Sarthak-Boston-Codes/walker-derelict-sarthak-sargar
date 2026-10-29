shader_type spatial;

// Concrete floor: one colour texture and two data textures.
// Two ShaderMaterials (dry, wet) share this shader. Spec: CHANGE-BRIEF.md section 4.

group_uniforms surface;
uniform vec4 albedo_tint : source_color = vec4(1.0);
uniform float uv_scale : hint_range(0.05, 2.0) = 0.5;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;

group_uniforms response;
uniform sampler2D roughness_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float roughness_scale : hint_range(0.0, 1.0) = 1.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;

group_uniforms wet;
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform float wet_darkening : hint_range(0.0, 1.0) = 0.35;

group_uniforms;

varying vec2 world_uv;

void vertex() {
	// World-space planar UVs, so every floor tile repeats seamlessly.
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_uv = world_pos.xz * uv_scale;
}

void fragment() {
	vec3 base = texture(albedo_tex, world_uv).rgb * albedo_tint.rgb;
	float rough = texture(roughness_tex, world_uv).r * roughness_scale;
	ALBEDO = base * (1.0 - wetness * wet_darkening);
	ROUGHNESS = mix(rough, 0.08, wetness);
	NORMAL_MAP = texture(normal_tex, world_uv).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
}
