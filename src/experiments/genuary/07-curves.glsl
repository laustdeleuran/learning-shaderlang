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
uniform vec4 iMouse;

void mainImage(out vec4, in vec2);
void main(void) { mainImage(fragColor,inData.v_texcoord * iResolution.xy); }

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#define PI 3.14159265359

/**
 * Utils
 */
float dot2( in vec2 v ) { return dot(v,v); }
float cross2( in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }

/**
 * Parabola
 * @src https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
 */
float sdParabola(in vec2 pos, in float wi, in float he) {
    pos.x = abs(pos.x);

    float ik = wi*wi/he;
    float p = ik*(he-pos.y-0.5*ik)/3.0;
    float q = pos.x*ik*ik*0.25;
    
    float h = q*q - p*p*p;
    float r = sqrt(abs(h));

    float x = (h>0.0) ? 
        // 1 root
        pow(q+r,1.0/3.0) - pow(abs(q-r),1.0/3.0)*sign(r-q) :
        // 3 roots
        2.0*cos(atan(r/q)/3.0)*sqrt(p);
    
    x = min(x,wi);
    
    return length(pos-vec2(x,he-x*x/ik)) * 
           sign(ik*(pos.y-he)+pos.x*pos.x);
}

/**
 * Bezier curve
 * @src
 */
float sdBezier( in vec2 pos, in vec2 A, in vec2 B, in vec2 C )
{    
    vec2 a = B - A;
    vec2 b = A - 2.0*B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;
    float kk = 1.0/dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b)) / 3.0;
    float kz = kk * dot(d,a);      
    float res = 0.0;
    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx-3.0*ky) + kz;
    float h = q*q + 4.0*p3;
    if(h >= 0.0) { 
        h = sqrt(h);
        vec2 x = (vec2(h,-h)-q)/2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = clamp( uv.x+uv.y-kx, 0.0, 1.0 );
        res = dot2(d + (c + b*t)*t);
    } else {
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3  t = clamp(vec3(m+m,-n-m,n-m)*z-kx,0.0,1.0);
        res = min( dot2(d+(c+b*t.x)*t.x),
                   dot2(d+(c+b*t.y)*t.y) );
        // the third root cannot be the closest
        // res = min(res,dot2(d+(c+b*t.z)*t.z));
    }
    return sqrt(res);
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
 * Noise
 * @src https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83#perlin-noise
 */
 
// Noise: Random
float rand(vec2 c){
    return fract(sin(dot(c.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 rand2(vec2 p) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
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
* HSB to RGB
* All components are in the range [0…1], including hue.
* @src https://stackoverflow.com/a/17897228
*/
vec3 hsb2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


vec3 drawCurve(vec2 uv, vec3 seed, vec3 bgColor, vec3 color) {
    vec2 v0 = rand2(vec2(seed.x));
    vec2 v1 = rand2(vec2(seed.y));
    vec2 v2 = rand2(vec2(seed.z));
    
    float d = sdBezier(uv, v0, v1, v2); 
    
    return step(0.005, abs(d)) == 0. ? color : bgColor;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    
    vec3 bgColor = vec3(0., 0., 0.1);
    vec3 color = bgColor;
    
    for (int i = 0; i < 300; i++) {
        color = drawCurve(
            uv, 
            vec3(random(i * .000001), random(i * .00003), random(i * .000002)), 
            color, 
            vec3(0. + random(i) * 0.2, 0.9, 0.8)
        );
    }
    
    
    fragColor = vec4(hsb2rgb(color), 0.5);
}