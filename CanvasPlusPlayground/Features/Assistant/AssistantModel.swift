//
//  AssistantModel.swift
//  CanvasPlusPlayground
//

import Foundation
import SwiftUI

/// State for the floating assistant: which form the orb is in, the mini chat, and the questions
/// it offers for the current screen.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
@Observable
final class AssistantModel {
    enum Mode: Equatable {
        /// Just the orb.
        case idle
        /// Hover (Mac) or long press (iPhone): question chips above the orb.
        case suggestions
        /// Tap: a text field and mic next to the orb.
        case input
        /// A question was asked: the mini chat card.
        case chat
    }

    struct Turn: Identifiable, Equatable {
        enum Status: Equatable {
            case thinking(String)
            case answered(AssistantReply)
            case failed(String)
        }

        let id = UUID()
        let question: String
        let startedAt: Date
        var status: Status
    }

    var mode = Mode.idle
    var draft = ""
    private(set) var turns: [Turn] = []
    private(set) var generated: [AssistantSuggestion] = []
    private(set) var context = AssistantPageContext.dashboard

    let voice = VoiceInput()

    /// The record being opened, so its row can pulse while the card folds away.
    private(set) var openingID: String?
    /// Opens a record with an animated push on the current screen. Set by the host; returns false
    /// when the record has nowhere to go.
    @ObservationIgnored var navigate: ((Evidence) -> Bool)?

    @ObservationIgnored private var engine: AssistantEngine?
    @ObservationIgnored private var generationTask: Task<Void, Never>?
    @ObservationIgnored private var generatedCache: [String: [AssistantSuggestion]] = [:]

    init() {
        voice.onFinish = { [weak self] text in
            self?.draft = text
        }
    }

    func configure(dataSource: any AgentDataSource) {
        engine = AssistantEngine(dataSource: dataSource)
    }

    var isBusy: Bool {
        turns.last.map { if case .thinking = $0.status { true } else { false } } ?? false
    }

    /// The fixed questions for this screen, then the ones made for it.
    var suggestions: [AssistantSuggestion] {
        var seen = Set<String>()
        return (generated + AssistantSuggestions.faq(for: context)).filter { seen.insert($0.text.lowercased()).inserted }.prefix(4).map { $0 }
    }

    /// Follow-ups under the latest answer, as chips.
    var followUps: [AssistantSuggestion] {
        guard case .answered(let reply)? = turns.last?.status else { return [] }
        let fromReply = reply.followUps.map { AssistantSuggestion(text: $0, systemImage: "arrow.turn.down.right") }
        return Array((fromReply + suggestions).filter { suggestion in !turns.contains { $0.question == suggestion.text } }.prefix(3))
    }

    // MARK: Screen

    func updateContext(_ newContext: AssistantPageContext) {
        guard newContext != context else { return }
        context = newContext
        generated = generatedCache[newContext.cacheKey] ?? AssistantSuggestions.templates(for: newContext)
        generateSuggestions(for: newContext)
    }

    /// Questions for this screen, made in the background so the orb never waits on the model.
    private func generateSuggestions(for context: AssistantPageContext) {
        generationTask?.cancel()
        guard generatedCache[context.cacheKey] == nil else { return }

        generationTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            let questions = await AssistantSuggestions.generate(for: context)
            guard !Task.isCancelled, let self else { return }
            self.generatedCache[context.cacheKey] = questions
            if self.context == context {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { self.generated = questions }
            }
        }
    }

    // MARK: Asking

    func submitDraft() {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        draft = ""
        ask(question)
    }

    func ask(_ question: String, allowing tiers: Set<AgentTier> = [.onDevice]) {
        guard !isBusy, let engine else { return }
        if voice.isListening { voice.stop() }

        let history = turns.map(\.question)
        let intent = AssistantIntent.classify(question)
        let turn = Turn(question: question, startedAt: .now, status: .thinking(intent.workingLabel))

        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            mode = .chat
            turns.append(turn)
        }

        let context = context
        Task {
            let status: Turn.Status
            do {
                let reply = try await engine.answer(question, history: history, context: context, allowing: tiers)
                status = .answered(reply)
            } catch {
                status = .failed(error.localizedDescription)
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                if let index = turns.firstIndex(where: { $0.id == turn.id }) { turns[index].status = status }
            }
        }
    }

    /// Re-asks a question with the cloud model. Only called from the student's tap.
    func tryWithCloud(_ turn: Turn) {
        ask(turn.question, allowing: [.cloud])
    }

    var isCloudReady: Bool {
        AgentModelRouter().cloud?.isAvailable == true
    }

    /// What the thinking row says: the latest tool the run called, else the intent's label.
    func liveStep(for turn: Turn) -> String? {
        guard case .thinking(let label) = turn.status else { return nil }
        let lastTool = ExecutionLedger.shared.liveEntries.last { entry in
            guard entry.timestamp >= turn.startedAt, case .toolCall = entry.kind else { return false }
            return true
        }
        guard case let .toolCall(name, _, _, _)? = lastTool?.kind else { return label }
        return Self.label(forTool: name) ?? label
    }

    static func label(forTool name: String) -> String? {
        switch name {
        case "listAssignments": "Reading your assignments"
        case "listAnnouncements": "Reading announcements"
        case "listCalendarEvents": "Checking your calendar"
        case "listToDos": "Checking your to-dos"
        case "listCourses": "Looking at your courses"
        case "listFiles": "Looking through files"
        default: nil
        }
    }

    // MARK: Opening records

    /// A tap on a record: the row pulses, the card folds back into the orb (the conversation is
    /// kept; tap the orb to bring it back), then the record opens with an animated push.
    func open(_ evidence: Evidence) {
        guard openingID == nil else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { openingID = evidence.id }

        Task {
            try? await Task.sleep(for: .milliseconds(140))
            minimize()
            try? await Task.sleep(for: .milliseconds(220))
            if navigate?(evidence) != true {
                AssistantNavigation.open(evidence)
            }
            try? await Task.sleep(for: .milliseconds(300))
            openingID = nil
        }
    }

    /// Folds the chat back into the orb without forgetting it.
    func minimize() {
        if voice.isListening { voice.stop() }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) { mode = .idle }
    }

    // MARK: Spotlight

    /// Double tap on the orb: search everything, over a blurred app.
    private(set) var isSpotlightPresented = false

    func toggleSpotlight() {
        if voice.isListening { voice.stop() }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if !isSpotlightPresented, mode != .idle { mode = .idle }
            isSpotlightPresented.toggle()
        }
    }

    /// Hands a search that reads like a question to the chat.
    func askFromSpotlight(_ question: String) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { isSpotlightPresented = false }
        Task {
            try? await Task.sleep(for: .milliseconds(180))
            ask(question)
        }
    }

    /// There's a conversation to come back to.
    var hasConversation: Bool { !turns.isEmpty }

    // MARK: Orb

    func close() {
        if voice.isListening { voice.stop() }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            mode = .idle
            turns = []
            draft = ""
        }
    }

    func showSuggestions() {
        guard mode == .idle else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) { mode = .suggestions }
    }

    func hideSuggestions() {
        guard mode == .suggestions else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { mode = .idle }
    }

    /// Single tap or click on the orb.
    func tapOrb() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.66)) {
            switch mode {
            case .idle, .suggestions: mode = hasConversation ? .chat : .input
            case .input: mode = .idle
            case .chat: break
            }
        }
    }
}
