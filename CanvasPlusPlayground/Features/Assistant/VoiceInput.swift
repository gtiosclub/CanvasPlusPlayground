//
//  VoiceInput.swift
//  CanvasPlusPlayground
//

import AVFoundation
import Foundation
import Speech

/// Dictation for the assistant's input bar: tap the mic to start, tap again (or pause for a
/// moment) to stop. The transcript updates live. Recognition runs on device when supported.
@MainActor
@Observable
final class VoiceInput {
    enum State: Equatable {
        case idle
        case listening
        case denied(String)
    }

    private(set) var state = State.idle
    private(set) var transcript = ""
    /// 0…1, from the microphone, for the pulsing ring.
    private(set) var level: Double = 0

    @ObservationIgnored private let recognizer = SFSpeechRecognizer()
    @ObservationIgnored private var engine: AVAudioEngine?
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private var silenceTimer: Task<Void, Never>?
    @ObservationIgnored var onFinish: ((String) -> Void)?

    /// Stops listening after this long without new words.
    var silenceTimeout: Duration = .seconds(1.8)

    var isListening: Bool { state == .listening }

    func toggle() {
        if isListening { stop() } else { Task { await start() } }
    }

    func start() async {
        guard !isListening else { return }
        transcript = ""

        guard await Self.authorize() else {
            state = .denied("Allow microphone and speech recognition for Canvas Plus in Settings to talk to the assistant.")
            return
        }
        guard let recognizer, recognizer.isAvailable else {
            state = .denied("Speech recognition isn't available right now.")
            return
        }

        do {
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            #endif

            let engine = AVAudioEngine()
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                request.append(buffer)
                let level = Self.level(of: buffer)
                Task { @MainActor in self?.level = level }
            }

            engine.prepare()
            try engine.start()

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                        self.restartSilenceTimer()
                        if result.isFinal { self.stop() }
                    } else if error != nil {
                        self.stop()
                    }
                }
            }

            self.engine = engine
            self.request = request
            state = .listening
            restartSilenceTimer()
        } catch {
            state = .denied("Couldn't start the microphone: \(error.localizedDescription)")
            teardown()
        }
    }

    func stop() {
        guard isListening else { return }
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        teardown()
        state = .idle
        if !text.isEmpty { onFinish?(text) }
    }

    func dismissError() {
        if case .denied = state { state = .idle }
    }

    private func teardown() {
        silenceTimer?.cancel()
        engine?.stop()
        engine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        engine = nil
        request = nil
        task = nil
        level = 0
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    private func restartSilenceTimer() {
        silenceTimer?.cancel()
        let timeout = silenceTimeout
        silenceTimer = Task { [weak self] in
            try? await Task.sleep(for: timeout)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, !self.transcript.isEmpty else { return }
                self.stop()
            }
        }
    }

    private static func authorize() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
        guard speech else { return false }
        #if os(iOS)
        return await AVAudioApplication.requestRecordPermission()
        #else
        return await AVCaptureDevice.requestAccess(for: .audio)
        #endif
    }

    private nonisolated static func level(of buffer: AVAudioPCMBuffer) -> Double {
        guard let data = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        var sum: Float = 0
        for index in 0..<Int(buffer.frameLength) { sum += data[index] * data[index] }
        let rms = sqrt(sum / Float(buffer.frameLength))
        return min(Double(rms) * 12, 1)
    }
}
