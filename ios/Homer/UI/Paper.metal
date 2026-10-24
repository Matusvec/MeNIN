// Paper grain for UI surfaces, matching the scene's finish pass.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static inline float paperHash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float paperNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(paperHash(i), paperHash(i + float2(1.0, 0.0)), f.x),
               mix(paperHash(i + float2(0.0, 1.0)), paperHash(i + float2(1.0, 1.0)), f.x), f.y);
}

[[ stitchable ]] half4 paperGrain(float2 position, half4 color, float amount) {
    if (color.a <= 0.0h) return color;
    // position is in points; these scales land near the scene's per-pixel tooth on a 3x screen.
    float tooth = paperNoise(position / 0.5) * 0.6 + paperNoise(position / 1.8) * 0.4 - 0.5;
    half3 rgb = color.rgb + half3(tooth * amount) * color.a;
    return half4(rgb, color.a);
}
