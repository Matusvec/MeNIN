import AVFoundation

enum AudioSessionConfig {
    /// Play and record through the speaker (not the earpiece).
    static func activateForRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setPreferredIOBufferDuration(0.01)
        try session.setActive(true)
    }
}
