#define PI 3.14159265359

/**
 * Utils
 */
float map(float value, float min1, float max1, float min2, float max2) {
	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
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
 * Genuary 03 - Something human
 */
vec4 renderMain(void) {
	// Normalization
	vec2 uv = _uv;
	if (RENDERSIZE.x > RENDERSIZE.y) {
		uv.y *= (RENDERSIZE.y / RENDERSIZE.x);
		uv.y -= (RENDERSIZE.y - RENDERSIZE.x) * 0.5 / RENDERSIZE.x;
	} else {
		uv.x *= (RENDERSIZE.x / RENDERSIZE.y);
		uv.x -= (RENDERSIZE.x - RENDERSIZE.y) * 0.5 / RENDERSIZE.y;
	}
	uv = rotateTilePattern(uv);
	
	// Loading texture
	vec3 color;
	if (_exists(syn_UserImage)) {
		color = _loadUserImage().rgb;
	} else {
		color = texture(sandPattern, uv).rgb;
	}
	
	// Changing colors based on time
	color = _rgb2hsv(color);
	color = mix(
		vec3(color_a, color.yz),
		vec3(color_b, color.yz),
		sin(color.r * (map(script_time * 30., 0. , 1000., -100., 100.) * uv.x * uv.y))
	); 
	
	// Output
	return vec4(color, 1.);
}