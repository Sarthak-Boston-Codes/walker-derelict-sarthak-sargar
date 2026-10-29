shader_type canvas_item;

// Low-ammo warning for the HUD ammo counter. Spec: CHANGE-BRIEF.md section 2.
// No samplers: the label's own glyph colour arrives in COLOR.

uniform float low_ammo : hint_range(0.0, 1.0) = 0.0;
uniform vec4 warning_color : source_color = vec4(1.0, 0.188, 0.188, 1.0);

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, warning_color.rgb, low_ammo);
}
