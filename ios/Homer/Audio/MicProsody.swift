import AVFoundation
import Observation
import os

/// Mic -> Prosody at display rate, for the scene's instant layer.
/// Views read `prosody`; nothing here knows about presentation.
@Observable
@MainActor
final class MicProsody {
    private(set) var prosody = Prosody.silent
    private(set) var isRunning = false
    private(set) var error: String?

    @ObservationIgnored private let capture = MicCapture()
    @ObservationIgnored private var poll: Task<Void, Never>?

    func start() async {
        guard !isRunning else { return }
        error = nil
        guard await AVAudioApplication.requestRecordPermission() else {
            error = "Microphone access is off. Turn it on in Settings > Privacy > Microphone."
            return
        }
        do {
            try AudioSessionConfig.activateForRecording()
            try capture.start()
        } catch {
            self.error = "Mic failed to start: \(error.localizedDescription)"
            return
        }
        isRunning = true
        poll = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                if let p = self.capture.latestProsody() { self.prosody = p }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    func stop() {
        poll?.cancel()
        poll = nil
        capture.stop()
        isRunning = false
        prosody = .silent
    }
}

/// Owns the engine and a ring of the most recent samples. The tap runs on the audio
/// thread and only copies; analysis happens on the reader's thread.
final class MicCapture: @unchecked Sendable {
    static let window = 2048

    private let engine = AVAudioEngine()
    private let ring = OSAllocatedUnfairLock(initialState: Ring(capacity: MicCapture.window))
    private var sampleRate: Double = 48_000

    func start() throws {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw NSError(domain: "Homer.Mic", code: 1, userInfo: [NSLocalizedDescriptionKey: "No microphone input"])
        }
        sampleRate = format.sampleRate
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [ring] buffer, _ in
            guard let channel = buffer.floatChannelData?[0] else { return }
            let samples = UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength))
            ring.withLock { $0.append(samples) }
        }
        engine.prepare()
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        ring.withLock { $0.reset() }
    }

    /// Nil until a full window has arrived since the last read.
    func latestProsody() -> Prosody? {
        let window: [Float]? = ring.withLock { $0.takeIfFresh() }
        guard let window else { return nil }
        return window.withUnsafeBufferPointer { ProsodyAnalyzer.analyze($0, sampleRate: sampleRate) }
    }
}

private struct Ring {
    private var buffer: [Float]
    private var head = 0
    private var filled = 0
    private var fresh = false

    init(capacity: Int) {
        buffer = Array(repeating: 0, count: capacity)
    }

    mutating func append(_ samples: UnsafeBufferPointer<Float>) {
        for s in samples {
            buffer[head] = s
            head = (head + 1) % buffer.count
        }
        filled = min(buffer.count, filled + samples.count)
        fresh = true
    }

    mutating func takeIfFresh() -> [Float]? {
        guard fresh, filled == buffer.count else { return nil }
        fresh = false
        return Array(buffer[head...] + buffer[..<head])
    }

    mutating func reset() {
        head = 0
        filled = 0
        fresh = false
    }
}
