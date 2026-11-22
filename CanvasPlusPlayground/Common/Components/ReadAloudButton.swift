//
//  ReadAloudButton.swift
//  CanvasPlusPlayground
//
//  Created by Kareem on 10/24/26.
//

import AVFoundation
import SwiftUI

struct ReadAloudButton: View {
    let html: String

    @State private var speaker = Speaker()

    var body: some View {
        Button(
            speaker.isSpeaking ? "Stop Reading" : "Read Aloud",
            systemImage: speaker.isSpeaking ? "stop.circle" : "speaker.wave.2"
        ) {
            if speaker.isSpeaking {
                speaker.stop()
            } else {
                speaker.speak(Self.plainText(from: html))
            }
        }
        .labelStyle(.iconOnly)
        .disabled(html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .onDisappear {
            speaker.stop()
        }
    }

    @MainActor
    private static func plainText(from html: String) -> String {
        let attributedString = try? NSAttributedString(
            data: Data(html.utf8),
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        return attributedString?.string ?? ""
    }
}

@MainActor
@Observable
private final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    private(set) var isSpeaking = false

    @ObservationIgnored private var currentUtterance: AVSpeechUtterance?

    @ObservationIgnored private lazy var synthesizer: AVSpeechSynthesizer = {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        return synthesizer
    }()

    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
        #endif

        let utterance = AVSpeechUtterance(string: trimmed)
        currentUtterance = utterance
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    func stop() {
        guard isSpeaking else { return }
        currentUtterance = nil
        synthesizer.stopSpeaking(at: .immediate)
        finish()
    }

    private func finish() {
        isSpeaking = false
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    private func utteranceEnded(_ id: ObjectIdentifier) {
        guard let currentUtterance, ObjectIdentifier(currentUtterance) == id else { return }
        self.currentUtterance = nil
        finish()
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in utteranceEnded(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in utteranceEnded(id) }
    }
}
