shader_type spatial;
render_mode unshaded, cull_front; // culls front faces to show back

uniform float outline_width = 1.4;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D texture_albedo;

void vertex() {
    // Grow the vertex along the normal
    VERTEX += NORMAL * outline_width;
}

void fragment() {
    // Sample original texture to keep transparency
    vec4 albedo_tex = texture(texture_albedo, UV);
    
    // Set color and make sure alpha matches
    ALBEDO = outline_color.rgb;
    ALPHA = albedo_tex.a; // Outline follows base texture alpha
}
