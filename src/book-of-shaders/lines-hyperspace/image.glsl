#include "../../utils.glsl"

#ifdef GL_ES
precision mediump float;
#endif

#define SIZE 10.

/**
 * Draw helper for better portability between environments 
 */
vec4 draw(vec2 coordinate, vec2 resolution, float time, vec2 mouse) {
	float rows = resolution.y / SIZE;
	float columns = resolution.x / SIZE;
		
	// Normalize coordinates and set up grid
	vec2 uv = normalizedCoordinates(coordinate.xy, resolution.xy);
	uv = vec2(uv.x * columns, uv.y * rows);
	vec2 iPos = floor(uv); // get the integer coords
	vec2 fPos = fract(uv); // get the fractional coords
	
	// Velocity
	float velocity = iTime * 50.; // Base velocity based on time
	velocity *= -1. * random(1.0 + iPos.y); // Randomize by row index
	float x = floor(uv.x + velocity); // Add velocity to current position
	
	// Get color from x position and mouse 
	float color = step(
		0.25 + mouse.x / resolution.x, 
		random(100. + x * .000001) + random(x) * 0.5
	);
	
	// Margins
	color *= step(1. / SIZE, fPos.y);
	color *= 1. - step(1. - 1. / SIZE, fPos.y);
	
	// Assign a random value based on the integer coord
	return vec4(vec3(1. - color), 1.0);
}

/**
 * Main
 */
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	fragColor = draw(fragCoord, iResolution.xy, iTime, iMouse.xy);
}