#version 300 es
// Screen-wide dot matrix for Hyprland compositor.
// Same algorithm as dots.frag but rewritten for Hyprland's shader pipeline
// (v_texcoord / tex / time uniforms instead of Qt SceneGraph uniforms).

precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;
uniform float time;

// Grid density. Higher = more dots. Approximate 8px pitch at 1080p.
#define GRID_COLS 240.0
#define GRID_ROWS 135.0

void main() {
    vec2 grid = vec2(GRID_COLS, GRID_ROWS);
    vec2 cell_center = (floor(v_texcoord * grid) + 0.5) / grid;

    vec2 diff = (v_texcoord - cell_center) * grid;
    float dist = length(diff);

    float r = 0.3;
    float mask = 1.0 - smoothstep(r * 0.85, r * 1.15, dist);

    vec4 col = texture(tex, cell_center);
    fragColor = vec4(col.rgb * mask, 1.0);
}
