/**
 * LPD8
 */
const vec2 LPD8_K1 = vec2(30, 11);
const vec2 LPD8_K2 = vec2(31, 11);
const vec2 LPD8_K3 = vec2(0, 12);
const vec2 LPD8_K4 = vec2(1, 12);
const vec2 LPD8_K5 = vec2(2, 12);
const vec2 LPD8_K6 = vec2(3, 12);
const vec2 LPD8_K7 = vec2(4, 12);
const vec2 LPD8_K8 = vec2(5, 12);

const vec2 LPD8_P1A = vec2(3, 5);
const vec2 LPD8_P2A = vec2(4, 5);
const vec2 LPD8_P3A = vec2(5, 5);
const vec2 LPD8_P4A = vec2(6, 5);
const vec2 LPD8_P5A = vec2(7, 5);
const vec2 LPD8_P6A = vec2(8, 5);
const vec2 LPD8_P7A = vec2(9, 5);
const vec2 LPD8_P8A = vec2(10, 5);

const vec2 LPD8_P1B = vec2(11, 5);
const vec2 LPD8_P2B = vec2(12, 5);
const vec2 LPD8_P3B = vec2(13, 5);
const vec2 LPD8_P4B = vec2(14, 5);
const vec2 LPD8_P5B = vec2(15, 5);
const vec2 LPD8_P6B = vec2(16, 5);
const vec2 LPD8_P7B = vec2(17, 5);
const vec2 LPD8_P8B = vec2(18, 5);

float getLPD8Value(vec2 coord) {
    return texture(midi1, coord / 32.).x;
}