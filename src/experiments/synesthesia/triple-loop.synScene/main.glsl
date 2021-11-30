
#define PI 3.14159265359

float map(float value, float min1, float max1, float min2, float max2) {
	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

float random (in vec2 _st) {
	return fract(sin(dot(_st.xy, vec2(12.9898,78.233))) * 43758.5453123);
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
float fbm ( in vec2 _st, in int octaves) {
	float time = syn_BPMTwitcher * 0.5;
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100.0);
	// Rotate to reduce axial bias
	mat2 rot = mat2(cos(0.5), sin(0.5),
					-sin(0.5), cos(0.50));
	for (int i = 0; i < octaves; ++i) {
		v += a * noise(_st, 2000. + abs(1000. * sin(mix(syn_BPMTwitcher * 0.009, TIME * 0.009, bpm_vs_time))));
		_st = rot * _st * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}
/** 
* Genuary 01
 * @main
 */
vec4 renderMain(void) {
	vec2 st = _uv;
	st.x *= (RENDERSIZE.x / RENDERSIZE.y);
	vec3 color = vec3(0.0);

	vec2 r = vec2(0.);
	r.x = fbm(st  + 0.10, 1);

	float f = fbm(st+r, 10);
	f = f* 0.5 + fbm(vec2(f *0.5), 2);
	f = f* 0.5 + fbm(vec2(f *0.5), 2);
	
	float t = smoothstep(0., 1., abs(map(fract(TIME * .075), 0., 1., -1., 1.)));

	color = _hsv2rgb(
		mix(vec3(1, 1, 1),
		mix(
			vec3(color_a, 0.725, 0.75 + 0.25 * sin(TIME * 0.1)),
			vec3(color_b, 0.625, 0.75 + 0.25 * sin(TIME * 0.1)),
			t * 0.5 + st.y * 0.5
		),
		clamp((f*f)*4.0,0.0,1.0))
	);


	return vec4((f*f*f+.3*f*f+.8*f)*color,1.);
}
