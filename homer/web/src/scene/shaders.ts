// The scene's shaders, ported from the iOS app (ios/Homer/Scene/Scene.metal).
// Three passes share one look: flat matte ink layers cut like paper, with soft
// cast shadows, mottled pigment and paper grain.
//   1. field:  domain-warped ink layers, rendered below screen resolution
//   2. flecks: flat dots, dashes and shards drawn over the field
//   3. finish: matte grade, paper tooth and grain at screen resolution

export const FULLSCREEN_VERT = /* glsl */ `#version 300 es
out vec2 vUv;
void main() {
  vec2 uv = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2);
  vUv = uv;
  gl_Position = vec4(uv * 2.0 - 1.0, 0.0, 1.0);
}`

const NOISE = /* glsl */ `
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x * 34.0) + 1.0) * x); }

// 2D simplex noise. Ashima Arts / Stefan Gustavson, MIT license.
float snoise(vec2 v) {
  const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
  vec2 i = floor(v + dot(v, C.yy));
  vec2 x0 = v - i + dot(i, C.xx);
  vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod289(i);
  vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
  vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
  m = m * m;
  m = m * m;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
  vec3 g;
  g.x = a0.x * x0.x + h.x * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

const mat2 ROT = mat2(0.8, -0.6, 0.6, 0.8);

float fbm(vec2 p, float jag, float detail) {
  float s = 0.0;
  float a = 0.5;
  for (int i = 0; i < 5; i++) {
    float n = snoise(p);
    n = mix(n, 0.6 - 2.0 * abs(n), jag); // ridged: torn-paper creases
    s += a * n * (i < 2 ? 1.0 : detail);
    p = ROT * p * 2.02 + vec2(13.7, 7.1);
    a *= 0.5;
  }
  return s;
}

float fbm3(vec2 p) {
  float s = 0.0;
  float a = 0.5;
  for (int i = 0; i < 3; i++) {
    s += a * snoise(p);
    p = ROT * p * 2.02 + vec2(3.1, 17.3);
    a *= 0.5;
  }
  return s;
}
`

export const FIELD_FRAG = /* glsl */ `#version 300 es
precision highp float;
uniform vec4 uA;        // res.xy, time, flow
uniform vec4 uB;        // drift.xy, turb, jag
uniform vec4 uC;        // detail, scale, tremble, lightY
uniform vec4 uD;        // lightAmt, soft, lift, wash (progress 0..1, < 0 idle)
uniform vec4 uWashInk;  // rgb
uniform vec4 uWashFrom; // xy direction, z: 1 from center, -1 from rim, 0 linear
uniform vec4 uRip[6];   // xy origin, z age (s), w strength
uniform float uW[9];    // mood weights
uniform vec4 uE;        // tilt, amp
uniform vec3 uInks[36]; // 9 moods × 4 inks, dark to light
out vec4 outColor;
${NOISE}
float squash(float x) { return x / (1.0 + abs(x)); }

const float T1 = 0.36;
const float T2 = 0.52;
const float T3 = 0.68;

vec3 layers(int mood, float f, float aa) {
  int b = mood * 4;
  vec3 col = mix(uInks[b], uInks[b + 1], smoothstep(T1 - aa, T1 + aa, f));
  col = mix(col, uInks[b + 2], smoothstep(T2 - aa, T2 + aa, f));
  return mix(col, uInks[b + 3], smoothstep(T3 - aa, T3 + aa, f));
}

float shadowAt(float t, float f, float fs, float aa) {
  return smoothstep(t - aa * 2.0, t + aa * 2.0, fs) * (1.0 - smoothstep(t - aa, t + aa, f));
}

// The layer height at one point: tilt stacks the inks, noise bends the edges,
// the hearth light lifts them, and ripples from stressed syllables pass through.
float layerField(vec2 p, vec2 s, vec2 w, float tilt, float amp, float turb, float jag,
                 float detail, float lightY, float lightAmt, float lift) {
  float f = 0.5 + tilt * p.y + amp * fbm(s + turb * w, jag, detail);
  vec2 lp = (p - vec2(0.0, lightY)) * vec2(0.6, 1.0);
  f += lightAmt * (exp(-dot(lp, lp) * 2.4) - 0.3) + lift;
  for (int i = 0; i < 6; i++) {
    vec4 R = uRip[i];
    if (R.w <= 0.0) continue;
    float d = length(p - R.xy) - R.z * 0.42;
    f += R.w * 0.16 * exp(-d * d / 0.004) * exp(-R.z * 1.1);
  }
  return f;
}

void main() {
  vec2 res = uA.xy;
  float time = uA.z;
  float flow = uA.w;
  vec2 drift = uB.xy;
  float turb = uB.z;
  float jag = uB.w;
  float detail = uC.x;
  float scale = uC.y;
  float tremble = uC.z;
  float lightY = uC.w;
  float lightAmt = uD.x;
  float soft = uD.y;
  float lift = uD.z;
  float wash = uD.w;

  // Centered, y up, one unit = screen height.
  vec2 p = (gl_FragCoord.xy - 0.5 * res) / res.y;
  float aspect = res.x / res.y;
  float tt = time * 29.0;
  p += tremble * 0.0045 * vec2(snoise(vec2(tt, 1.7)), snoise(vec2(5.3, tt)));

  // Layered horizons: the inks stack top to bottom (tilt), and a slow
  // domain-warped noise bends their edges (amp). Wide, calm shapes.
  float tilt = uE.x;
  float amp = uE.y;
  vec2 s = p * vec2(0.7, 1.1) * scale - drift;
  vec2 q = vec2(fbm(s + 0.11 * flow, jag, detail),
                fbm(s + vec2(5.2, 1.3) - 0.09 * flow, jag, detail));
  vec2 w = vec2(fbm(s + turb * q + vec2(1.7, 9.2) + 0.14 * flow, jag, detail),
                fbm(s + turb * q + vec2(8.3, 2.8) - 0.12 * flow, jag, detail));
  // The paper cast shadow down and to the right: sample the same field a few
  // pixels up and to the left, reusing the warp.
  vec2 toLight = vec2(-0.55, 1.0) * (6.0 / res.y);
  float f = layerField(p, s, w, tilt, amp, turb, jag, detail, lightY, lightAmt, lift);
  float fs = layerField(p + toLight, s + toLight * vec2(0.7, 1.1) * scale, w, tilt, amp, turb, jag, detail, lightY, lightAmt, lift);

  float aa = max(fwidth(f) * 0.8, soft);

  // Mixed feelings are marbled, not averaged: each patch of paper is cut
  // from one mood's inks, and patch area follows the weights.
  float m = fbm3(p * 0.5 - drift * 0.3 + 0.4 * q + vec2(31.0, 11.0) + 0.03 * flow);
  m = 0.5 + 0.46 * squash(m * 3.2);
  const float e = 0.03;
  float prev = 1.0;
  float acc = 0.0;
  vec3 col = vec3(0.0);
  for (int i = 0; i < 9; i++) {
    acc += uW[i];
    float S = i == 8 ? 0.0 : smoothstep(acc - e, acc + e, m);
    float k = prev - S;
    prev = S;
    if (k > 0.0005) col += k * layers(i, f, aa);
  }

  // Each layer casts a soft shadow down and to the right, like cut paper.
  float sh = shadowAt(T1, f, fs, aa) + shadowAt(T2, f, fs, aa) + shadowAt(T3, f, fs, aa);
  col *= 1.0 - 0.13 * clamp(sh, 0.0, 1.0);

  // Pigment mottling so the flat color reads as paint, not vector fill.
  col *= 0.965 + 0.035 * snoise(p * 9.0 + w * 2.0);

  // The wash: a sheet of the new mood's ink sweeps across when the feeling turns.
  if (wash >= 0.0) {
    float reach = 0.5 * length(vec2(aspect, 1.0));
    float d;
    if (uWashFrom.z > 0.5) d = length(p) / reach;
    else if (uWashFrom.z < -0.5) d = 1.0 - length(p) / reach;
    else d = 0.5 + dot(p, uWashFrom.xy) / (abs(uWashFrom.x) * aspect + abs(uWashFrom.y));
    d += 0.05 * snoise(p * 5.0 + 7.0) + 0.015 * snoise(p * 19.0);
    float front = mix(-0.3, 1.3, wash);
    float body = smoothstep(front - 0.32, front - 0.06, d);
    float edge = 1.0 - smoothstep(front - 0.004, front + 0.004, d);
    col = mix(col, uWashInk.rgb, body * edge * 0.92);
  }

  outColor = vec4(col, 1.0);
}`

export const FLECK_VERT = /* glsl */ `#version 300 es
layout(location = 0) in vec4 aP;     // x, y (scene units), size (CSS px), alpha
layout(location = 1) in vec4 aC;     // rgb, shape (0 dot, 1 dash, 2 shard)
layout(location = 2) in float aAngle;
uniform vec2 uView;                  // aspect, field px per CSS px
out vec4 vColor;
out float vShape;
out float vAngle;
void main() {
  gl_Position = vec4(aP.x / (0.5 * uView.x), aP.y / 0.5, 0.0, 1.0);
  gl_PointSize = max(aP.z * uView.y, 1.0);
  vColor = vec4(aC.rgb, aP.w);
  vShape = aC.w;
  vAngle = aAngle;
}`

export const FLECK_FRAG = /* glsl */ `#version 300 es
precision highp float;
in vec4 vColor;
in float vShape;
in float vAngle;
out vec4 outColor;

float sdTri(vec2 p, float r) {
  const float k = 1.7320508;
  p.x = abs(p.x) - r;
  p.y = p.y + r / k;
  if (p.x + k * p.y > 0.0) p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
  p.x -= clamp(p.x, -2.0 * r, 0.0);
  return -length(p) * sign(p.y);
}

void main() {
  vec2 c = gl_PointCoord - 0.5;
  c.y = -c.y;
  float ca = cos(vAngle);
  float sa = sin(vAngle);
  c = vec2(ca * c.x + sa * c.y, -sa * c.x + ca * c.y);
  float d;
  if (vShape < 0.5) d = length(c) - 0.48;
  else if (vShape < 1.5) d = max(abs(c.x) - 0.48, abs(c.y) - 0.06);
  else d = sdTri(vec2(c.y * 1.7, c.x), 0.26);
  float aa = fwidth(d);
  float a = vColor.a * (1.0 - smoothstep(-aa, aa, d));
  if (a < 0.004) discard;
  outColor = vec4(vColor.rgb * a, a); // premultiplied
}`

export const FINISH_FRAG = /* glsl */ `#version 300 es
precision highp float;
in vec2 vUv;
uniform sampler2D uScene;
uniform vec4 uA; // res.xy, time, vignette strength
uniform vec4 uB; // white point rgb
out vec4 outColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void main() {
  vec3 col = texture(uScene, vUv).rgb;

  // Matte finish: lift the blacks and ease the whites, like pigment on paper.
  col = mix(vec3(0.06, 0.05, 0.07), uB.rgb, col);

  // Paper tooth (fixed to the sheet) and a whisper of moving grain.
  vec2 px = gl_FragCoord.xy;
  float tooth = vnoise(px / 1.7) * 0.6 + vnoise(px / 6.0) * 0.4 - 0.5;
  float grain = hash(px + floor(uA.z * 24.0) * 17.0) - 0.5;
  float lum = dot(col, vec3(0.299, 0.587, 0.114));
  float mid = 1.0 - abs(lum - 0.5) * 1.4;
  col += (tooth * 0.045 + grain * 0.018) * mid;

  vec2 v = vUv - 0.5;
  v.x *= uA.x / uA.y;
  col *= 1.0 - uA.w * smoothstep(0.4, 1.15, length(v));

  outColor = vec4(col, 1.0);
}`
