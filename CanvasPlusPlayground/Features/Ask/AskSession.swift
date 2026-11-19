//
//  AskSession.swift
//  CanvasPlusPlayground
//

import Foundation
import FoundationModels
import SwiftData

/// One version of the answer card. A follow-up adds a revision instead of a new message.
struct AskRevision: Identifiable, Sendable {
    struct Sentence: Identifiable, Sendable {
        let id = UUID()
        let text: String
        /// The records it cites, as re-read by the gate.
        let evidence: [Evidence]
    }

    let id = UUID()
    /// The question as the student asked it, plus any follow-ups so far.
    let questions: [String]
    let sentences: [Sentence]
    /// Everything retrieved for this revision, for the "Sources" list.
    let sources: [Evidence]
    let tier: AgentTier
    /// Sentences the gate wouldn't show (no valid citation).
    let droppedCount: Int
    /// No model: the card quotes the best passages instead of answering.
    let isExtractive: Bool
    /// The on-device answer didn't hold up; the student can choose to try the cloud.
    let shouldOfferCloud: Bool

    var question: String { questions.joined(separator: " → ") }
}

/// "Ask your course": retrieval (in Swift, from the semantic index and cached assignments), one
/// model call per question or follow-up, and the EvidenceGate between the model and the card.
/// The cloud is only used when the student taps "Try with cloud?".
@available(iOS 26.0, macOS 26.0, *)
@MainActor
@Observable
final class AskSession {
    typealias Retrieve = @MainActor (_ query: String, _ courseID: String?) async -> [Evidence]

    enum State: Equatable {
        case idle
        case thinking
        case answered
        case failed(String)
    }

    @Generable
    struct ModelAnswer {
        @Guide(description: "Two to four short sentences that answer the question, each citing the records it uses.")
        var sentences: [ModelSentence]
        @Guide(description: "How sure you are the records answer the question.", .anyOf(["high", "medium", "low"]))
        var confidence: String
    }

    @Generable
    struct ModelSentence {
        var text: String
        @Guide(description: "Ids of the records this sentence relies on, exactly as given, like page:12#0 or assignment:34.")
        var citedIDs: [String]
    }

    /// Context window share for retrieved records.
    static let contextTokens = 2_200
    static let retrievalLimit = 8

    let courseID: String?
    private(set) var state = State.idle
    private(set) var revisions: [AskRevision] = []
    var selectedRevision = 0

    private let retrieve: Retrieve
    private let router: AgentModelRouter
    private let fallbackResolver: (any EvidenceResolver)?

    init(
        courseID: String?,
        retrieve: @escaping Retrieve,
        router: AgentModelRouter = AgentModelRouter(),
        fallbackResolver: (any EvidenceResolver)? = nil
    ) {
        self.courseID = courseID
        self.retrieve = retrieve
        self.router = router
        self.fallbackResolver = fallbackResolver
    }

    var current: AskRevision? {
        revisions.indices.contains(selectedRevision) ? revisions[selectedRevision] : nil
    }

    /// Whether the cloud is set up, so "Try with cloud?" can be offered as a button rather than a hint.
    var isCloudReady: Bool {
        router.cloud?.isAvailable == true
    }

    /// A new question, or a follow-up that revises the latest answer.
    func ask(_ text: String) async {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let questions = (revisions.last?.questions ?? []) + [text]
        await answer(questions, allowing: [.onDevice])
    }

    /// Re-answers the current questions with the cloud model. Only called from the student's tap.
    func tryWithCloud() async {
        guard let questions = current?.questions else { return }
        await answer(questions, allowing: [.cloud])
    }

    func startOver() {
        revisions = []
        selectedRevision = 0
        state = .idle
    }

    // MARK: Answering

    private func answer(_ questions: [String], allowing tiers: Set<AgentTier>) async {
        state = .thinking

        let query = questions.joined(separator: " ")
        let retrieved = await retrieve(query, courseID)
        let fitted = ContextBudgeter().fit(retrieved, objective: query, tokenBudget: Self.contextTokens)
        let included = fitted.includedEvidence
        let provider = router.provider(allowing: tiers)

        guard provider.tier != .none else {
            add(Self.extractive(questions: questions, sources: included, offerCloud: isCloudReady))
            return
        }

        guard !included.isEmpty else {
            add(AskRevision(questions: questions, sentences: [], sources: [], tier: provider.tier, droppedCount: 0, isExtractive: false, shouldOfferCloud: false))
            return
        }

        let prompt = AgentPrompt(
            instructions: """
            You answer a student's question about their course using only the records below. \
            Every sentence must cite the ids of the records it uses. If the records don't answer the \
            question, say so in one sentence and set confidence to low. Never make up dates or numbers.
            """,
            text: Self.promptText(questions: questions, previous: revisions.last, context: fitted.text),
            temperature: 0.2,
            courseIDs: Set(included.compactMap(\.ref.courseID))
        )

        do {
            let response = try await provider.respond(to: prompt, tools: [], generating: ModelAnswer.self)
            let claims = response.content.sentences.map { AgentClaim(text: $0.text, citations: $0.citedIDs) }
            let resolver = PassageEvidenceResolver(evidence: included, fallback: fallbackResolver)
            let gate = await EvidenceGate(evidence: included, resolver: resolver).evaluate(claims)

            let sentences = gate.verified.map { AskRevision.Sentence(text: $0.claim.text, evidence: $0.evidence) }
            let lowConfidence = response.content.confidence == "low"
            let rejected = sentences.isEmpty || gate.dropped.count > sentences.count
            add(AskRevision(
                questions: questions,
                sentences: sentences,
                sources: included,
                tier: response.tier,
                droppedCount: gate.dropped.count,
                isExtractive: false,
                // Never offered after a cloud answer: nothing further to escalate to.
                shouldOfferCloud: response.tier != .cloud && (rejected || lowConfidence)
            ))
        } catch {
            if provider.tier == .cloud {
                state = .failed(error.localizedDescription)
            } else {
                // The on-device model couldn't answer; fall back to quoting the sources.
                add(Self.extractive(questions: questions, sources: included, offerCloud: true))
            }
        }
    }

    private func add(_ revision: AskRevision) {
        revisions.append(revision)
        selectedRevision = revisions.count - 1
        state = .answered
    }

    static func promptText(questions: [String], previous: AskRevision?, context: String) -> String {
        var lines: [String] = []
        if let previous, questions.count > 1 {
            lines.append("Earlier question: \(previous.question)")
            lines.append("Current answer: \(previous.sentences.map(\.text).joined(separator: " "))")
            lines.append("Follow-up (revise the answer to cover it): \(questions.last ?? "")")
        } else {
            lines.append("Question: \(questions.last ?? "")")
        }
        lines.append("")
        lines.append("Records:")
        lines.append(context)
        return lines.joined(separator: "\n")
    }

    /// Tier 0: the best passages, quoted, so the card is useful with no model at all.
    static func extractive(questions: [String], sources: [Evidence], offerCloud: Bool) -> AskRevision {
        let sentences = sources.prefix(3).map { source in
            AskRevision.Sentence(text: source.snippet.isEmpty ? source.title : source.snippet, evidence: [source])
        }
        return AskRevision(
            questions: questions,
            sentences: Array(sentences),
            sources: sources,
            tier: .none,
            droppedCount: 0,
            isExtractive: true,
            shouldOfferCloud: offerCloud && !sources.isEmpty
        )
    }
}

/// Resolves passages to the copies retrieved this run (the index is already current) and hands
/// anything else (assignments) to `fallback`, which re-reads it from Canvas data.
@MainActor
final class PassageEvidenceResolver: EvidenceResolver {
    private let byID: [String: Evidence]
    private let fallback: (any EvidenceResolver)?

    init(evidence: [Evidence], fallback: (any EvidenceResolver)?) {
        byID = Dictionary(evidence.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.fallback = fallback
    }

    func resolve(_ ref: EvidenceRef) async -> Evidence? {
        if case .passage = ref { return byID[ref.id] }
        if let fallback { return await fallback.resolve(ref) }
        return byID[ref.id]
    }
}

// MARK: - Live retrieval

enum AskRetrieval {
    /// Hybrid search over the course index plus cached assignments whose names match, so
    /// "when is PS5 due" finds the assignment record with its real due date.
    @MainActor
    static func live(context: ModelContext? = nil) -> @MainActor (String, String?) async -> [Evidence] {
        { query, courseID in
            let context = context ?? .shared
            var evidence: [Evidence] = []

            if let indexer = SemanticIndexer.shared,
               let matches = try? await indexer.hybridSearch(query, courseID: courseID, limit: AskSessionLimits.retrieval) {
                let names = courseNames(in: context)
                evidence += matches.map { passageEvidence($0, courseName: $0.courseID.flatMap { names[$0] }) }
            }

            evidence += assignmentMatches(query, courseID: courseID, in: context)
            return evidence
        }
    }

    static func passageEvidence(_ match: SemanticIndexer.Match, courseName: String?) -> Evidence {
        Evidence(
            ref: .passage(sourceID: match.sourceID, ordinal: match.ordinal, courseID: match.courseID),
            title: match.headingPath.first ?? match.sourceID,
            snippet: match.text,
            facts: EvidenceFacts(courseName: courseName)
        )
    }

    @MainActor
    static func assignmentMatches(_ query: String, courseID: String?, in context: ModelContext, limit: Int = 3) -> [Evidence] {
        let all = (try? context.fetch(FetchDescriptor<Assignment>())) ?? []
        let assignments = courseID.map { id in all.filter { $0.courseId?.asString == id } } ?? all
        guard !assignments.isEmpty else { return [] }

        let names = courseNames(in: context)
        let index = LexicalIndex(documents: assignments.map(\.name))
        return index.rank(query).prefix(limit).map { hit in
            let assignment = assignments[hit.index]
            let course = assignment.courseId?.asString ?? ""
            return assignment.evidence(courseID: course, courseName: names[course])
        }
    }

    @MainActor
    private static func courseNames(in context: ModelContext) -> [String: String] {
        let courses = (try? context.fetch(FetchDescriptor<Course>())) ?? []
        return Dictionary(courses.map { ($0.id, $0.displayName) }, uniquingKeysWith: { first, _ in first })
    }

    /// The deep-link id that opens the record behind `evidence`, in the format
    /// `HomeView.handleSpotlightDeepLink` reads.
    static func deepLink(for evidence: Evidence) -> String? {
        switch evidence.ref {
        case let .passage(sourceID, _, _):
            guard let separator = sourceID.firstIndex(of: ":") else { return nil }
            let kind = sourceID[..<separator]
            let id = sourceID[sourceID.index(after: separator)...]
            switch kind {
            case "discussion", "announcement": return "announcement:\(id)"
            case "syllabus": return "course:\(id)"
            case "page", "assignment", "quiz", "file": return "\(kind):\(id)"
            default: return nil
            }
        case .assignment(let id, _):
            return "assignment:\(id)"
        case .announcement(let id, _):
            return "announcement:\(id)"
        case .course(let id):
            return "course:\(id)"
        case .file(let id, _):
            return "file:\(id)"
        case .toDo(let id, _):
            return "todo:\(id)"
        case .calendarEvent:
            return nil
        }
    }
}

enum AskSessionLimits {
    static let retrieval = 8
}
