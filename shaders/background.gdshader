shader_type canvas_item;

uniform float blur_size : hint_range(0.0, 8.0) = 3.0;

void fragment() {
    // Convert integer texture size to vec2(float)
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 pixel = 1.0 / tex_size;

    vec4 col = vec4(0.0);
    float total = 0.0;

    // Sample in a 9-tap blur pattern
    for (float x = -4.0; x <= 4.0; x++) {
        for (float y = -4.0; y <= 4.0; y++) {
            float weight = exp(-(x*x + y*y) / (2.0 * blur_size * blur_size));
            col += texture(TEXTURE, UV + vec2(x, y) * pixel) * weight;
            total += weight;
        }
    }

    col /= total;   // normalize
    COLOR = col;
}