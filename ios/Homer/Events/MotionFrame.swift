import CoreMotion
import simd

/// Device → world (reference frame, z vertical) for a device-motion sample, without trusting a
/// memorised convention: CMAttitude's matrix goes one way or the other, so pick the orientation
/// whose world-down, seen from the device, matches the sample's own gravity. Gimbal-free (no
/// Euler angles), so it holds with the phone upright, the boxing and discus grip.
enum MotionFrame {
    static func deviceToWorld(_ m: CMDeviceMotion) -> simd_double3x3 {
        let r = m.attitude.rotationMatrix
        let a = simd_double3x3(rows: [SIMD3(r.m11, r.m12, r.m13), SIMD3(r.m21, r.m22, r.m23), SIMD3(r.m31, r.m32, r.m33)])
        let g = SIMD3(m.gravity.x, m.gravity.y, m.gravity.z)
        // If `a` maps world → device, world-down (0,0,-1) lands on the device's gravity.
        let viaA = a * SIMD3(0, 0, -1)
        let viaT = a.transpose * SIMD3(0, 0, -1)
        return simd_distance(viaA, g) <= simd_distance(viaT, g) ? a.transpose : a
    }

    /// Heading (about the vertical) and elevation of a world-frame direction, radians.
    static func headingElevation(_ v: SIMD3<Double>) -> (heading: Double, elevation: Double) {
        let n = simd_length(v) > 1e-9 ? simd_normalize(v) : SIMD3(0, 1, 0)
        return (atan2(n.y, n.x), asin(max(-1, min(1, n.z))))
    }

    static func wrap(_ radians: Double) -> Double {
        var d = radians.truncatingRemainder(dividingBy: 2 * .pi)
        if d > .pi { d -= 2 * .pi }
        if d < -.pi { d += 2 * .pi }
        return d
    }
}
