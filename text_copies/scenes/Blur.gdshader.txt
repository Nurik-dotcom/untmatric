shader_type canvas_item;

uniform float lod: hint_range(0.0, 5.0) = 0.0;
uniform vec4 modulate: source_color = vec4(0.0, 0.0, 0.0, 0.8);

void fragment() {
	vec4 color = texture(TEXTURE, UV, lod);
	COLOR = color * modulate;
}
