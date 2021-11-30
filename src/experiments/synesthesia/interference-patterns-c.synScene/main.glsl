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
vec3 permute(vec3 x) { 
	return mod(((x*34.0)+1.0)*x, 289.0); 
}

float snoise(vec2 v){
	const vec4 C = vec4(
		.211324865405187, 
		.366025403784439,
		-.577350269189626, 
		.024390243902439
	);
	vec2 i  = floor(v + dot(v, C.yy) );
	vec2 x0 = v -   i + dot(i, C.xx);
	vec2 i1;
	i1 = (x0.x > x0.y) ? vec2(1., .0) : vec2(.0, 1.);
	vec4 x12 = x0.xyxy + C.xxzz;
	x12.xy -= i1;
	i = mod(i, 289.0);
	vec3 p = permute( permute( i.y + vec3(.0, i1.y, 1. ))
	+ i.x + vec3(.0, i1.x, 1. ));
	vec3 m = max(.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
	  dot(x12.zw,x12.zw)), 0.);
	m = m*m ;
	m = m*m ;
	vec3 x = 2.0 * fract(p * C.www) - 1.0;
	vec3 h = abs(x) - .5;
	vec3 ox = floor(x + .5);
	vec3 a0 = x - ox;
	m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
	vec3 g;
	g.x  = a0.x  * x0.x  + h.x  * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return map(130. * dot(m, g), -1., 1., 0., 1.);
}

/** 
 * Circle distance function
 * @src https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
 */
float sdCircle(in vec2 point, in vec2 center, in float radius) {
	return distance(point, center) / radius;
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
 * @main
 */
vec4 renderMain(void) {
	vec2 uv = _uv;
  uv.x *= (RENDERSIZE.x / RENDERSIZE.y);
	
	// Circle centers
	float centerTime = (script_bass_time * .05) + (TIME * .01);
	vec2 centerA = vec2(
		snoise(vec2(2.25, 2.5) * centerTime),
		snoise(vec2(3.25, .5) * centerTime)
	);
	vec2 centerB = vec2(
		snoise(vec2(20., 2000.) + vec2(0.25, 2.5) * centerTime),
		snoise(vec2(2000., 20.) + vec2(1.75, 0.5) * centerTime)
	);
	
	// Circles radii / interference
	float distA = sdCircle(uv, centerA, 0.025 + size_a * sin(TIME * 0.025) );
	float distB = sdCircle(uv, centerB, 0.025 + size_b * sin(TIME * 0.1));
	
	float pattern = smoothstep(.2, .9, fract(distA) + fract(distB));
	
	// Colors
	vec3 colorA = vec3(mix(color_a, sin(script_color_time) * syn_FadeInOut, .5), .5, .5);
	vec3 colorB = vec3(mix(color_b, sin(script_color_time) * syn_FadeInOut, .5), .5, .5);
	
	vec3 color = getColor(uv, centerA, centerB, colorA, colorB);
	
	// Noise
	float pixelNoise = snoise(uv * 300.);
	
	// Combine
	return vec4(_hsv2rgb(vec3(
		color.x + pattern * .15,
		color.y,
		1. - pixelNoise * .05
	)), 1.0);
}