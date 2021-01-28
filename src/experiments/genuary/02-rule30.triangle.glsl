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
uniform sampler2D rule30map;

void mainImage(out vec4, in vec2);
void main(void) { mainImage(fragColor,inData.v_texcoord * iResolution.xy); }

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#define PI 3.14159265359

const vec2 s = vec2(1, .8660254);
const vec2 scale = vec2(2., 1.);
const vec2 rule30start = ivec2(500, 500);

/**
 * @overview
 * Big credits go to [*Shane*](https://www.shadertoy.com/user/Shane) 
 * and [*Andrew Hung*](https://andrewhungblog.wordpress.com/2018/07/28/shader-art-tutorial-hexagonal-grids/)
 * for explaining hex and triangle grids to me.
 */

/**
 * Hashed vector
 */
float hash21(vec2 p){ return fract(sin(dot(p, vec2(141.13, 289.97)))*43758.5453); }

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
float fbm ( in vec2 _st, in int octaves) {
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
 * Simple mapping from one range to another
 */
float map(float value, float min1, float max1, float min2, float max2) {
    return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

/**
 * Get triangle coordinates
 * Big kudos to *Shane* for writing super readable code. 
 * @src https://www.shadertoy.com/view/tsVSzG
 */
vec4 getTriangle(vec2 p, inout float itri) {
    
    // Scale coordinates down
    p /= s;
    
    // Offset alternate rows
    float ys = mod(floor(p.y), 2.) * .5;
    vec4 ipY = vec4(ys, 0, ys + .5, 0);
    
    // Two triangles pack into each square cell, and each triangle uses the bottom 
    // left point as it's unique identifier. The two points are stored here.
    vec4 ip4 = floor(p.xyxy + ipY) - ipY + .5; 
    
    // The local coordinates of the two triangles are stored here.
    vec4 p4 = fract(p.xyxy - ipY) - .5;
    
    // Which triangle are we in? 
    float i = (abs(p4.x) * 2. + p4.y < .5) ? 1. : -1.;
    itri = i;
    
    p4 = i > 0.? vec4(p4.xy * s, ip4.xy) : vec4(p4.zw * s, ip4.zw);  
    
    return p4;
}

/**
 * Get and blend colors. 
 * Credits to *Shane* for good blending techniques.
 * @src https://www.shadertoy.com/view/Xljczw
 */
vec4 getTriangleColor(vec2 st) {
    float itri;
    vec4 triangle = getTriangle(st, itri);
    
    vec3 v = texelFetch(rule30map, ivec2(triangle.zw * 53), 0).rgb;
    
    float rnd = hash21(triangle.zw);
    rnd = sin(rnd * 6.283 + iTime * 0.5) * .5 + .5; // Animating the random number.
    
    
    float blink = smoothstep(0., .125, rnd); // Smooth blinking transition.
    float blend = dot(sin(st * 3.14159 * 2. - cos(st.yx * 3.14159 * 2.) * 3.14159), vec2(.25)) + .1; // Screen blend.
    
    
    vec3 bg = vec3(0.994, 0.408, 0.6);
    
    vec3 colorA = v.r > 0.5 ? vec3(0.998, 0.545, 0.675) : vec3(0.755, 0.407, 0.82);
    vec3 colorB = v.r > 0.5 ? vec3(0.999, 0.578, 0.843) : vec3(0.719, 0.191, 1.0);
    
    vec3 col;
    float t = smoothstep(0., 1., abs(map(fract(iTime * .075), 0., 1., -1., 1.)));
    col = max(mix(bg, mix(colorA, colorB, t * 0.75 + st.y * 0.25), blink), 0.); 
    
    //return vec4(hue(triangle.x), 1.);
    return vec4(col, 1.);
}

/**
 * @main
 */
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 st = fragCoord / iResolution;
    st *= vec2(1., 1.) *  10.;
    
    fragColor = getTriangleColor(st);
}