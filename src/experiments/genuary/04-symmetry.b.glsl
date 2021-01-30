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
uniform sampler2D video1;
uniform sampler2D photo1;
uniform vec2 direction;

void mainImage(out vec4, in vec2);
void main(void) { mainImage(fragColor,inData.v_texcoord * iResolution.xy); }

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

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
* RGB to HSB
* All components are in the range [0…1], including hue.
* @src https://stackoverflow.com/a/17897228
*/
vec3 rgb2hsb(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
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

/**
 * @main
 * Genuary 03 - Something human
 */
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Normalization
    vec2 uv = fragCoord/iResolution.xy;
    uv = rotateTilePattern(uv);
    
    // Loading texture
    vec3 color = texture(video1, uv).rgb;
    
    // Changing colors based on time
    color = rgb2hsb(color);
    color = mix(
        vec3(0.716, color.yz),
        vec3(0.991, color.yz),
        sin(color.r * (map(iTime * 30., 0. , 1000., -100., 100.) * uv.x * uv.y))
    ); 
    
    // Output
    fragColor = vec4(color, 1.);
}