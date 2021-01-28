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
uniform sampler2D videoPass;

void mainImage(out vec4, in vec2);
void main(void) { mainImage(fragColor,inData.v_texcoord * iResolution.xy); }

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/**
 * Hexagon grid pattern
 * @src https://www.shadertoy.com/view/ll3yW7
 */
const vec2 s = vec2(1, 1.7320508); // 1.7320508 = sqrt(3)

vec4 calcHexInfo(vec2 uv) {
    vec4 hexCenter = round(vec4(uv, uv - vec2(.5, 1.)) / s.xyxy);
    vec4 offset = vec4(uv - hexCenter.xy * s, uv - (hexCenter.zw + .5) * s);
    return dot(offset.xy, offset.xy) < dot(offset.zw, offset.zw) ? 
        vec4(offset.xy, hexCenter.xy) : 
        vec4(offset.zw, hexCenter.zw);
}

/**
 * @main
 * Genuary 03 - Something human
 */
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy/iResolution.xy;
    uv.x *= iResolution.x/iResolution.y;
    
    // Hexagons
    float hexScale = 50.;
    vec4 hex = calcHexInfo(uv * hexScale);
    
    // Get video input
    vec2 videoUv = vec2(hex.zw / hexScale);
    videoUv.y = videoUv.y * s.y;; // Flip video input
    vec3 color = texture(videoPass, videoUv).rgb;
    
    // Output
    fragColor = vec4(color,1.0);
}


