shader_type canvas_item;

uniform sampler2D marking_texture : hint_default_transparent;
uniform float marking_opacity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec4 mark = texture(marking_texture, UV);
	float blend = mark.a * marking_opacity;
	COLOR = vec4(mix(base.rgb, mark.rgb, blend), base.a);
}
