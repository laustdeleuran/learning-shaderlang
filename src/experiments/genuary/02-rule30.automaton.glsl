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
uniform sampler2D texture1;

void mainImage(out vec4, in vec2);
void main(void) { mainImage(fragColor,inData.v_texcoord * iResolution.xy); }

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/**
 * @overview
 * @src https://www.shadertoy.com/view/4dVczK
 * First attempt at running Rule 30 as part of Genuary 2021-02. 
 * Huge props to *microwerx* for a bunch of inspiration for this code. 
 */

/**
 * @const
 * Colors
 */
const vec3 colorBlack = vec3(0.0);
const vec3 colorWhite = vec3(1.0);

/**
 * @const
 * Texel states
 */
const int painted = 1;
const int blank = 0;

/**
 * @const
 * @src https://mathworld.wolfram.com/Rule30.html
 * Rule 30 – basically the first three values are the arguments, the 4th value the outcome
 */
const ivec4 rule30set[8] = ivec4[8](
  ivec4(painted, painted, painted, blank),
  ivec4(painted, painted, blank, blank),
  ivec4(painted, blank, painted, blank),
  ivec4(painted, blank, blank, painted),
  ivec4(blank, painted, painted, painted),
  ivec4(blank, painted, blank, painted),
  ivec4(blank, blank, painted, painted),
  ivec4(blank, blank, blank, blank)
);

/**
 * @function
 * Loops through the rules array and outputs the color
 * based on the given parent's states
 */
vec3 rule30(int a, int b, int c) {
  for (int i = 0; i < 8; i++) {
    if (rule30set[i].xyz == ivec3(a, b, c)) 
      return rule30set[i].w == painted ? colorBlack : colorWhite;
  }
}

/**
 * @main
 */
void mainImage(out vec4 fragColor, in vec2 fragCoord) {

  // Normalized pixel coordinates (from 0 to 1)
  vec2 uv = fragCoord/iResolution.xy;
  
  // Set fallback colors of parent pixels to white
  vec3 va = colorWhite;
  vec3 vb = colorWhite;
  vec3 vc = colorWhite;
  
  // Get texture from buffer (self)
  vec3 original = texture(texture1, uv).rgb;
  ivec2 iuv = ivec2(fragCoord);
  ivec2 iwh = ivec2(iResolution.xy);

  // Load parent texel color values
  if (iuv.x > 0 && iuv.x < iwh.x - 1) {
    va = texelFetch(texture1, iuv + ivec2(-1, 1), 0).rgb;
    vb = texelFetch(texture1, iuv + ivec2( 0, 1), 0).rgb;
    vc = texelFetch(texture1, iuv + ivec2( 1, 1), 0).rgb;
  }
  
  // Determine texel state based on the red channel 
  // we could use any channel here, since we're
  // painting with black. 
  int a = (va.r < 0.5) ? painted : blank;
  int b = (vb.r < 0.5) ? painted : blank;
  int c = (vc.r < 0.5) ? painted : blank;
  
  // Look up current fragment's color
  vec3 color = rule30(a, b ,c);

  // Retain rows from previous render
  if (iuv.y == iwh.y - 1) {
    fragColor = vec4(original, 1.0);
  } else {
    fragColor = vec4(color, 1.0);
  }

  // Seed with black at the beginning, then use white for the rest
  if (iTime < 0.2) {
    if ((iuv.y == iwh.y - 1) && iuv.x == (iwh.x >> 1)) {
      fragColor = vec4(colorBlack, 1.0);
    } else {
      fragColor = vec4(colorWhite, 1.0);
    }
  }
}