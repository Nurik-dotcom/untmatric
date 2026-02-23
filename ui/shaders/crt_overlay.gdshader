shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform vec4 tint_color : source_color = vec4(0.0, 1.0, 0.25, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.12;
uniform int fx_quality = 0;
uniform float jitter_strength : hint_range(0.0, 1.0) = 0.0;
uniform float glitch_strength : hint_range(0.0, 2.0) = 0.0;
uniform float pulse : hint_range(0.0, 3.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float scan = 0.5 + 0.5 * sin((uv.y * 900.0) + TIME * 12.0);
	float vig = smoothstep(0.95, 0.2, length(uv - vec2(0.5)));

	vec2 sample_uv = uv;
	if (fx_quality > 0) {
		float jitter = (fract(sin((TIME * 27.13) + uv.y * 311.77) * 43758.5453) - 0.5) * 0.008;
		sample_uv.x += jitter * jitter_strength;
		float shift = glitch_strength * (sin(TIME * 35.0 + uv.y * 80.0)) * 0.003;
		sample_uv.x += shift;
	}

	vec3 src = texture(screen_tex, sample_uv).rgb;
	float pulse_wave = 1.0 + (sin(TIME * 4.0 + uv.y * 18.0) * 0.08 * pulse);
	float overlay = intensity * mix(0.65, 1.0, scan) * vig * pulse_wave;
	vec3 tint = mix(src, tint_color.rgb, overlay);
	COLOR = vec4(tint, overlay);
}
