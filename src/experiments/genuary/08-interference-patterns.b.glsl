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
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iMouse;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform vec4 iDate;
uniform float iSampleRate;

void mainImage(out vec4, in vec2);
void main(void) { mainImage(fragColor,inData.v_texcoord * iResolution.xy); }

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/**
 * Constants
 */
#define PI 3.14159265359

#define CIRCLES 4

/**
 * Pseudo-random based on sine with float input
 * @src https://thebookofshaders.com/10/
 * @param seed {float}
 * @return {float}
 */
float random(float seed) {
    return fract(sin(seed)*1e4);
}

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
 * Get color hues
 */
float getHues(in vec2 point, in vec3[CIRCLES] c) {
    float hue;

    float[CIRCLES] hues;
    for (int i = 0; i < CIRCLES; i++) {
        float r = random(float(i));
        hues[i] = (0.25 + r * 0.75) + 0.125 * cos(iTime * (0.05 + r * 0.05));
    }
    
    for (int i = 0; i < CIRCLES; i++) {
        if (i == 0) hue = hues[i];
        else {
            float distA = distance(point, c[i - 1].xy);
            float distB = distance(point, c[i].xy);
            
            float dist;
            dist = distA / (distB + distA);
            hue = mix(hue, hues[i], dist);
        }
    }
    
    return hue;
}

/**
 * Get circle centers, xy is center point, z is distance field
 */
vec3[CIRCLES] circles(in vec2 point) {
    vec3[CIRCLES] centers; 
    for (int i = 0; i < CIRCLES; i++) {
        float t = float(i);
        float rand = random(t);
        vec2 center = vec2(
            snoise(vec2(20., 2000. * t) + vec2(0.25, 2.5) * iTime * (.008 + rand * 0.025)),
            snoise(vec2(2000. * t, 20.) + vec2(1.75, 0.5) * iTime * (.0015 + rand * 0.025))
        );
        centers[i] = vec3(
            center, 
            sdCircle(point, center, 0.375 * rand + (0.25 + rand * 0.125) * sin(iTime * (0.025 + 0.0125 * rand)))
        );
    }
    return centers;
}

/**
 * @main
 */
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec3[CIRCLES] c = circles(uv);
    float dist = 0.;
    for (int i = 0; i < CIRCLES; i++) {
        dist += fract(c[i].z);
    }
    if (CIRCLES > 2) dist /= float(CIRCLES - 1);
    
    float pattern = smoothstep(0.2, 0.9, dist);
    float pixelNoise = snoise(uv * 300.);
    
    float hue = getHues(uv, c);
    fragColor = vec4(hsb2rgb(vec3(
        hue + pattern * .15,
        0.5,
        1. - pixelNoise * 0.05
    )), 1.0);
}