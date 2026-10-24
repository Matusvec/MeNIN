#include <metal_stdlib>
using namespace metal;

struct MetalCheckOut {
    float4 position [[position]];
    float2 uv;
};

// One oversized triangle covers the viewport.
vertex MetalCheckOut metalCheckVertex(uint vid [[vertex_id]]) {
    float2 p = float2((vid << 1) & 2, vid & 2);
    MetalCheckOut out;
    out.position = float4(p * 2.0 - 1.0, 0.0, 1.0);
    out.uv = p;
    return out;
}

fragment float4 metalCheckFragment(MetalCheckOut in [[stage_in]], constant float &time [[buffer(0)]]) {
    float band = 0.5 + 0.5 * sin(in.uv.x * 12.0 - time * 2.0);
    return float4(mix(float3(0.16, 0.22, 0.36), float3(0.91, 0.62, 0.30), band), 1.0);
}
