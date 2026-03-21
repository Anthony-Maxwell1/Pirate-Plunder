shader_type spatial;

// --- HEIGHT CONTROLS ---
uniform float min_height = -3.0;   // lowest trough
uniform float max_height =  3.0;   // highest crest
uniform float height_weight = 1.0; // overall multiplier (0 = flat, 2 = double)

uniform float time_scale = 0.5;
uniform float choppiness = 0.5;

varying float v_height;
varying vec3 v_world_pos;

float dwave(vec2 p, float freq, float speed, float amp, vec2 dir) {
    float t = TIME * speed * time_scale;
    return sin(dot(p, dir) * freq + t) * amp;
}

float ocean_height(vec2 p) {
    float w0 = dwave(p, 0.11, 1.0,  1.0, vec2( 0.72,  0.69));
    float w1 = dwave(p, 0.19, 1.4,  0.7, vec2(-0.55,  0.83));
    float w2 = dwave(p, 0.28, 0.8,  0.5, vec2( 0.88, -0.47));
    float w3 = dwave(p, 0.38, 1.9,  0.35, vec2(-0.38, -0.92));

    vec2 warped = p + vec2(w0 + w1, w2 + w3) * choppiness;

    float w4 = dwave(warped, 0.14, 1.2,  0.9, vec2( 0.60, -0.80));
    float w5 = dwave(warped, 0.23, 0.7,  0.6, vec2(-0.82,  0.57));
    float w6 = dwave(warped, 0.42, 2.1,  0.3, vec2( 0.45,  0.89));

    vec2 warped2 = warped + vec2(w4, w5) * choppiness * 0.6;

    float w7 = dwave(warped2, 0.18, 1.6, 0.55, vec2(-0.66, -0.75));
    float w8 = dwave(warped2, 0.33, 0.9, 0.35, vec2( 0.91,  0.41));

    // Raw sum is in roughly [-1, 1] range before scaling
    float raw = (w0+w1+w2+w3+w4+w5+w6+w7+w8) * 0.28;

    // Remap [-1, 1] → [min_height, max_height], then apply weight
    float mid = (min_height + max_height) * 0.5;
    float half_range = (max_height - min_height) * 0.5;
    return mid + raw * half_range * height_weight;
}

void vertex() {
    vec3 pos = VERTEX;
    vec2 p = pos.xz;
    pos.y += ocean_height(p);
    VERTEX = pos;
    v_height = pos.y;
    v_world_pos = (MODEL_MATRIX * vec4(pos, 1.0)).xyz;
}

void fragment() {
    float h = v_height;

    vec2 p = v_world_pos.xz;
    float eps = 0.3;
    float hx = ocean_height(p + vec2(eps, 0.0));
    float hy = ocean_height(p + vec2(0.0, eps));
    float curvature = abs(hx - h) + abs(hy - h);
    float foam_curv = smoothstep(0.06, 0.20, curvature);
    float foam_peak = smoothstep(0.55, 0.85, h / max_height);
    float foam = clamp(foam_curv * 0.8 + foam_peak, 0.0, 1.0);

    // Normalise h into [0,1] using the explicit range for colour bands
    float depth = clamp((h - min_height) / (max_height - min_height), 0.0, 1.0);
    depth = floor(depth * 5.0) / 5.0;

    vec3 deep    = vec3(0.04, 0.18, 0.30);
    vec3 mid     = vec3(0.10, 0.38, 0.48);
    vec3 shallow = vec3(0.28, 0.62, 0.60);
    vec3 color = mix(deep, mid,     smoothstep(0.0, 0.55, depth));
    color      = mix(color, shallow, smoothstep(0.45, 1.0, depth));

    vec3 foam_col = vec3(0.90, 0.94, 0.96);
    color = mix(color, foam_col, foam * 0.75);

    ALBEDO = color;
    ROUGHNESS = mix(0.08, 0.4, foam);
    METALLIC = 0.0;
}

void light() {
    float NdotL = dot(NORMAL, LIGHT);
    NdotL = floor(NdotL * 4.0) / 4.0;
    float intensity = max(NdotL, 0.15);
    DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * intensity;

    float foam_mask = smoothstep(0.4, 0.8, v_height / max_height);
    float spec = pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 32.0);
    SPECULAR_LIGHT += LIGHT_COLOR * spec * (1.0 - foam_mask * 0.6) * 0.4;
}