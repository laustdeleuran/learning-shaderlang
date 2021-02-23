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

void mainImage(out vec4, in vec2);
void main(void) { mainImage(fragColor,inData.v_texcoord * iResolution.xy); }

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#define PI 3.14159265359
#define e 2.7182818


/**
 * Rotate coordinate system from the center by angle
 * @src https://thebookofshaders.com/08/
 * @param coordinates {vec2}
 * @param angle {float} - angle in radians (360 degrees = 2 * PI)
 * @return {vec2}
 */
vec2 rotate2d(vec2 coordinate, float angle){
    coordinate = mat2(
        cos(angle),
        -sin(angle),
        sin(angle),
        cos(angle)
    ) * coordinate; // Rotate coordinate
    return coordinate;
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
        v += a * snoise(_st);
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
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
 * Pseudo-random based on sine with float input
 * @src https://thebookofshaders.com/10/
 * @param seed {float}
 * @return {float}
 */
float random(float seed) {
    return fract(sin(seed)*1e4);
}

/**
 * Distance field circle
 * @src https://thebookofshaders.com/07/
 * @param coordinate {vec2} - normalized (0-1, 0-1) coordinate
 * @param radius {float} - radius
 * @return {float} distance
 */
float circle(in vec2 coordinate, in vec2 center, in float radius, in float edge) {
    float dist = length(coordinate - center) / radius;
    return dist;
}

float circle(in vec2 uv, in vec2 center, in float radius) {
    return circle(uv, center, radius, 1./iResolution.x);
}

/** 
 * Got a Cleu?
 * @param coordinate {vec2} - normalized (0-1, 0-1) coordinate
 * @param radius {float} - radius
 */
vec2 cleu(in vec2 uv, in vec2 center, in float radius, in float count, in float part) {
    float i = 0;
    float d = 1.;
    
    // Create outer circle (A)
    float dist = circle(uv, center, radius);
    if (dist < 1.) {
        d = 1. - dist;
        i++;
    
        for (float t = 0.; t < count / 2.; t++) {
            if (i >= count) break;
            // Create big inner circle (B)
            center.y -= radius;
            radius = radius * (1. - part);
            center.y += radius;
        
            float distB = circle(uv, center, radius);
            
            if (distB < 1.) {
                i++;
                d = 1. - distB;
            };
            if (i >= count - 1.) break;
            
            // Create small inner circle (C)
            center.y += radius;
            radius = radius * (1. + part / (1. - part)) * part;
            center.y += radius;
            
            float distC = circle(uv, center, radius);
            
            if (distC < 1.) {
                i += 2.;
                d = 1. - distC;
            };
        }
    }
    
    
    return vec2(i, d);
}

/** 
 * @main
 */
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
    uv *= map(sin(iTime * 0.5), -1., 1., 1., 0.9);
    
    vec2 cl = cleu(uv, vec2(0.), 0.38, 4., 1./e);
    
    float pixelNoise = snoise(uv * 300.);
    
    vec3 bg = hsb2rgb(vec3(
        0., 
        0.,
        0.175 * (circle(uv, vec2(0.), 0.75)) + pixelNoise * 0.025 
    ));

    vec2 r = vec2(0.);
    r.x = fbm(uv + random(cl.x) + 0.10, 1);

    float f = fbm(uv + r, 10);
    f = f * 0.5 + fbm(vec2(f * 0.5) + iTime * 0.05, 2);
    f = f * 0.5 + fbm(vec2(f * 0.25) + -iTime * 0.05, 2);
    
    vec3 color = vec3(f);
    
    color = hsb2rgb(vec3(
        color.x * 0.75 + cl.y * 0.25,
        min(color.y, 1.) - (1. - cl.y) * 0.25,
        min(color.z, 1.) * 1.6 + pixelNoise * 0.125
    ));
    
    if (cl.x == 0. && cl.y == 1.) color = bg * 0.85 + color * 0.15;
    
    fragColor = vec4(color, 1.);
}