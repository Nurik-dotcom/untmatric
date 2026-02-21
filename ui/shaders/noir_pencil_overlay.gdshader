shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float intensity : hint_range(0.0, 1.0) = 0.34;
uniform float grain_strength : hint_range(0.0, 1.5) = 0.35;
uniform float hatch_strength : hint_range(0.0, 1.5) = 0.3;
uniform float vignette_strength : hint_range(0.0, 1.5) = 0.45;
uniform int fx_quality = 1;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform float jitter_strength : hint_range(0.0, 2.0) = 0.0;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 sample_uv = uv;

	if (fx_quality > 0) {
		float j = (noise2d(vec2(TIME * 24.0, uv.y * 420.0)) - 0.5) * 0.0045;
		sample_uv.x += j * (jitter_strength + pulse * 1.5);
	}

	vec3 src = texture(screen_tex, sample_uv).rgb;
	float luma = dot(src, vec3(0.299, 0.587, 0.114));

	float grain = noise2d(uv * vec2(1100.0, 760.0) + TIME * 8.0) - 0.5;

	float hatch = 0.0;
	if (fx_quality > 0) {
		vec2 p = uv * vec2(1100.0, 680.0);
		float line_a = abs(sin((p.x + p.y) * 0.048));
		float line_b = abs(sin((p.x - p.y) * 0.062 + 1.2));
		hatch = smoothstep(0.78, 1.0, mix(line_a, line_b, 0.5)) * (1.0 - luma);
	}

	float vignette = smoothstep(0.92, 0.22, length(uv - vec2(0.5)));

	float scratch = 0.0;
	if (pulse > 0.001) {
		float scratch_mask = step(0.988, noise2d(vec2(uv.y * 1400.0, TIME * 28.0)));
		scratch = scratch_mask * pulse;
	}

	float mono = luma;
	mono += grain * grain_strength * 0.18;
	mono -= hatch * hatch_strength * 0.22;
	mono -= scratch * 0.2;
	mono = clamp(mono, 0.0, 1.0);

	float blend_strength = clamp(intensity * vignette * vignette_strength + pulse * 0.16, 0.0, 1.0);
	vec3 noir = vec3(mono);
	vec3 out_col = mix(src, noir, blend_strength);

	COLOR = vec4(out_col, 1.0);
}
