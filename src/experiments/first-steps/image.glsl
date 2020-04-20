#include "../../utils.glsl"

#ifdef GL_ES
precision mediump float;
#endif

/**
 * Draw helper for better portability between environments 
 */
vec4 draw(vec2 coordinate, vec2 resolution, float time) {
	float zoom = 1.;
	vec2 zoomVector = vec2(resolution.x / resolution.y * zoom, zoom); // Tile in squares

	vec2 uv = normalizedCoordinates(coordinate.xy, resolution.xy);
	uv = tile(uv, zoomVector);
	uv = rotate2d(uv, PI * 0.25 * time);
	uv = scale(uv, vec2(sin(time)+1.5));
	uv = rotateTilePattern(uv);

	vec3 color = 0.5 + 0.5 * cos(time + uv.xyx + vec3(0, 2, 4)); // Rotating color by time
	// vec3 color = vec3(box(uv, vec2(0.7),0.01)); // Boxes
	// float color = distanceField(uv, 4);
	return vec4(color, 1.0);
}

/**
 * Main
 */
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	fragColor = draw(fragCoord, iResolution.xy, iTime);
}