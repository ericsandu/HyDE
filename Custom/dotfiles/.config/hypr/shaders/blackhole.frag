// !damage_tracking = 0
#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;
out vec4 FragColor;

// Configuration
const vec2 center = vec2(0.5, 0.5); // Center of the screen (where the black hole is)
const float effect_radius = 0.15;   // How far out the gravitational pull affects the screen
const float aspect_ratio = 16.0 / 9.0; // Standard widescreen aspect ratio

void main() {
    vec2 uv = v_texcoord;
    vec2 pos = uv - center;
    
    // Correct for aspect ratio so the swirl is perfectly circular, not an oval
    pos.x *= aspect_ratio;
    
    float dist = length(pos);
    
    // Only apply the gravitational lensing/swirl within the effect radius
    if (dist < effect_radius) {
        // Smooth falloff: the effect gradually fades out to 0 at the effect_radius
        float falloff = smoothstep(effect_radius, 0.05, dist);
        
        // Swirl speed: spins significantly faster the closer you get to the event horizon (dist ~ 0)
        float speed = 1.0 / (dist + 0.05); 
        
        // Calculate the rotational angle over time
        float angle = time * 0.15 * speed * falloff;
        
        float s = sin(angle);
        float c = cos(angle);
        
        // Apply 2D rotation matrix
        pos = vec2(pos.x * c - pos.y * s, pos.x * s + pos.y * c);
    }
    
    // Restore aspect ratio and move back to original coordinates
    pos.x /= aspect_ratio;
    uv = pos + center;
    
    // Sample the screen at the newly warped coordinate
    FragColor = texture(tex, uv);
}
