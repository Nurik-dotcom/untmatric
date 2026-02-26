shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform vec4 tint_color : source_color = vec4(0.93, 0.93, 0.93, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.15;
uniform int fx_quality : hint_range(0, 2) = 1;
uniform float jitter_strength : hint_range(0.0, 1.0) = 0.0;
uniform float glitch_strength : hint_range(0.0, 2.0) = 0.0;
uniform float pulse : hint_range(0.0, 3.0) = 0.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.4;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.08;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Enhanced vignette with oval shape
    vec2 vignette_uv = uv * (1.0 - uv.yx);
    float vig = vignette_uv.x * vignette_uv.y * 15.0;
    vig = pow(vig, vignette_strength * 0.4);
    vig = clamp(vig, 0.0, 1.0);
    vig = 1.0 - vig;
    
    // Animated scanlines with depth
    float scan = 0.5 + 0.5 * sin((uv.y * 1080.0) + TIME * 8.0);
    scan = mix(0.85, 1.0, scan * scanline_strength);
    
    // Chromatic aberration on glitch
    float aberration = glitch_strength * 0.015;
    vec2 sample_uv = uv;
    
    if (fx_quality > 0) {
        // Jitter effect
        float jitter = (random(vec2(TIME * 0.1, uv.y * 100.0)) - 0.5) * 0.01;
        sample_uv.x += jitter * jitter_strength;
        
        // Glitch bands
        float glitch_band = sin(TIME * 20.0 + uv.y * 50.0) * glitch_strength * 0.02;
        sample_uv.x += glitch_band;
    }
    
    // RGB split for high glitch
    vec3 src;
    if (glitch_strength > 0.5 && fx_quality > 1) {
        float shift = aberration * (sin(TIME * 10.0 + uv.y * 30.0) + 1.0) * 0.5;
        src.r = texture(screen_tex, sample_uv + vec2(shift, 0.0)).r;
        src.g = texture(screen_tex, sample_uv).g;
        src.b = texture(screen_tex, sample_uv - vec2(shift, 0.0)).b;
    } else {
        src = texture(screen_tex, sample_uv).rgb;
    }
    
    // Film noise
    float noise = random(uv + TIME * 0.01) * noise_strength;
    src += noise - (noise_strength * 0.5);
    
    // Pulse breathing effect
    float pulse_wave = 1.0 + (sin(TIME * 3.0) * 0.05 * pulse);
    
    // Combine effects
    float overlay = intensity * scan * vig * pulse_wave;
    vec3 tint = mix(src, tint_color.rgb, overlay);
    
    // Final color with vignette darkening
    tint *= (0.85 + 0.15 * (1.0 - vig * 0.7));
    
    COLOR = vec4(tint, overlay);
}
