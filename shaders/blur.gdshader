shader_type canvas_item;
render_mode unshaded;

uniform float blur_size = 3.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 off = SCREEN_PIXEL_SIZE * blur_size;

	vec4 sum = vec4(0.0);
	sum += texture(SCREEN_TEXTURE, uv);
	sum += texture(SCREEN_TEXTURE, uv + vec2(off.x, 0.0));
	sum += texture(SCREEN_TEXTURE, uv - vec2(off.x, 0.0));
	sum += texture(SCREEN_TEXTURE, uv + vec2(0.0, off.y));
	sum += texture(SCREEN_TEXTURE, uv - vec2(0.0, off.y));
	sum += texture(SCREEN_TEXTURE, uv + off);
	sum += texture(SCREEN_TEXTURE, uv - off);
	sum += texture(SCREEN_TEXTURE, uv + vec2(off.x, -off.y));
	sum += texture(SCREEN_TEXTURE, uv + vec2(-off.x, off.y));

	COLOR = sum / 9.0;
}
