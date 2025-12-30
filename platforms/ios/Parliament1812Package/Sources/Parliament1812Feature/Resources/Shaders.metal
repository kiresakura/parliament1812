#include <metal_stdlib>
using namespace metal;

// Metallic Sheen Shader
// sweeping light effect across the surface
// time: current time in seconds
// size: size of the view
[[ stitchable ]] half4 metallicSheen(float2 position, half4 color, float time, float2 size) {
    // Calculate a sweep based on time and position
    // The sweep moves diagonally
    float speed = 2.0;
    float width = 0.2; // Width of the sheen line relative to size
    
    // Normalize position
    float2 uv = position / size;
    
    // Create a moving line: y = x + offset(time)
    // We want the line to repeat every few seconds
    float cycle = fmod(time * speed, 4.0); // 4 second cycle (2s move, 2s pause)
    float offset = cycle - 1.0; // Start off screen
    
    // Distance from the diagonal line
    float dist = abs(uv.x + uv.y - offset);
    
    // Calculate intensity if within the sheen width
    float intensity = 0.0;
    if (dist < width) {
        // Smooth falloff
        intensity = 1.0 - smoothstep(0.0, width, dist);
        // Make it sharp in the middle
        intensity = pow(intensity, 3.0);
    }
    
    // Add the sheen to the original color
    // We brighten the pixel based on intensity
    return color + half4(1.0, 0.9, 0.6, 0.0) * half(intensity * 0.4);
}

// Fog of War Shader
// animated cloudy noise
[[ stitchable ]] half4 fogOfWar(float2 position, half4 color, float time, float2 size) {
    // Simple noise-based fog would go here
    // For now, we'll just do a pulsating gray overlay
    // ideally requires noise texture or function
    
    float2 uv = position / size;
    float pulse = sin(time + uv.x * 5.0 + uv.y * 3.0) * 0.1;
    
    half4 fogColor = half4(0.2, 0.2, 0.2, 0.8 + pulse);
    
    // Blend fog over content
    return mix(color, fogColor, half(0.9));
}
