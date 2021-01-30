#version 150

in VertexData
{
    vec4 v_position;
    vec3 v_normal;
    vec2 v_texcoord;
} inData;

out vec4 fragColor;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D video1;

void mainImage(out vec4, in vec2);
void main(void) { mainImage(fragColor,inData.v_texcoord * iResolution.xy); }

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#define PI 3.14159265359

/**
 * Utils
 */
vec2 random(vec2 p) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

/** 
 * Noise
 * @src https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83#perlin-noise
 */
 
// Noise: Random
float rand(vec2 c){
    return fract(sin(dot(c.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// Noise: Basic noise
float noise(vec2 p, float freq){
    float unit = iResolution.x / freq;
    vec2 ij = floor(p / unit);
    vec2 xy = .5 * (1. - cos(PI * mod(p, unit) / unit));
    float a = rand((ij + vec2(0., 0.)));
    float b = rand((ij + vec2(1., 0.)));
    float c = rand((ij + vec2(0., 1.)));
    float d = rand((ij + vec2(1., 1.)));
    float x1 = mix(a,b,xy.x);
    float x2 = mix(c,d,xy.x);
    return mix(x1,x2,xy.y);
}

/**
 * Fractional Brownian Motion
 * @src https://thebookofshaders.com/13/
 */
float fbm(in vec2 _st, in int octaves) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for (int i = 0; i < octaves; ++i) {
        v += a * noise(_st, 2000. + abs(1000. * sin(iTime * 0.0009)));
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

/**
 * RGB to HSB
 * All components are in the range [0…1], including hue.
 * @src https://stackoverflow.com/a/17897228
 */
vec3 rgb2hsb(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
 
/**
 * HSB to RGB
 * All components are in the range [0…1], including hue.
 * @src https://stackoverflow.com/a/17897228
 */
vec3 hsb2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

/**
 * Voronoi cells
 * @src https://thebookofshaders.com/12/
 */
float voronoi(vec2 st, float scale) {
    // Scale
    st *= 3.;

    // Tile the space
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);

    float m_dist = 1.;  // minimum distance

    for (int y= -1; y <= 1; y++) {
        for (int x= -1; x <= 1; x++) {
            // Neighbor place in the grid
            vec2 neighbor = vec2(float(x),float(y));

            // Random position from current + neighbor place in the grid
            vec2 point = random(i_st + neighbor);

            // Animate the point
            point = 0.5 + 0.5*sin(iTime + 6.2831*point);

            // Vector between the pixel and the point
            vec2 diff = neighbor + point - f_st;

            // Distance to the point
            float dist = length(diff);

            // Keep the closer distance
            m_dist = min(m_dist, dist);
        }
    }
    
    return m_dist;
}

/**
 * @main
 * Genuary 03 - Something human
 */
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy/iResolution.xy;
    uv.x *= iResolution.x/iResolution.y;
    
    // Get video input
    uv.y = 1. - uv.y;; // Flip video input
    vec3 color = texture(video1, uv).rgb;

    // Distance field using Voronoi
    float m_dist = voronoi(uv, 10.);

    // Mess with colors with fbm
    vec2 r = vec2(0.);
    r.x = fbm(uv  + 0.10, 1);

    float f = fbm(uv + r, 10);
    f = f* 0.5 + fbm(vec2(f *0.5), 2);
    f = f* 0.5 + fbm(vec2(f *0.5), 2);

    color = rgb2hsb(color); // Ah, HSB is so much easier to work with
    color.x += m_dist * f * f;
    color = hsb2rgb(color);
    

    // Output
    fragColor = vec4((f*f*f+.3*f*f+.8*f)*color,1.0);
}


