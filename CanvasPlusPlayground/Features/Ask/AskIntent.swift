//
//  AskIntent.swift
//  CanvasPlusPlayground
//

import AppIntents
import Foundation

/// "Ask Canvas Plus" for Siri and Shortcuts. Answers from the course index on this device
/// (never the cloud) and speaks the verified sentences with their source titles.
struct AskCanvasPlusIntent: AppIntent {
    static let title: LocalizedStringResource = "Ask Canvas Plus"
    static let description = IntentDescription("Answers a question about your courses from your synced course content, on this device.")

    @Parameter(title: "Question", requestValueDialog: "What do you want to know about your courses?")
    var question: String

    static var parameterSummary: some ParameterSummary {
        Summary("Ask Canvas Plus \(\.$question)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        guard #available(iOS 26.0, macOS 26.0, *) else {
            let message = "Asking needs iOS 26 or macOS 26."
            return .result(value: message, dialog: IntentDialog(stringLiteral: message))
        }

        let session = AskSession(courseID: nil, retrieve: AskRetrieval.live())
        await session.ask(question)
        let answer = Self.spokenAnswer(for: session.current)
        return .result(value: answer, dialog: IntentDialog(stringLiteral: answer))
    }

    @available(iOS 26.0, macOS 26.0, *)
    static func spokenAnswer(for revision: AskRevision?) -> String {
        guard let revision, !revision.sentences.isEmpty else {
            return "I couldn't find that in your synced course content. Open Canvas Plus to try again."
        }

        let text = revision.sentences.map(\.text).joined(separator: " ")
        let sources = Array(Set(revision.sentences.flatMap(\.evidence).map(\.title))).sorted().prefix(3)
        return sources.isEmpty ? text : "\(text) Sources: \(sources.joined(separator: ", "))."
    }
}

struct CanvasPlusShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskCanvasPlusIntent(),
            phrases: [
                "Ask \(.applicationName)",
                "Ask \(.applicationName) about my courses",
            ],
            shortTitle: "Ask Your Courses",
            systemImageName: "questionmark.bubble"
        )
    }
}
