#define PI 3.14159265359

/**
 * Utils
 */

// @src https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float dot2(in vec2 v) { return dot(v, v); }
float ndot(in vec2 a, in vec2 b) { return a.x * b.x - a.y*b.y; }

float random(in float seed) {
	return fract(sin(seed)*1e4);
}

float random(in vec2 seed) {
	return fract(sin(dot(seed.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec2 random2(vec2 seed) {
	return fract(sin(vec2(dot(seed, vec2(127.1, 311.7)), dot(seed, vec2(269.5, 183.3)))) * 43758.5453);
}

float map(in float value, in float min1, in float max1, in float min2, in float max2) {
	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

/**
 * Basic noise
 */
float noise(vec2 p, float freq){
	float unit = RENDERSIZE.x / freq;
	vec2 ij = floor(p / unit);
	vec2 xy = .5 * (1. - cos(PI * mod(p, unit) / unit));
	float a = random((ij + vec2(0., 0.)));
	float b = random((ij + vec2(1., 0.)));
	float c = random((ij + vec2(0., 1.)));
	float d = random((ij + vec2(1., 1.)));
	float x1 = mix(a,b,xy.x);
	float x2 = mix(c,d,xy.x);
	return mix(x1,x2,xy.y);
}

/**
 * Simplex noise
 * @src https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
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
	return 130.0 * dot(m, g);
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
		v += a * noise(_st, 2000. + abs(1000. * sin(TIME * 0.0009)));
		_st = rot * _st * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

/**
 * Triangle
 * @src https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
 */
float sdTriangle(in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2) {
	vec2 e0 = p1-p0, e1 = p2-p1, e2 = p0-p2;
	vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2;
	vec2 pq0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
	vec2 pq1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
	vec2 pq2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);
	float s = sign(e0.x * e2.y - e0.y * e2.x);
	vec2 d = min(
		min(
			vec2(dot(pq0, pq0), s * (v0.x * e0.y - v0.y * e0.x)),
			vec2(dot(pq1, pq1), s * (v1.x * e1.y - v1.y * e1.x))
		),
		vec2(dot(pq2, pq2), s * (v2.x * e2.y - v2.y * e2.x))
	);
	
	return -sqrt(d.x) * sign(d.y);
}

/**
 * Triangular subdivision
 */
void getNewTrianglePoints(in float seed, inout vec2 a, inout vec2 b, inout vec2 c) {
	float side = random(seed) * 3;
	float tilt = (0.5 + sin(snoise(vec2(syn_BassTime * 0.025 + TIME * 0.025))) * 0.5);
	
	if (side < 1.) {
		a = mix(a, b, tilt);
	} else if (side < 2.) {
		b = mix(b, c, tilt);
	} else {
		c = mix(c, a, tilt);
	}
}

/**
 * Subdivide triangle and give color and points back
 */
vec3 getSubTriangle(in vec2 uv, in float seed, inout vec2 a, inout vec2 b, inout vec2 c, vec3 prevColor, vec3 newColor) {
	getNewTrianglePoints(seed, a, b, c);
	float d = sdTriangle(uv, a, b, c);
	vec3 color = d >= 0 ? prevColor : newColor;
	return color;
}

/**
 * FbM colors ftw
 */
	
vec3 getColor(in vec2 uv, in float f, in float t, in vec3 colorA, in vec3 colorB) {
	vec3 color = _hsv2rgb(mix(
		vec3(1, 1 ,1 ),
		mix(
				vec3(colorA.x, colorA.y, 0.75 + 0.25 * sin(TIME * 0.1)),
				vec3(colorB.x, colorB.y, 0.75 + 0.25 * sin(TIME * 0.1)),
				t * 0.5 + uv.y * 0.5
		),
		clamp(f * 4.0, 0.0, 1.0)
	));
	
	return (1.5 * f) * color;
}

/**
 * Rotate coordinate system from the center by angle
 * @src https://thebookofshaders.com/08/
 * @param coordinates {vec2}
 * @param angle {float} - angle in radians (360 degrees = 2 * PI)
 * @return {vec2}
 */
vec2 rotate2d(vec2 coordinate, float angle){
	coordinate -= 0.5; // Move coordinate to center 
	coordinate = mat2(
		cos(angle),
		-sin(angle),
		sin(angle),
		cos(angle)
	) * coordinate; // Rotate coordinate
	coordinate += 0.5; // Reset coordinate from center 
	return coordinate;
}

/**
 * Rotate tile pattern
 * @src https://thebookofshaders.com/09/
 * @param coordinate {vec2} - normalized (0-1, 0-1) coordinate
 * @return {vec2}
 */
vec2 rotateTilePattern(vec2 coordinate){

	//  Scale the coordinate system by 2x2
	coordinate *= 2.0;

	//  Give each cell an index number
	//  according to its position
	float index = 0.0;
	index += step(1., mod(coordinate.x,2.0));
	index += step(1., mod(coordinate.y,2.0))*2.0;

	//      |
	//  2   |   3
	//      |
	//--------------
	//      |
	//  0   |   1
	//      |

	// Make each cell between 0.0 - 1.0
	coordinate = fract(coordinate);

	// Rotate each cell according to the index
	if(index == 1.0){
		//  Rotate cell 1 by 90 degrees
		coordinate = rotate2d(coordinate, PI*0.5);
	} else if(index == 2.0){
		//  Rotate cell 2 by -90 degrees
		coordinate = rotate2d(coordinate, PI*-0.5);
	} else if(index == 3.0){
		//  Rotate cell 3 by 180 degrees
		coordinate = rotate2d(coordinate, PI);
	}

	return coordinate;
}

/**
 * @main
 */
vec4 renderMain(void) {
	vec2 uv = _uv;
	uv.x *= (RENDERSIZE.x / RENDERSIZE.y);
	uv.x -= (RENDERSIZE.x - RENDERSIZE.y) * 0.5 / RENDERSIZE.y;
	uv = rotate2d(uv, sin(script_rotationTime) * 2 * PI);
	uv = rotateTilePattern(uv);
	
	float subs = floor(mod(syn_BPMTwitcher * 2, 30));
	
	// Outer triangle bounds
	vec2 a = vec2(1., 0.1);
	vec2 b = vec2(0.1, 1.);
	vec2 c = vec2(1., 1.9);
	
	// FbM colors ftw
	vec2 r = vec2(0.);
	r.x = fbm(uv  + 0.10, 1);
	float f = fbm(uv + r, 10);
	f = f * 0.5 + fbm(vec2(f * 0.5), 2);
	f = f * 0.5 + fbm(vec2(f * 0.5), 2);
	float t = smoothstep(0., 1., abs(map(fract(syn_BPMTwitcher * .0075), 0., 1., -1., 1.)));
	
	vec3 colors[10];
	colors[0] = vec3(color_a, 0.725, 0.75);
	colors[1] = vec3(color_b, 0.625, 0.75);
	colors[2] = vec3(color_c, 0.725, 0.75);
	colors[3] = vec3(color_d, 0.625, 0.75);
	colors[4] = vec3(color_e, 0.725, 0.75);
	
	vec3 bgColor = vec3(color_bg * syn_HighHits);
	
	float d = sdTriangle(uv, a, b, c);
	vec3 color = d >= 0 ? bgColor : getColor(uv, f, t, colors[0], colors[1]);
	
	color = getSubTriangle(uv, 3., a, b, c, color, getColor(uv, f, t, colors[1], colors[2]));
	color = getSubTriangle(uv, 8, a, b, c, color, getColor(uv, f, t, colors[2], colors[3]));
	color = getSubTriangle(uv, 3, a, b, c, color, getColor(uv, f, t, colors[3], colors[4]));
	color = getSubTriangle(uv, 4, a, b, c, color, getColor(uv, f, t, colors[4], colors[0]));
	color = getSubTriangle(uv, 3, a, b, c, color, getColor(uv, f, t, colors[0], colors[1]));
	color = getSubTriangle(uv, 6, a, b, c, color, getColor(uv, f, t, colors[1], colors[2]));
	color = getSubTriangle(uv, 7, a, b, c, color, getColor(uv, f, t, colors[2], colors[3]));
	color = getSubTriangle(uv, 8, a, b, c, color, getColor(uv, f, t, colors[3], colors[4]));

	// Output
	return vec4(color, 1.);
	
}