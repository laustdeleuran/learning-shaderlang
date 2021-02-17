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

void mainImage(out vec4, in vec2);
void main(void) { mainImage(fragColor,inData.v_texcoord * iResolution.xy); }

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/**
 * Basic mandelbrot math
 * @param vec2 z - current position
 * @param vec2 c - origin
 * @src https://www.youtube.com/watch?v=6IWXkV82oyY&ab_channel=TheArtofCode
 */
vec2 mandelbrot(in vec2 z, in vec2 c) {
    // f(z) = z^2 + c;
    return vec2(
        z.x * z.x - z.y * z.y,
        2 * z.x * z.y
    ) + c;
}

/**
 * Fractal iterations
 * @src https://www.youtube.com/watch?v=6IWXkV82oyY&ab_channel=TheArtofCode
 */
float mandelbrot(in vec2 c, in int maxIterations, in float bound) {
    vec2 z = vec2(0, 0);
    int iterations = 0;
    for (int i = 0; i < maxIterations; i++) {
        z = mandelbrot(z, c);
        if (length(z) > bound) break;
        iterations++;
    }
    return iterations/maxIterations;
}

/**
 * @main
 */
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord.xy - .5 * iResolution.xy) / iResolution.y;
    uv *= 3;
    
    float d = mandelbrot(uv, 100, 2.);
    fragColor = vec4(vec3(d),1.0);
}