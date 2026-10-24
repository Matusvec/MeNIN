// The scene. Three passes share one look: flat matte ink layers cut like
// paper, with soft cast shadows, mottled pigment and paper grain.
//   1. field:  domain-warped ink layers, rendered below screen resolution
//   2. flecks: flat dots, dashes and shards drawn over the field
//   3. finish: matte grade, paper tooth and grain at full resolution

#include <metal_stdlib>
using namespace metal;

constant int MOOD_COUNT = 9;
constant int RIPPLE_COUNT = 6;

// Mirrors FieldUniforms in SceneMotion.swift. Every member is a float4 so the
// layout is identical on both sides.
struct FieldUniforms {
    float4 a;         // res.xy, time, flow
    float4 b;         // drift.xy, turb, jag
    float4 c;         // detail, scale, tremble, lightY
    float4 d;         // lightAmt, soft, lift, wash (progress 0..1, < 0 idle)
    float4 washInk;   // rgb
    float4 washFrom;  // xy direction, z: 1 from center, -1 from rim, 0 linear
    float4 rip[RIPPLE_COUNT]; // xy origin, z age (s), w strength
    float4 w[3];      // mood weights, 9 used
    float4 e;         // tilt, amp
};

struct FinishUniforms {
    float4 a; // res.xy, time, vignette strength
    float4 b; // white point rgb (the grade maps 1.0 here), unused
};

// Mirrors Fleck in SceneMotion.swift.
struct Fleck {
    float4 p; // x, y (scene units), size (points), alpha
    float4 c; // rgb, shape (0 dot, 1 dash, 2 shard)
    float4 r; // angle, aspect, unused, unused
};

struct FullOut {
    float4 position [[position]];
    float2 uv;
};

vertex FullOut fullscreen_vertex(uint vid [[vertex_id]]) {
    float2 uv = float2((vid << 1) & 2, vid & 2);
    FullOut o;
    o.position = float4(uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    o.uv = uv;
    return o;
}

// MARK: - Noise

// GLSL-style mod (floored), not fmod (truncated): they differ for negatives.
static inline float3 mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static inline float2 mod289(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static inline float3 permute(float3 x) { return mod289(((x * 34.0) + 1.0) * x); }

// 2D simplex noise. Ashima Arts / Stefan Gustavson, MIT license.
static float snoise(float2 v) {
    const float4 C = float4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
    float2 i = floor(v + dot(v, C.yy));
    float2 x0 = v - i + dot(i, C.xx);
    float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0)) + i.x + float3(0.0, i1.x, 1.0));
    float3 m = max(0.5 - float3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;
    float3 x = 2.0 * fract(p * C.www) - 1.0;
    float3 h = abs(x) - 0.5;
    float3 ox = floor(x + 0.5);
    float3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    float3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

constant float2x2 ROT = float2x2(float2(0.8, -0.6), float2(0.6, 0.8));

static float fbm(float2 p, float jag, float detail) {
    float s = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        float n = snoise(p);
        n = mix(n, 0.6 - 2.0 * abs(n), jag); // ridged: torn-paper creases
        s += a * n * (i < 2 ? 1.0 : detail);
        p = ROT * p * 2.02 + float2(13.7, 7.1);
        a *= 0.5;
    }
    return s;
}

static float fbm3(float2 p) {
    float s = 0.0;
    float a = 0.5;
    for (int i = 0; i < 3; i++) {
        s += a * snoise(p);
        p = ROT * p * 2.02 + float2(3.1, 17.3);
        a *= 0.5;
    }
    return s;
}

static inline float squash(float x) { return x / (1.0 + abs(x)); }

// MARK: - Field

constant float T1 = 0.36;
constant float T2 = 0.52;
constant float T3 = 0.68;

static inline float3 layers(constant float4 *inks, int mood, float f, float aa) {
    constant float4 *k = inks + mood * 4;
    float3 col = mix(k[0].rgb, k[1].rgb, smoothstep(T1 - aa, T1 + aa, f));
    col = mix(col, k[2].rgb, smoothstep(T2 - aa, T2 + aa, f));
    return mix(col, k[3].rgb, smoothstep(T3 - aa, T3 + aa, f));
}

static inline float shadowAt(float t, float f, float fs, float aa) {
    return smoothstep(t - aa * 2.0, t + aa * 2.0, fs) * (1.0 - smoothstep(t - aa, t + aa, f));
}

// The layer height at one point: tilt stacks the inks, noise bends the edges,
// the hearth light lifts them, and ripples from stressed syllables pass through.
static float layerField(float2 p, float2 s, float2 w, float tilt, float amp, float turb, float jag,
                        float detail, float lightY, float lightAmt, float lift, constant FieldUniforms &U) {
    float f = 0.5 + tilt * p.y + amp * fbm(s + turb * w, jag, detail);
    float2 lp = (p - float2(0.0, lightY)) * float2(0.6, 1.0);
    f += lightAmt * (exp(-dot(lp, lp) * 2.4) - 0.3) + lift;
    for (int i = 0; i < RIPPLE_COUNT; i++) {
        float4 R = U.rip[i];
        if (R.w <= 0.0) continue;
        float d = length(p - R.xy) - R.z * 0.42;
        f += R.w * 0.16 * exp(-d * d / 0.004) * exp(-R.z * 1.1);
    }
    return f;
}

fragment float4 field_fragment(FullOut in [[stage_in]],
                               constant FieldUniforms &U [[buffer(0)]],
                               constant float4 *inks [[buffer(1)]]) {
    float2 res = U.a.xy;
    float time = U.a.z;
    float flow = U.a.w;
    float2 drift = U.b.xy;
    float turb = U.b.z;
    float jag = U.b.w;
    float detail = U.c.x;
    float scale = U.c.y;
    float tremble = U.c.z;
    float lightY = U.c.w;
    float lightAmt = U.d.x;
    float soft = U.d.y;
    float lift = U.d.z;
    float wash = U.d.w;

    // Centered, y up, one unit = screen height.
    float2 frag = in.position.xy;
    float2 p = float2(frag.x - 0.5 * res.x, 0.5 * res.y - frag.y) / res.y;
    float aspect = res.x / res.y;
    float tt = time * 29.0;
    p += tremble * 0.0045 * float2(snoise(float2(tt, 1.7)), snoise(float2(5.3, tt)));

    // Layered horizons: the inks stack top to bottom (tilt), and a slow
    // domain-warped noise bends their edges (amp). Wide, calm shapes.
    float tilt = U.e.x;
    float amp = U.e.y;
    float2 s = p * float2(0.7, 1.1) * scale - drift;
    float2 q = float2(fbm(s + 0.11 * flow, jag, detail),
                      fbm(s + float2(5.2, 1.3) - 0.09 * flow, jag, detail));
    float2 w = float2(fbm(s + turb * q + float2(1.7, 9.2) + 0.14 * flow, jag, detail),
                      fbm(s + turb * q + float2(8.3, 2.8) - 0.12 * flow, jag, detail));
    // The paper cast shadow down and to the right: sample the same field a few
    // pixels up and to the left. The warp (w) barely changes over that distance,
    // so it is reused and only the last octave stack runs twice.
    float2 toLight = float2(-0.55, 1.0) * (6.0 / res.y);
    float f = layerField(p, s, w, tilt, amp, turb, jag, detail, lightY, lightAmt, lift, U);
    float fs = layerField(p + toLight, s + toLight * float2(0.7, 1.1) * scale, w, tilt, amp, turb, jag, detail, lightY, lightAmt, lift, U);

    float aa = max(fwidth(f) * 0.8, soft);

    // Mixed feelings are marbled, not averaged: each patch of paper is cut
    // from one mood's inks, and patch area follows the weights.
    float m = fbm3(p * 0.5 - drift * 0.3 + 0.4 * q + float2(31.0, 11.0) + 0.03 * flow);
    m = 0.5 + 0.46 * squash(m * 3.2); // stays inside (0.04, 0.96), clear of the edge bins
    const float e = 0.03;
    float prev = 1.0;
    float acc = 0.0;
    float3 col = float3(0.0);
    for (int i = 0; i < MOOD_COUNT; i++) {
        acc += U.w[i / 4][i % 4];
        float S = i == MOOD_COUNT - 1 ? 0.0 : smoothstep(acc - e, acc + e, m);
        float k = prev - S;
        prev = S;
        if (k > 0.0005) col += k * layers(inks, i, f, aa);
    }

    // Each layer casts a soft shadow down and to the right, like cut paper.
    float sh = shadowAt(T1, f, fs, aa) + shadowAt(T2, f, fs, aa) + shadowAt(T3, f, fs, aa);
    col *= 1.0 - 0.13 * clamp(sh, 0.0, 1.0);

    // Pigment mottling so the flat color reads as paint, not vector fill.
    col *= 0.965 + 0.035 * snoise(p * 9.0 + w * 2.0);

    // The wash: a sheet of the new mood's ink sweeps across when the feeling turns.
    if (wash >= 0.0) {
        float reach = 0.5 * length(float2(aspect, 1.0));
        float d;
        if (U.washFrom.z > 0.5) d = length(p) / reach;
        else if (U.washFrom.z < -0.5) d = 1.0 - length(p) / reach;
        else d = 0.5 + dot(p, U.washFrom.xy) / (abs(U.washFrom.x) * aspect + abs(U.washFrom.y));
        d += 0.05 * snoise(p * 5.0 + 7.0) + 0.015 * snoise(p * 19.0);
        float front = mix(-0.3, 1.3, wash);
        float body = smoothstep(front - 0.32, front - 0.06, d);
        float edge = 1.0 - smoothstep(front - 0.004, front + 0.004, d);
        col = mix(col, U.washInk.rgb, body * edge * 0.92);
    }

    return float4(col, 1.0);
}

// MARK: - Flecks

struct FleckOut {
    float4 position [[position]];
    float size [[point_size]];
    float4 color;
    float shape;
    float angle;
};

vertex FleckOut fleck_vertex(uint vid [[vertex_id]],
                             constant Fleck *flecks [[buffer(0)]],
                             constant float4 &view [[buffer(1)]]) { // aspect, field px per point
    Fleck k = flecks[vid];
    float aspect = view.x;
    FleckOut o;
    o.position = float4(k.p.x / (0.5 * aspect), k.p.y / 0.5, 0.0, 1.0);
    o.size = max(k.p.z * view.y, 1.0);
    o.color = float4(k.c.rgb, k.p.w);
    o.shape = k.c.w;
    o.angle = k.r.x;
    return o;
}

static float sdTri(float2 p, float r) {
    const float k = 1.7320508;
    p.x = abs(p.x) - r;
    p.y = p.y + r / k;
    if (p.x + k * p.y > 0.0) p = float2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    p.x -= clamp(p.x, -2.0 * r, 0.0);
    return -length(p) * sign(p.y);
}

fragment float4 fleck_fragment(FleckOut in [[stage_in]], float2 pc [[point_coord]]) {
    float2 c = pc - 0.5;
    c.y = -c.y;
    float ca = cos(in.angle);
    float sa = sin(in.angle);
    c = float2(ca * c.x + sa * c.y, -sa * c.x + ca * c.y);
    float d;
    if (in.shape < 0.5) d = length(c) - 0.48;
    else if (in.shape < 1.5) d = max(abs(c.x) - 0.48, abs(c.y) - 0.06);
    else d = sdTri(float2(c.y * 1.7, c.x), 0.26);
    float aa = fwidth(d);
    float a = in.color.a * (1.0 - smoothstep(-aa, aa, d));
    if (a < 0.004) discard_fragment();
    return float4(in.color.rgb * a, a); // premultiplied
}

// MARK: - Finish

static inline float hash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float vnoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + float2(1.0, 0.0)), f.x),
               mix(hash(i + float2(0.0, 1.0)), hash(i + float2(1.0, 1.0)), f.x), f.y);
}

fragment float4 finish_fragment(FullOut in [[stage_in]],
                                texture2d<float> scene [[texture(0)]],
                                constant FinishUniforms &U [[buffer(0)]]) {
    constexpr sampler linear(filter::linear, address::clamp_to_edge);
    float3 col = scene.sample(linear, in.uv).rgb;

    // Matte finish: lift the blacks and ease the whites, like pigment on paper.
    col = mix(float3(0.06, 0.05, 0.07), U.b.rgb, col);

    // Paper tooth (fixed to the sheet) and a whisper of moving grain.
    float2 px = in.position.xy;
    float tooth = vnoise(px / 1.7) * 0.6 + vnoise(px / 6.0) * 0.4 - 0.5;
    float grain = hash(px + floor(U.a.z * 24.0) * 17.0) - 0.5;
    float lum = dot(col, float3(0.299, 0.587, 0.114));
    float mid = 1.0 - abs(lum - 0.5) * 1.4;
    col += (tooth * 0.045 + grain * 0.018) * mid;

    float2 v = in.uv - 0.5;
    v.x *= U.a.x / U.a.y;
    col *= 1.0 - U.a.w * smoothstep(0.4, 1.15, length(v));

    return float4(col, 1.0);
}
