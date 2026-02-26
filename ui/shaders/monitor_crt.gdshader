shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform vec4 tint_color : source_color = vec4(0.05, 0.08, 0.12, 1.0);
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float scanline_count : hint_range(100.0, 800.0) = 300.0;
uniform float curvature : hint_range(0.0, 0.1) = 0.02;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.5;
uniform float noise_intensity : hint_range(0.0, 0.5) = 0.03;
uniform float flicker_speed : hint_range(0.0, 10.0) = 5.0;
uniform float flicker_intensity : hint_range(0.0, 0.1) = 0.02;
uniform bool powered_on = true;
uniform float power_on_progress : hint_range(0.0, 1.0) = 1.0;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    vec4 final_color = vec4(0.0, 0.0, 0.0, 1.0);
    
    // Screen curvature effect
    vec2 curved_uv = uv;
    curved_uv.x -= 0.5;
    curved_uv.x *= 1.0 + (uv.y - 0.5) * (uv.y - 0.5) * curvature * 2.0;
    curved_uv.x += 0.5;
    
    // Check if pixel is inside curved screen
    bool inside_screen = curved_uv.x >= 0.0 && curved_uv.x <= 1.0 && curved_uv.y >= 0.0 && curved_uv.y <= 1.0;
    
    if (inside_screen) {
        vec2 screen_uv = curved_uv;
        
        // Power on/off effect
        float scan_progress = powered_on ? power_on_progress : (1.0 - power_on_progress);
        float scanline_mask = step(1.0 - screen_uv.y, scan_progress);
        
        if (scanline_mask >= 0.5) {
            // Sample the screen texture
            vec3 color = texture(screen_tex, screen_uv).rgb;
            
            // Scanlines
            float scanline = sin(screen_uv.y * scanline_count * 3.14159);
            scanline = (scanline * 0.5 + 0.5) * scanline_intensity + (1.0 - scanline_intensity);
            
            // RGB strip effect (simulating CRT phosphors)
            float rgb_shift = 0.002;
            float r = texture(screen_tex, screen_uv + vec2(rgb_shift, 0.0)).r;
            float g = texture(screen_tex, screen_uv).g;
            float b = texture(screen_tex, screen_uv - vec2(rgb_shift, 0.0)).b;
            color = vec3(r, g, b);
            
            // Apply scanlines
            color *= scanline;
            
            // Vignette
            vec2 vig_uv = screen_uv * (1.0 - screen_uv.yx);
            float vignette = vig_uv.x * vig_uv.y * 15.0;
            vignette = pow(vignette, vignette_strength * 0.5);
            color *= vignette;
            
            // Film noise
            float noise = random(screen_uv + vec2(TIME * 0.1, TIME * 0.05));
            color += (noise - 0.5) * noise_intensity;
            
            // Screen flicker
            float flicker = 1.0 + sin(TIME * flicker_speed) * flicker_intensity;
            color *= flicker;
            
            // Apply tint
            color = mix(color, tint_color.rgb, 0.15);
            
            // Slight brightness variation at edges
            float edge_darkening = 1.0 - abs(screen_uv.x - 0.5) * 0.1;
            color *= edge_darkening;
            
            final_color = vec4(color, 1.0);
        }
    }
    
    COLOR = final_color;
}
