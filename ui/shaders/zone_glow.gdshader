shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.6, 0.6, 0.6, 0.8);
uniform float glow_intensity : hint_range(0.0, 5.0) = 0.6;
uniform float glow_radius : hint_range(0.0, 2.0) = 0.5;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.15;
uniform bool active = false;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    
    // Pulse animation
    float pulse = 1.0 + pulse_intensity * sin(TIME * pulse_speed);
    
    // Calculate glow based on distance from center
    float glow = 1.0 - smoothstep(0.0, glow_radius * pulse, dist);
    glow = pow(glow, 2.0);
    
    // Border highlight
    float border = smoothstep(0.45, 0.5, dist) * (1.0 - smoothstep(0.5, 0.55, dist));
    
    // Нейтральный glow без цветового кодирования
    vec4 final_color = glow_color;
    
    // Combine glow with border
    float alpha = glow * glow_intensity;
    if (active) {
        alpha = mix(alpha * 0.5, alpha, pulse);
        alpha += border * 0.8;
    }
    
    COLOR = vec4(final_color.rgb, alpha * final_color.a);
}
