// Utilities

#define PI 3.14159265359
#define TWO_PI 6.28318530718


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
 * Pseudo-random with 2d vector input
 * @src https://thebookofshaders.com/10/
 * @param coordinate {vec2}
 * @return {float}
 */
float random(vec2 coordinate) {
	return fract(
		sin(dot(
			coordinate,
			vec2(12.9898, 78.233)
		)) 
	* 43758.5453123);
}

/**
 * Normalize coordinates
 * @param coordinate {vec2}
 * @param resolution {vec2}
 * @return {vec2} - coordinates normalized to 0-1 by resolution
 */
vec2 normalizedCoordinates(vec2 coordinate, vec2 resolution) {
	return coordinate / resolution;
}

/**
 * Tile coordinate system by zoom level
 * @param coordinates {vec2}
 * @param zoom {float}
 * @return {vec2} - coordinates scaled and tiled by zoom level
 */
vec2 tile(vec2 coordinate, vec2 zoom) {
	return fract(coordinate * zoom);
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
 * Scale coordinate system
 * @src https://thebookofshaders.com/08/
 * @param coordinate {vec2}
 * @param scale {vec2}
 * @return {vec2}
 */
vec2 scale(vec2 coordinate, vec2 scale){
	coordinate -= 0.5; // Move coordinate to center 
	coordinate = mat2(scale.x, 0.0, 0.0, scale.y) * coordinate; // Scale coordinate
	coordinate += 0.5; // Reset coordinate from center 
	return coordinate;
}

/**
 * Box color at coordinate
 * @src https://thebookofshaders.com/07/
 * @param coordinate {vec2}
 * @param size {vec2}
 * @param smoothEdges {float}
 * @return {float}
 */
float box(vec2 coordinate, vec2 size, float smoothEdges){
	size = vec2(0.5) - size * 0.5; // Center size
	
	vec2 aa = vec2(smoothEdges * 0.5);
	
	vec2 uv = smoothstep(size, size + aa, coordinate);
	uv *= smoothstep(size, size + aa, vec2(1.0) - coordinate);
	
	return uv.x * uv.y;
}


/**
 * Distance field
 * @src https://thebookofshaders.com/07/
 * @param coordinate {vec2} - normalized (0-1, 0-1) coordinate
 * @param sides {int} - Number of sides of your shape
 * @return {float}
 */
float distanceField(vec2 coordinate, int sides) {
	// Remap the space to -1. to 1.
	coordinate = coordinate * 2. - 1.;

	// Angle and radius from the current pixel
	float angle = atan(coordinate.x, coordinate.y) + PI;
	float radius = TWO_PI / float(sides);

	// Shaping function that modulate the distance
	float dist = cos(floor( .5 + angle / radius) * radius - angle) * length(coordinate);
	return dist;
}


/**
 * Distance field circle
 * @src https://thebookofshaders.com/07/
 * @param coordinate {vec2} - normalized (0-1, 0-1) coordinate
 * @param radius {float} - radius
 * @return {float} distance
 */
float distanceFieldCircle(vec2 coordinate, float radius, float edge) {
	vec2 dist = coordinate - vec2(0.5);
	return 1. - smoothstep(radius - (radius * edge),
		radius + (radius * edge),
		dot(dist, dist) * 4.0);
}

float distanceFieldCircle(vec2 coordinate, float radius) {
	return distanceFieldCircle(coordinate, radius, 0.01);
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