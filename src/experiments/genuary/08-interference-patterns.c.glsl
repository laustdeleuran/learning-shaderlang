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
uniform sampler2D midi1;
uniform float iSampleRate;

void mainImage(out vec4, in vec2);
void main(void) { mainImage(fragColor,inData.v_texcoord * iResolution.xy); }

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#define PI 3.14159265359

#define CIRCLES 2

/**
 * Map range to new range
 */
float map(float value, float min1, float max1, float min2, float max2) {
    return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

/**
 * Simplex noise
 * @src https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83#simplex-noise
 */
vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v){
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
           -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod(i, 289.0);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
  + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return map(130.0 * dot(m, g), -1., 1., 0., 1.);
}

/** 
 * Circle distance function
 * @src https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
 */
float sdCircle(in vec2 point, in vec2 center, in float radius) {
    return distance(point, center) / radius;
}
 
/**
 * HSB to RGB
 * All components are in the range [0…1], including hue.
 * @src https://stackoverflow.com/a/17897228
 */
vec3 hsb2rgb(in vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

/** 
 * Get color
 */
vec3 getColor(in vec2 point, in vec2 centerA, in vec2 centerB, in vec3 colorA, in vec3 colorB) {
    float distA = distance(point, centerA);
    float distB = distance(point, centerB);
    
    float dist;
    dist = distA / (distB + distA);
    return mix(colorA, colorB, dist);
}

/**
 * LPD8
 */
const vec2 LPD8_K1 = vec2(30, 11);
const vec2 LPD8_K2 = vec2(31, 11);
const vec2 LPD8_K3 = vec2(0, 12);
const vec2 LPD8_K4 = vec2(1, 12);
const vec2 LPD8_K5 = vec2(2, 12);
const vec2 LPD8_K6 = vec2(3, 12);
const vec2 LPD8_K7 = vec2(4, 12);
const vec2 LPD8_K8 = vec2(5, 12);

const vec2 LPD8_P1A = vec2(3, 5);
const vec2 LPD8_P2A = vec2(4, 5);
const vec2 LPD8_P3A = vec2(5, 5);
const vec2 LPD8_P4A = vec2(6, 5);
const vec2 LPD8_P5A = vec2(7, 5);
const vec2 LPD8_P6A = vec2(8, 5);
const vec2 LPD8_P7A = vec2(9, 5);
const vec2 LPD8_P8A = vec2(10, 5);

const vec2 LPD8_P1B = vec2(11, 5);
const vec2 LPD8_P2B = vec2(12, 5);
const vec2 LPD8_P3B = vec2(13, 5);
const vec2 LPD8_P4B = vec2(14, 5);
const vec2 LPD8_P5B = vec2(15, 5);
const vec2 LPD8_P6B = vec2(16, 5);
const vec2 LPD8_P7B = vec2(17, 5);
const vec2 LPD8_P8B = vec2(18, 5);

float getLPD8Value(vec2 coord) {
    return texture(midi1, coord / 32.).x;
}

/**
 * @main
 */
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;    
    
    // Circle centers
    vec2 centerA = vec2(
        snoise(vec2(2.25, 2.5) * iTime * .005),
        snoise(vec2(3.25, 0.5) * iTime * .0010)
    );
    vec2 centerB = vec2(
        snoise(vec2(20., 2000.) + vec2(0.25, 2.5) * iTime * .008),
        snoise(vec2(2000., 20.) + vec2(1.75, 0.5) * iTime * .0015)
    );
    
    // Circles radii / interference
    float k1 = getLPD8Value(LPD8_K1);
    float k2 = getLPD8Value(LPD8_K2);
    
    float distA = sdCircle(uv, centerA, 0.025 + k1 * sin(iTime * 0.025) );
    float distB = sdCircle(uv, centerB, 0.025 + k2 * sin(iTime * 0.1));
    
    float pattern = smoothstep(0.2, 0.9, fract(distA) + fract(distB));
    
    // Colors
    float k5 = getLPD8Value(LPD8_K5);
    float k6 = getLPD8Value(LPD8_K6);
    
    vec3 colorA = vec3(k5, 0.5, 0.5);
    vec3 colorB = vec3(k6, 0.5, 0.5);
    
    vec3 color = getColor(uv, centerA, centerB, colorA, colorB);
    
    // Noise
    float pixelNoise = snoise(uv * 300.);
    
    // Combine
    fragColor = vec4(hsb2rgb(vec3(
        color.x + pattern * .15,
        color.y,
        1. - pixelNoise * 0.05
    )), 1.0);
}