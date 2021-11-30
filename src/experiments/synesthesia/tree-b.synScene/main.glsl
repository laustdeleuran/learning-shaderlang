#define PI 3.14159265359

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
	float unit = RENDERSIZE.x / freq;
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
		v += a * noise(_st, 2000. + abs(1000. * sin(TIME * 0.009)));
		_st = rot * _st * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

/**
 * Fractal, aka. black magic
 * @src https://www.shadertoy.com/view/Xdy3RK
 * @author Passion, 2016
 */
// 2D Rotation
mat2 rotate2d(float deg){    
	return mat2(cos(deg),-sin(deg),
				sin(deg), cos(deg));
}
	
// The Fractal
vec2 fractal(vec2 uv, float time, int iterations) {    
	for(int i = 0; i < iterations; i++){
		uv = abs(uv) / dot(uv, uv);
		uv.x = abs(uv.x + cos(time * .6) * .5);
		uv.x = abs(uv.x - .8);
		uv = abs(rotate2d(-time * .3) * uv);
		uv.y = abs(uv.y - .5);
		uv.y = abs(uv.y + .03 +sin(time) * .25);
	}
	uv = abs(uv) / float(iterations);
	
	return uv;
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
 * Get color
 */
vec3 getColor(in vec2 point, in vec3 colorA, in vec3 colorB) {
	float dist = point.x / (point.x + point.y);
	return mix(colorA, colorB, dist);
}

/**
 * @main
 */
vec4 renderMain(void) {
	// Time
	float time = TIME * (time + 0.05);
	
	// Center uv coordinates
	vec2 uv = _uv;
	uv = uv * 2.0 - 1.0;
	uv.x *= RENDERSIZE.x / RENDERSIZE.y;
   
	// Rotation
	uv *= rotate2d(-time * (.1 + .5 * rotation));
	
	// Fractal
	float b1 = floor(syn_BassHits * 2);
	float b2 = floor(syn_BassPresence * 2);
	float b3 = floor(syn_HighPresence * 2);
	uv = fractal(uv, time, int(1 + b1 + b2 + b3));
	
	
	vec3 color = getColor(uv, vec3(color_a, color_b, brightness), vec3(color_c, color_d, uv.y));
	
	
	// Noise
	float pixelNoise = snoise(uv * 300.);
	
	return vec4(_hsv2rgb(vec3(
		color.x,
		color.y,
		color.z * 1.6 + pixelNoise * 0.1
	)), 1.);
}