//
//  AssistantEngine.swift
//  CanvasPlusPlayground
//

import Foundation
import FoundationModels
import SwiftData

// MARK: - Reply

/// What the assistant shows for one question: a few verified sentences, then records drawn the
/// same way every time (the block), then follow-up questions.
///
/// Sentences come from the model (or Swift templates without one) and pass the EvidenceGate.
/// The block is built in Swift from evidence the tools returned, so every answer about
/// assignments, the week or grades looks the same no matter how the model phrased it.
struct AssistantReply: Codable, Hashable, Sendable {
    struct Sentence: Codable, Hashable, Sendable {
        let text: String
        let evidenceIDs: [String]
    }

    enum Block: Codable, Hashable, Sendable {
        /// Rows of records, e.g. graded assignments with their scores.
        case records([Evidence])
        /// The days ahead, each with its items in time order.
        case week([Day])
        /// One course's grade, overall and by assignment group.
        case grade(courseName: String, overall: Double?, groups: [Evidence])
    }

    struct Day: Codable, Hashable, Sendable {
        let date: Date
        let items: [Evidence]
    }

    var sentences: [Sentence]
    var block: Block?
    var followUps: [String]
    /// Every record this answer was built from, for "show your work".
    var evidence: [Evidence]
    var tier: AgentTier
    var runID: UUID?
    /// The on-device answer didn't hold up; the student can choose to try the cloud.
    var canTryCloud = false
    /// Sentences the gate hid because their citations didn't check out.
    var droppedCount = 0
    /// Shown instead of an answer when the records don't answer the question, e.g. the model's
    /// "Your course calendars don't list class times." Never carries facts, so it needs no citation.
    var note: String?

    var isEmpty: Bool { sentences.isEmpty && block == nil && note == nil }
}

extension AgentTier: Codable {}

// MARK: - Intent

/// What a question is about. Swift decides this before any model runs, and it decides which tools
/// run and how the answer is drawn.
enum AssistantIntent: String, Codable, Sendable, CaseIterable {
    /// "What assignments have been graded?"
    case graded
    /// "What's my grade in CS 1332?"
    case grade
    /// "What classes do I have today?", "What's due today?"
    case today
    /// "What does my next week look like?"
    case week
    /// "Did anything change in my courses?"
    case changes
    /// "Any new announcements?"
    case announcements
    /// "What should I do first?"
    case urgent
    /// "Am I missing any work?"
    case missing
    /// Anything else: searched in course content and records.
    case general

    static func classify(_ question: String) -> AssistantIntent {
        let text = question.lowercased()
        func has(_ words: String...) -> Bool { words.contains(where: text.contains) }

        if has("graded", "grades posted", "got back", "scored") { return .graded }
        if has("my grade", "overall grade", "grade in", "what grade", "current grade", "my score in") { return .grade }
        if has("missing", "overdue", "late work", "forgot", "behind") { return .missing }
        if has("urgent", "priorit", "first", "to-do", "todo", "to do") { return .urgent }
        if has("announcement", "unread", "inbox", "e-mail", "email", "message") { return .announcements }
        if has("change", "anything new", "what's new", "whats new", "updated", "update") { return .changes }
        if has("today", "tonight", "class", "lecture", "my day", "right now") { return .today }
        if has("week", "upcoming", "coming up", "schedule", "calendar", "due soon", "exam", "plan") { return .week }
        return .general
    }

    /// The tools this kind of question needs. Fewer tools means a shorter prompt.
    @available(iOS 26.0, macOS 26.0, *)
    var scope: ToolRegistry.Scope {
        switch self {
        case .graded, .missing, .grade: [.listAssignments]
        case .week: [.listAssignments, .listCalendarEvents]
        case .today: [.listCalendarEvents, .listAssignments, .listToDos]
        case .changes: [.listAnnouncements, .listAssignments]
        case .announcements: [.listAnnouncements]
        case .urgent: [.listToDos, .listAssignments]
        case .general: [.listAssignments, .listAnnouncements]
        }
    }

    /// What the thinking indicator says while the tools run.
    var workingLabel: String {
        switch self {
        case .graded: "Checking your graded work"
        case .grade: "Adding up your grade"
        case .today: "Looking at today"
        case .week: "Looking at your week"
        case .changes: "Looking for what changed"
        case .announcements: "Reading announcements"
        case .urgent: "Sorting by what's due first"
        case .missing: "Checking for missing work"
        case .general: "Searching your courses"
        }
    }
}

// MARK: - Engine

/// Answers one question with the agent harness: an `AgentRuntime` run of a six-step graph
/// (plan → gather → budget → compose → gate → emit) with checkpoints, budgets and a ledger entry
/// for every tool and model call. Tools come from the `ToolRegistry` scoped to the question.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
struct AssistantEngine {
    static let graphName = "assistant.answer"
    static let contextTokens = 2_000

    let dataSource: any AgentDataSource
    /// Passages from the course index, for general questions. Tests pass a fake.
    var retrievePassages: @MainActor (_ query: String, _ courseID: String?) async -> [Evidence] = { query, courseID in
        await AskRetrieval.live()(query, courseID)
    }
    /// Assignment groups with the student's scores, for grade questions.
    var gradeGroups: @MainActor (_ courseID: String) async -> [GradeGroupScore] = { courseID in
        await GradeGroupScore.load(courseID: courseID)
    }
    var router = AgentModelRouter()
    /// Cloud runs get more time and context than on-device ones.
    var runtime: (any AgentModelProvider) -> AgentRuntime = { AgentRuntime(provider: $0, budget: $0.tier == .cloud ? .cloud : .onDevice) }
    var now: @Sendable () -> Date = { .now }
    var calendar: Calendar = .current

    // Run state keys.
    static let questionKey = AgentStateKey<String>("question")
    static let historyKey = AgentStateKey<[String]>("history")
    static let contextKey = AgentStateKey<AssistantPageContext>("page")
    static let intentKey = AgentStateKey<AssistantIntent>("intent")
    static let evidenceKey = AgentStateKey<[Evidence]>("evidence")
    static let overallKey = AgentStateKey<Double>("overall")
    static let promptKey = AgentStateKey<String>("prompt")
    static let draftKey = AgentStateKey<Draft>("draft")
    static let replyKey = AgentStateKey<AssistantReply>("reply")

    /// The model's (or the template's) answer before the gate.
    struct Draft: Codable, Hashable, Sendable {
        var sentences: [AssistantReply.Sentence]
        var highlightIDs: [String]
        var followUps: [String]
        var lowConfidence: Bool
        var tier: AgentTier
        /// The model's own "I couldn't find that" sentence, when it cited nothing.
        var note: String? = nil
    }

    @Generable
    struct ModelAnswer {
        @Guide(description: "One to three short sentences answering the question. Each cites the ids of the records it uses.")
        var sentences: [ModelSentence]
        @Guide(description: "Ids of the records to show the student under the answer, most relevant first. At most 6.")
        var showIDs: [String]
        @Guide(description: "Two short follow-up questions the student might ask next, under 8 words each.")
        var followUps: [String]
        @Guide(description: "How well the records answer the question.", .anyOf(["high", "medium", "low"]))
        var confidence: String
    }

    @Generable
    struct ModelSentence {
        var text: String
        @Guide(description: "Ids exactly as given, like assignment:12 or passage:page:7#0.")
        var citedIDs: [String]
    }

    /// Answers `question`. `history` is earlier questions in the same chat, for follow-ups.
    /// `tiers` is `[.onDevice]` normally and `[.cloud]` only after the student taps "Try with cloud".
    func answer(
        _ question: String,
        history: [String] = [],
        context: AssistantPageContext,
        allowing tiers: Set<AgentTier> = [.onDevice]
    ) async throws -> AssistantReply {
        let provider = router.provider(allowing: tiers)
        var input = AgentRunState()
        try input.set(question, for: Self.questionKey)
        try input.set(history, for: Self.historyKey)
        try input.set(context, for: Self.contextKey)

        let result = try await runtime(provider).start(graph(provider: provider), state: input)
        if let budgetError = result.budgetError { throw budgetError }

        var reply = result.state[Self.replyKey] ?? AssistantReply(sentences: [], block: nil, followUps: [], evidence: [], tier: .none)
        reply.runID = result.runID
        return reply
    }

    // MARK: Graph

    func graph(provider: any AgentModelProvider) -> AgentGraph {
        AgentGraph(name: Self.graphName, start: "plan", nodes: [
            AgentStep("plan") { context in
                let question = context.value(Self.questionKey) ?? ""
                let intent = AssistantIntent.classify(question)
                try context.set(intent, for: Self.intentKey)
                context.note("Intent: \(intent.rawValue); tools: \(intent.scope.tools.map(\.rawValue).sorted().joined(separator: ", "))")
                return .next("gather")
            },
            AgentStep("gather") { context in
                let intent = context.value(Self.intentKey) ?? .general
                let page = context.value(Self.contextKey)
                let question = context.value(Self.questionKey) ?? ""
                let evidence = try await gather(intent: intent, question: question, page: page, in: context)
                try context.set(evidence, for: Self.evidenceKey)
                context.note("Gathered \(evidence.count) records")
                return .next("budget")
            },
            AgentStep("budget") { context in
                let evidence = context.value(Self.evidenceKey) ?? []
                let question = context.value(Self.questionKey) ?? ""
                let fitted = ContextBudgeter().fit(evidence, objective: question, tokenBudget: min(Self.contextTokens, context.promptTokenAllowance))
                try context.set(fitted.text, for: Self.promptKey)
                try context.set(fitted.includedEvidence, for: Self.evidenceKey)
                context.note("Kept \(fitted.includedEvidence.count) of \(evidence.count) records for the prompt")
                return .next("compose")
            },
            AgentStep("compose") { context in
                let draft = try await compose(in: context, provider: provider)
                try context.set(draft, for: Self.draftKey)
                return .next("gate")
            },
            AgentStep("gate") { context in
                guard var draft = context.value(Self.draftKey) else { return .next("emit") }
                let evidence = context.value(Self.evidenceKey) ?? []
                let claims = draft.sentences.map { AgentClaim(text: $0.text, citations: $0.evidenceIDs) }
                let resolver = PassageEvidenceResolver(evidence: evidence, fallback: nil)
                let result = await EvidenceGate(evidence: evidence, resolver: resolver).evaluate(claims)

                let dropped = result.dropped.count
                draft.sentences = result.verified.map { .init(text: $0.claim.text, evidenceIDs: $0.evidence.map(\.id)) }
                try context.set(draft, for: Self.draftKey)
                try context.set(dropped, for: AgentStateKey<Int>("dropped"))
                if dropped > 0 { context.note("Gate hid \(dropped) unsupported sentence\(dropped == 1 ? "" : "s")") }
                return .next("emit")
            },
            AgentStep("emit") { context in
                let reply = emit(in: context)
                try context.set(reply, for: Self.replyKey)
                return .finish
            },
        ])
    }

    // MARK: Gather

    private func gather(intent: AssistantIntent, question: String, page: AssistantPageContext?, in context: AgentNodeContext) async throws -> [Evidence] {
        let courseID = await courseID(mentionedIn: question) ?? page?.courseID
        let course = try await courseArgument(courseID)
        let run = ToolRegistry(dataSource: dataSource, now: now).makeRun(scope: intent.scope)
        // Calls go through the ledger, so the run trace shows every tool and what it returned.
        let tools = context.ledger?.recording(run.tools, runID: context.runID) ?? run.tools

        func call(_ name: ToolRegistry.ToolName, _ json: String) async -> [Evidence] {
            guard let tool = tools.first(where: { $0.name == name.rawValue }) else { return [] }
            return (try? await Self.invoke(tool, argumentsJSON: json)) ?? []
        }

        switch intent {
        case .graded:
            return await call(.listAssignments, #"{"course": \#(course), "onlyGraded": true}"#)

        case .missing:
            return await call(.listAssignments, #"{"course": \#(course), "onlyPastDue": true}"#)

        case .week:
            let assignments = await call(.listAssignments, #"{"course": \#(course), "daysAhead": 7}"#)
            let events = await call(.listCalendarEvents, #"{"course": \#(course), "daysAhead": 7}"#)
            return (assignments + events).sorted { ($0.primaryDate ?? .distantFuture) < ($1.primaryDate ?? .distantFuture) }

        case .today:
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now()))!
            let events = await call(.listCalendarEvents, #"{"course": \#(course), "daysAhead": 0}"#)
            let due = await call(.listAssignments, #"{"course": \#(course), "daysAhead": 1}"#)
            let todos = await call(.listToDos, #"{"daysAhead": 1}"#)
            var seen = Set<String>()
            let dueToday = (due + todos).filter { item in
                guard let date = item.facts.dueDate else { return false }
                return date >= now() && date < endOfToday && seen.insert(item.title.lowercased()).inserted
            }
            return (events + dueToday).sorted { ($0.primaryDate ?? .distantFuture) < ($1.primaryDate ?? .distantFuture) }

        case .changes:
            let announcements = await call(.listAnnouncements, #"{"course": \#(course), "daysBack": 7}"#)
            let graded = await call(.listAssignments, #"{"course": \#(course), "onlyGraded": true}"#)
                .filter { ($0.facts.gradedAt ?? .distantPast) > now().addingTimeInterval(-7 * 86_400) }
            return announcements + graded

        case .announcements:
            return await call(.listAnnouncements, #"{"course": \#(course), "daysBack": 14}"#)

        case .urgent:
            let todos = await call(.listToDos, #"{"daysAhead": 3}"#)
            let assignments = await call(.listAssignments, #"{"course": \#(course), "daysAhead": 3, "includePastDue": true}"#)
            var seen = Set<String>()
            return (todos + assignments)
                .filter { seen.insert($0.title.lowercased()).inserted }
                .sorted { ($0.facts.dueDate ?? .distantFuture) < ($1.facts.dueDate ?? .distantFuture) }

        case .grade:
            guard let courseID else {
                // No course in the question or on screen: every course's current grade.
                let courses = (try? await dataSource.courses()) ?? []
                var rows: [Evidence] = []
                for course in courses {
                    let groups = await gradeGroups(course.ref.recordID)
                    guard let overall = GradeGroupScore.overall(groups) else { continue }
                    rows.append(Evidence(
                        ref: course.ref,
                        title: course.title,
                        snippet: "Current grade \(overall.formatted(.number.precision(.fractionLength(0...1))))%",
                        facts: EvidenceFacts(courseName: course.title, pointsPossible: 100, score: overall)
                    ))
                }
                context.note("Computed current grades for \(rows.count) of \(courses.count) courses")
                return rows
            }
            let groups = await gradeGroups(courseID)
            let evidence = groups.map(\.evidence)
            if let overall = GradeGroupScore.overall(groups) { try context.set(overall, for: Self.overallKey) }
            context.note("Computed \(groups.count) group totals")
            return evidence

        case .general:
            // Search finds the closest passages even when nothing is relevant ("welcome" pages for
            // "what classes do I have"), so keep only records that share a real word with the question.
            let terms = Self.significantTerms(in: question)
            let passages = await retrievePassages(question, courseID).filter { Self.mentions($0, anyOf: terms) }
            let assignments = await call(.listAssignments, #"{"course": \#(course), "includePastDue": true, "includeCompleted": true}"#)
            let named = assignments.filter { Self.mentions($0, anyOf: terms, titleOnly: true) }.prefix(3)
            context.note("Kept \(named.count) assignments and \(passages.count) passages that mention: \(terms.sorted().joined(separator: ", "))")
            return Array(named) + passages
        }
    }

    /// Words that say what a question is about, without question words or filler.
    nonisolated static func significantTerms(in question: String) -> Set<String> {
        let filler: Set<String> = [
            "what", "when", "where", "which", "who", "how", "why", "do", "does", "did", "is", "are", "was", "be",
            "i", "me", "my", "you", "your", "we", "it", "this", "that", "there", "have", "has", "had", "can", "could",
            "will", "would", "should", "about", "any", "get", "got", "tell", "show", "know", "need", "want", "the",
            "a", "an", "of", "to", "in", "on", "for", "at", "and", "or", "with", "today", "class", "classes", "course", "courses",
        ]
        return Set(LexicalIndex.tokens(in: question).filter { !filler.contains($0) && $0.count > 1 })
    }

    nonisolated static func mentions(_ evidence: Evidence, anyOf terms: Set<String>, titleOnly: Bool = false) -> Bool {
        guard !terms.isEmpty else { return false }
        let text = titleOnly ? evidence.title : evidence.title + " " + evidence.snippet
        return !Set(LexicalIndex.tokens(in: text)).isDisjoint(with: terms)
    }

    /// The JSON value for a tool's `course` argument.
    private func courseArgument(_ courseID: String?) async throws -> String {
        guard let courseID else { return "null" }
        return "\"\(courseID)\""
    }

    /// A course named in the question ("CS 1332", "data structures"), by code or name.
    private func courseID(mentionedIn question: String) async -> String? {
        guard let courses = try? await dataSource.courses() else { return nil }
        let words = Set(LexicalIndex.tokens(in: question))
        return courses.first { course in
            let codeWords = Set(LexicalIndex.tokens(in: course.snippet + " " + course.title))
            let numbers = codeWords.filter { $0.allSatisfy(\.isNumber) && $0.count >= 4 }
            return !numbers.isEmpty && !numbers.isDisjoint(with: words)
        }?.ref.recordID
    }

    private static func invoke(_ tool: any Tool, argumentsJSON: String) async throws -> [Evidence] {
        try await call(tool, argumentsJSON: argumentsJSON)
    }

    private static func call<T: Tool>(_ tool: T, argumentsJSON: String) async throws -> [Evidence] {
        let output = try await tool.call(arguments: T.Arguments(GeneratedContent(json: argumentsJSON)))
        return (output as? EvidenceBundle)?.evidence ?? []
    }



    // MARK: Compose

    private func compose(in context: AgentNodeContext, provider: any AgentModelProvider) async throws -> Draft {
        let intent = context.value(Self.intentKey) ?? .general
        let evidence = context.value(Self.evidenceKey) ?? []
        let question = context.value(Self.questionKey) ?? ""
        let template = Self.template(intent: intent, evidence: evidence, overall: context.value(Self.overallKey), now: now(), calendar: calendar)

        guard provider.tier != .none, !evidence.isEmpty else {
            context.note("No model: answered from a template")
            return template
        }

        let history = context.value(Self.historyKey) ?? []
        let prompt = AgentPrompt(
            instructions: """
            You are a helpful assistant inside a student's course app. Answer using only the records given. \
            The records you pick in showIDs are shown as a list under your answer, so don't list them one by one: \
            summarize in one or two short sentences, like "There are 2 assignments and 1 exam next week." \
            Put record ids only in citedIDs and showIDs, never in the sentence text. Write dates the way a person would, \
            like "Friday at 11:59 PM", never in ISO format. Never invent dates, scores or items. \
            If the records don't answer the question, say so and set confidence to low.
            """,
            text: (history.isEmpty ? "" : "Earlier in this chat: \(history.joined(separator: " / "))\n")
                + "Question: \(question)\n\nRecords:\n\(context.value(Self.promptKey) ?? "")",
            temperature: 0.2,
            courseIDs: Set(evidence.compactMap(\.ref.courseID))
        )

        do {
            let response = try await context.respond(to: prompt, generating: ModelAnswer.self)
            let known = Set(evidence.map(\.id))
            let shown = response.content.showIDs.filter(known.contains)
            let sentences = response.content.sentences
                .map { AssistantReply.Sentence(text: Self.readable($0.text, calendar: calendar), evidenceIDs: $0.citedIDs) }
                .filter { !$0.text.isEmpty }
            let lowConfidence = response.content.confidence == "low"

            // "The records don't say" with no citations is an honest answer, not a made-up claim:
            // show it as a note instead of letting the gate hide it.
            if lowConfidence, sentences.allSatisfy(\.evidenceIDs.isEmpty), let first = sentences.first {
                context.note("Model found no answer in the records")
                return Draft(sentences: [], highlightIDs: [], followUps: Self.cleanFollowUps(response.content.followUps, fallback: template.followUps), lowConfidence: true, tier: response.tier, note: first.text)
            }

            return Draft(
                sentences: sentences,
                highlightIDs: shown.isEmpty ? template.highlightIDs : shown,
                followUps: Self.cleanFollowUps(response.content.followUps, fallback: template.followUps),
                lowConfidence: lowConfidence,
                tier: response.tier
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            context.note("Model failed (\(error.localizedDescription)); answered from a template")
            return template
        }
    }

    /// The no-model answer: a sentence in the design's voice and the records that back it.
    nonisolated static func template(intent: AssistantIntent, evidence: [Evidence], overall: Double?, now: Date, calendar: Calendar) -> Draft {
        let ids = evidence.prefix(6).map(\.id)
        func sentence(_ text: String, _ cited: [String] = ids) -> [AssistantReply.Sentence] {
            [.init(text: text, evidenceIDs: Array(cited.prefix(6)))]
        }
        let empty = evidence.isEmpty
        let sentences: [AssistantReply.Sentence]

        switch intent {
        case .graded:
            sentences = empty ? [] : sentence("Here are your most recent assignments that have been graded.")
        case .missing:
            sentences = empty ? [] : sentence("You have \(evidence.count) past-due \(evidence.count == 1 ? "item" : "items") without a submission.")
        case .today:
            let events = evidence.filter { $0.ref.kind == .calendarEvent }
            let due = evidence.count - events.count
            var parts: [String] = []
            if !events.isEmpty { parts.append("\(events.count) event\(events.count == 1 ? "" : "s") on your course calendars") }
            if due > 0 { parts.append("\(due) \(due == 1 ? "item" : "items") due") }
            sentences = empty ? [] : sentence("Today you have \(ListFormatter.localizedString(byJoining: parts)).")
        case .week:
            let exams = evidence.filter { WeekLayout.isExam($0) }.count
            let assignments = evidence.filter { $0.ref.kind == .assignment }.count
            let events = evidence.count - assignments
            var parts: [String] = []
            if exams > 0 { parts.append("\(exams) exam\(exams == 1 ? "" : "s")") }
            if events - exams > 0 { parts.append("\(events - exams) event\(events - exams == 1 ? "" : "s")") }
            if assignments > 0 { parts.append("\(assignments) assignment\(assignments == 1 ? "" : "s")") }
            sentences = empty ? [] : sentence("There \(evidence.count == 1 ? "is" : "are") \(ListFormatter.localizedString(byJoining: parts)) in the next week.")
        case .changes:
            sentences = empty ? [] : sentence("Here's what's new in your courses this week.")
        case .announcements:
            sentences = empty ? [] : sentence("Here are the latest announcements.")
        case .urgent:
            sentences = empty ? [] : sentence("These are due soonest.")
        case .grade where evidence.first?.ref.kind == .course:
            sentences = empty ? [] : sentence("Here are your current grades, from graded work so far.")
        case .grade:
            if let overall, !empty {
                sentences = sentence("You currently have \(overall.formatted(.number.precision(.fractionLength(0...1))))% in this course. Here's a breakdown of your grade.")
            } else {
                sentences = empty ? [] : sentence("Here's a breakdown of your grade.")
            }
        case .general:
            if let first = evidence.first {
                if first.ref.kind == .assignment, let due = first.facts.dueDate {
                    sentences = sentence("\(first.title) is due \(due.formatted(.dateTime.weekday(.wide).month().day().hour().minute())).", [first.id])
                } else {
                    sentences = sentence("Here's what I found in your courses.")
                }
            } else {
                sentences = []
            }
        }

        let note: String? = switch intent {
        case .today where empty:
            "There's nothing on your course calendars or due today. Canvas doesn't list regular class meeting times, so lectures won't show up here."
        case _ where empty:
            "I couldn't find that in your synced courses."
        default:
            nil
        }

        return Draft(
            sentences: sentences,
            highlightIDs: ids,
            followUps: AssistantSuggestions.followUps(after: intent),
            lowConfidence: empty,
            tier: .none,
            note: note
        )
    }

    /// Model text made fit to show: record ids removed and ISO dates written out, in case the
    /// model copied them from the records despite the instructions.
    nonisolated static func readable(_ text: String, calendar: Calendar) -> String {
        var result = text
        // "(assignment:2)", "[passage:page:7#0]", "(assignment:2, event:x)"
        result = result.replacingOccurrences(of: #"\s*[\(\[]\s*(?:[a-z]+:[^\s,\)\]]+(?:,\s*)?)+[\)\]]"#, with: "", options: .regularExpression)

        let iso = try! NSRegularExpression(pattern: #"\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}(?::\d{2})?(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?)?"#)
        for match in iso.matches(in: result, range: NSRange(result.startIndex..., in: result)).reversed() {
            guard let range = Range(match.range, in: result) else { continue }
            let raw = String(result[range])
            let formatter = ISO8601DateFormatter()
            var date: Date?
            for options: ISO8601DateFormatter.Options in [[.withInternetDateTime], [.withInternetDateTime, .withFractionalSeconds], [.withFullDate]] {
                formatter.formatOptions = options
                if let parsed = formatter.date(from: raw) { date = parsed; break }
            }
            guard let date else { continue }
            let hasTime = raw.contains("T")
            let style = Date.FormatStyle(timeZone: calendar.timeZone).weekday(.wide).month(.abbreviated).day()
            result.replaceSubrange(range, with: hasTime
                ? date.formatted(style.hour().minute())
                : date.formatted(style))
        }

        return result
            // A removed id can leave a dangling dash: "due soon— is" → "due soon is".
            .replacingOccurrences(of: #"\s*(?:[—–]\s*)+(?=[a-z])"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s*(?:[—–]\s*)+(?=[.,;!?]|$)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+([.,;!?])"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanFollowUps(_ followUps: [String], fallback: [String]) -> [String] {
        let cleaned = followUps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count <= 60 }
        return Array((cleaned.isEmpty ? fallback : cleaned).prefix(3))
    }

    // MARK: Emit

    private func emit(in context: AgentNodeContext) -> AssistantReply {
        let intent = context.value(Self.intentKey) ?? .general
        let evidence = context.value(Self.evidenceKey) ?? []
        let draft = context.value(Self.draftKey) ?? Self.template(intent: intent, evidence: [], overall: nil, now: now(), calendar: calendar)
        let dropped = context.value(AgentStateKey<Int>("dropped")) ?? 0
        let byID = Dictionary(evidence.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let highlighted = draft.highlightIDs.compactMap { byID[$0] }

        let block: AssistantReply.Block?
        switch intent {
        case .week, .today:
            block = evidence.isEmpty ? nil : .week(WeekLayout.days(evidence, from: now(), calendar: calendar))
        case .general:
            // Only what a verified sentence relies on: retrieved-but-unused passages aren't an answer.
            let cited = Set(draft.sentences.flatMap(\.evidenceIDs))
            let rows = evidence.filter { cited.contains($0.id) }
            block = rows.isEmpty ? nil : .records(Array(rows.prefix(6)))
        case .grade where evidence.first?.ref.kind == .course:
            block = evidence.isEmpty ? nil : .records(evidence)
        case .grade:
            let courseName = evidence.first?.facts.courseName ?? "This course"
            block = evidence.isEmpty ? nil : .grade(courseName: courseName, overall: context.value(Self.overallKey), groups: evidence)
        default:
            block = highlighted.isEmpty ? nil : .records(Array(highlighted.prefix(6)))
        }

        let rejected = draft.sentences.isEmpty || dropped > draft.sentences.count || draft.lowConfidence
        let note = draft.note ?? (draft.sentences.isEmpty && block == nil
            ? Self.template(intent: intent, evidence: [], overall: nil, now: now(), calendar: calendar).note
            : nil)
        return AssistantReply(
            sentences: draft.sentences,
            block: block,
            followUps: draft.followUps,
            evidence: evidence,
            tier: draft.tier,
            // Cloud only helps when there's something to read; it can't find what isn't synced.
            canTryCloud: draft.tier != .cloud && rejected && !evidence.isEmpty,
            droppedCount: dropped,
            note: note
        )
    }
}

extension Evidence {
    /// When it happens: due date, else start, else when it was posted.
    var primaryDate: Date? {
        facts.dueDate ?? facts.startDate ?? facts.postedAt
    }
}

// MARK: - Week layout

enum WeekLayout {
    static func isExam(_ evidence: Evidence) -> Bool {
        let title = evidence.title.lowercased()
        return ["exam", "midterm", "final", "quiz", "test"].contains(where: title.contains)
    }

    /// The next seven days that have something on them, items in time order.
    static func days(_ evidence: [Evidence], from start: Date, calendar: Calendar) -> [AssistantReply.Day] {
        let first = calendar.startOfDay(for: start)
        let grouped = Dictionary(grouping: evidence.compactMap { item -> (Date, Evidence)? in
            guard let date = item.primaryDate else { return nil }
            return (calendar.startOfDay(for: date), item)
        }, by: \.0)

        return grouped.keys
            .filter { $0 >= first && $0 < calendar.date(byAdding: .day, value: 8, to: first)! }
            .sorted()
            .map { day in
                AssistantReply.Day(
                    date: day,
                    items: grouped[day]!.map(\.1).sorted { ($0.primaryDate ?? day) < ($1.primaryDate ?? day) }
                )
            }
    }
}

// MARK: - Grades

/// The student's score in one assignment group, from graded submissions.
struct GradeGroupScore: Hashable, Sendable {
    let id: String
    let courseID: String
    let courseName: String
    let name: String
    /// Share of the final grade, when the course weights its groups.
    let weight: Double?
    let earned: Double
    let possible: Double

    var percent: Double? { possible > 0 ? earned / possible * 100 : nil }

    var evidence: Evidence {
        Evidence(
            ref: .assignmentGroup(id: id, courseID: courseID),
            title: name,
            snippet: percent.map { "\($0.formatted(.number.precision(.fractionLength(0...1))))% so far" } ?? "No graded work yet",
            facts: EvidenceFacts(courseName: courseName, pointsPossible: possible, score: percent, weight: weight)
        )
    }

    /// The overall percentage: weighted by group when the course weights groups, else by points.
    static func overall(_ groups: [GradeGroupScore]) -> Double? {
        let graded = groups.filter { $0.possible > 0 }
        guard !graded.isEmpty else { return nil }

        let weighted = graded.filter { ($0.weight ?? 0) > 0 }
        if !weighted.isEmpty {
            let totalWeight = weighted.compactMap(\.weight).reduce(0, +)
            return weighted.reduce(0) { $0 + ($1.percent ?? 0) * ($1.weight ?? 0) } / totalWeight
        }
        let earned = graded.reduce(0) { $0 + $1.earned }
        let possible = graded.reduce(0) { $0 + $1.possible }
        return earned / possible * 100
    }

    @MainActor
    static func load(courseID: String) async -> [GradeGroupScore] {
        let groups: [AssignmentGroup]
        if AppEnvironment.isSandbox {
            groups = SandboxData.dummyAssignmentGroups(forCourseID: courseID)
        } else {
            let request = CanvasRequest.getAssignmentGroups(courseId: courseID)
            if let cached = try? await CanvasService.shared.load(request), !cached.isEmpty {
                groups = cached
            } else {
                groups = (try? await CanvasService.shared.syncWithAPI(request)) ?? []
            }
        }

        let courseName = (try? ModelContext.shared.fetch(FetchDescriptor<Course>(predicate: #Predicate { $0.id == courseID })).first?.displayName) ?? "Course"
        return groups.sorted { $0.position < $1.position }.map { group in
            let graded = (group.assignments ?? []).filter { $0.submission?.score != nil && $0.points_possible != nil }
            return GradeGroupScore(
                id: group.id,
                courseID: courseID,
                courseName: courseName,
                name: group.name,
                weight: group.groupWeight,
                earned: graded.compactMap { $0.submission?.score }.reduce(0, +),
                possible: graded.compactMap(\.points_possible).reduce(0, +)
            )
        }
    }
}
