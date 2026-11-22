//
//  StartMyDay.swift
//  CanvasPlusPlayground
//

import Foundation
import FoundationModels

/// The daily brief on the dashboard: a short summary and the few things that matter today.
struct DayBrief: Codable, Hashable, Sendable {
    struct Section: Codable, Hashable, Sendable, Identifiable {
        enum Kind: String, Codable, Sendable, CaseIterable {
            case overdue
            case dueToday
            case events
            case comingUp
            case graded
            case announcements

            var title: String {
                switch self {
                case .overdue: "Needs attention"
                case .dueToday: "Due today"
                case .events: "Today's events"
                case .comingUp: "Coming up"
                case .graded: "Recently graded"
                case .announcements: "New announcements"
                }
            }

            var systemImage: String {
                switch self {
                case .overdue: "exclamationmark.circle.fill"
                case .dueToday: "flag.fill"
                case .events: "calendar"
                case .comingUp: "clock"
                case .graded: "checkmark.seal.fill"
                case .announcements: "megaphone.fill"
                }
            }
        }

        let kind: Kind
        let items: [Evidence]

        var id: Kind { kind }
    }

    var generatedAt: Date
    var summary: [AssistantReply.Sentence]
    var sections: [Section]
    var tier: AgentTier
    var runID: UUID?

    var isEmpty: Bool { sections.isEmpty }
}

// MARK: - Engine

/// Builds the brief with the agent harness: one `AgentRuntime` run of
/// gather → sort → summarize → gate, with every tool and model call in the ledger.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
struct DayBriefEngine {
    static let graphName = "startMyDay.brief"
    static let maxItemsPerSection = 4

    let dataSource: any AgentDataSource
    var router = AgentModelRouter()
    var runtime: (any AgentModelProvider) -> AgentRuntime = { AgentRuntime(provider: $0) }
    var now: @Sendable () -> Date = { .now }
    var calendar: Calendar = .current

    static let recordsKey = AgentStateKey<[Evidence]>("records")
    static let sectionsKey = AgentStateKey<[DayBrief.Section]>("sections")
    static let summaryKey = AgentStateKey<[AssistantReply.Sentence]>("summary")
    static let tierKey = AgentStateKey<AgentTier>("tier")

    @Generable
    struct ModelSummary {
        @Guide(description: "One or two short, friendly sentences about the student's day, most urgent first. Each cites the ids it mentions.")
        var sentences: [ModelSentence]
    }

    @Generable
    struct ModelSentence {
        var text: String
        @Guide(description: "Ids exactly as given, like assignment:12.")
        var citedIDs: [String]
    }

    func brief() async throws -> DayBrief {
        let provider = router.provider()
        let result = try await runtime(provider).start(graph(provider: provider))
        if let budgetError = result.budgetError { throw budgetError }

        return DayBrief(
            generatedAt: now(),
            summary: result.state[Self.summaryKey] ?? [],
            sections: result.state[Self.sectionsKey] ?? [],
            tier: result.state[Self.tierKey] ?? .none,
            runID: result.runID
        )
    }

    func graph(provider: any AgentModelProvider) -> AgentGraph {
        AgentGraph(name: Self.graphName, start: "gather", nodes: [
            AgentStep("gather") { context in
                let records = await gather(in: context)
                try context.set(records, for: Self.recordsKey)
                context.note("Gathered \(records.count) records")
                return .next("sort")
            },
            AgentStep("sort") { context in
                let sections = Self.sections(from: context.value(Self.recordsKey) ?? [], now: now(), calendar: calendar)
                try context.set(sections, for: Self.sectionsKey)
                context.note(sections.map { "\($0.kind.rawValue): \($0.items.count)" }.joined(separator: ", "))
                return .next("summarize")
            },
            AgentStep("summarize") { context in
                let sections = context.value(Self.sectionsKey) ?? []
                let template = Self.templateSummary(sections)
                let shown = sections.flatMap(\.items)

                guard provider.tier != .none, !shown.isEmpty else {
                    try context.set(template, for: Self.summaryKey)
                    try context.set(AgentTier.none, for: Self.tierKey)
                    return .finish
                }

                let records = sections.map { section in
                    "\(section.kind.title):\n" + section.items.map(\.promptText).joined(separator: "\n")
                }.joined(separator: "\n\n")

                do {
                    let response = try await context.respond(
                        to: AgentPrompt(
                            instructions: """
                            You write the top of a student's daily brief. In one or two short sentences, say what matters today, \
                            most urgent first, naming items by their title, e.g. "Quiz 1 is due tomorrow, and the Essay Draft came back with 93%." \
                            Only mention items in the records. Put ids only in citedIDs, never in the text. \
                            Write dates like "tonight at 11:59 PM" or "Friday", never in ISO format. Be warm and brief.
                            """,
                            text: "Today is \(now().formatted(.dateTime.weekday(.wide).month().day())).\n\n\(records)",
                            temperature: 0.4,
                            courseIDs: Set(shown.compactMap(\.ref.courseID))
                        ),
                        generating: ModelSummary.self
                    )
                    let claims = response.content.sentences.map {
                        AgentClaim(text: AssistantEngine.readable($0.text, calendar: calendar), citations: $0.citedIDs)
                    }
                    let gate = await EvidenceGate(evidence: shown, resolver: PassageEvidenceResolver(evidence: shown, fallback: nil)).evaluate(claims)
                    let verified = gate.verified.map { AssistantReply.Sentence(text: $0.claim.text, evidenceIDs: $0.evidence.map(\.id)) }
                    if !gate.dropped.isEmpty { context.note("Gate hid \(gate.dropped.count) unsupported sentences") }

                    try context.set(verified.isEmpty ? template : verified, for: Self.summaryKey)
                    try context.set(verified.isEmpty ? AgentTier.none : response.tier, for: Self.tierKey)
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    context.note("Model failed (\(error.localizedDescription)); used the template")
                    try context.set(template, for: Self.summaryKey)
                    try context.set(AgentTier.none, for: Self.tierKey)
                }
                return .finish
            },
        ])
    }

    private func gather(in context: AgentNodeContext) async -> [Evidence] {
        let run = ToolRegistry(dataSource: dataSource, now: now)
            .makeRun(scope: [.listAssignments, .listToDos, .listCalendarEvents, .listAnnouncements])
        let tools = context.ledger?.recording(run.tools, runID: context.runID) ?? run.tools

        func call(_ name: ToolRegistry.ToolName, _ json: String) async -> [Evidence] {
            guard let tool = tools.first(where: { $0.name == name.rawValue }) else { return [] }
            return (try? await Self.invoke(tool, argumentsJSON: json)) ?? []
        }

        let upcoming = await call(.listAssignments, #"{"daysAhead": 3}"#)
        let overdue = await call(.listAssignments, #"{"onlyPastDue": true}"#)
        let graded = await call(.listAssignments, #"{"onlyGraded": true}"#)
        let todos = await call(.listToDos, #"{"daysAhead": 3}"#)
        let events = await call(.listCalendarEvents, #"{"daysAhead": 0}"#)
        let announcements = await call(.listAnnouncements, #"{"daysBack": 2}"#)

        var seen = Set<String>()
        return (overdue + upcoming + todos + events + graded + announcements).filter { seen.insert($0.id).inserted }
    }

    private static func invoke(_ tool: any Tool, argumentsJSON: String) async throws -> [Evidence] {
        try await call(tool, argumentsJSON: argumentsJSON)
    }

    private static func call<T: Tool>(_ tool: T, argumentsJSON: String) async throws -> [Evidence] {
        let output = try await tool.call(arguments: T.Arguments(GeneratedContent(json: argumentsJSON)))
        return (output as? EvidenceBundle)?.evidence ?? []
    }

    // MARK: Sorting

    /// Puts each record in one section. Pure Swift, so the brief has the same shape with or
    /// without a model.
    nonisolated static func sections(from records: [Evidence], now: Date, calendar: Calendar) -> [DayBrief.Section] {
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        let horizon = calendar.date(byAdding: .day, value: 2, to: endOfToday)!
        let finished: Set<SubmissionStatus> = [.submitted, .late, .graded, .excused]

        var buckets: [DayBrief.Section.Kind: [Evidence]] = [:]
        var titles = Set<String>()

        for record in records {
            let kind: DayBrief.Section.Kind?
            let isDone = record.facts.submissionStatus.map(finished.contains) ?? false

            switch record.ref.kind {
            case .announcement:
                kind = (record.facts.postedAt ?? .distantPast) >= now.addingTimeInterval(-36 * 3_600) ? .announcements : nil
            case .calendarEvent:
                kind = record.facts.startDate.map { $0 >= startOfToday && $0 < endOfToday } == true ? .events : nil
            default:
                if record.facts.submissionStatus == .graded, let graded = record.facts.gradedAt, graded >= now.addingTimeInterval(-48 * 3_600) {
                    kind = .graded
                } else if let due = record.facts.dueDate, !isDone {
                    if due < now && due >= now.addingTimeInterval(-7 * 86_400) {
                        kind = .overdue
                    } else if due >= now && due < endOfToday {
                        kind = .dueToday
                    } else if due >= endOfToday && due < horizon {
                        kind = .comingUp
                    } else {
                        kind = nil
                    }
                } else {
                    kind = nil
                }
            }

            // To-dos and assignments often describe the same work; keep one.
            guard let kind, titles.insert(record.title.lowercased()).inserted else { continue }
            buckets[kind, default: []].append(record)
        }

        return DayBrief.Section.Kind.allCases.compactMap { kind in
            guard let items = buckets[kind], !items.isEmpty else { return nil }
            let sorted = items.sorted { ($0.primaryDate ?? .distantFuture) < ($1.primaryDate ?? .distantFuture) }
            let ordered = kind == .graded || kind == .announcements ? sorted.reversed() : sorted
            return DayBrief.Section(kind: kind, items: Array(ordered.prefix(maxItemsPerSection)))
        }
    }

    nonisolated static func templateSummary(_ sections: [DayBrief.Section]) -> [AssistantReply.Sentence] {
        func count(_ kind: DayBrief.Section.Kind) -> Int { sections.first { $0.kind == kind }?.items.count ?? 0 }
        let ids = sections.flatMap(\.items).prefix(6).map(\.id)

        var parts: [String] = []
        if count(.dueToday) > 0 { parts.append("\(count(.dueToday)) due today") }
        if count(.overdue) > 0 { parts.append("\(count(.overdue)) past due") }
        if count(.events) > 0 { parts.append("\(count(.events)) event\(count(.events) == 1 ? "" : "s") today") }
        if count(.comingUp) > 0 { parts.append("\(count(.comingUp)) coming up in the next two days") }

        guard !parts.isEmpty else {
            return [.init(text: sections.isEmpty ? "Nothing due today. Enjoy the breathing room." : "Nothing due today; here's what's new.", evidenceIDs: Array(ids))]
        }
        return [.init(text: "You have \(ListFormatter.localizedString(byJoining: parts)).", evidenceIDs: Array(ids))]
    }
}

// MARK: - Schedule

/// When the brief refreshes: once a day at a time the student picks (10:00 AM by default).
struct DayBriefSchedule: Sendable {
    static let defaultHour = 10
    static let defaultMinute = 0

    private enum Key {
        static let hour = "startMyDay.refreshHour"
        static let minute = "startMyDay.refreshMinute"
    }

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hour: Int {
        get { defaults.object(forKey: Key.hour) as? Int ?? Self.defaultHour }
        nonmutating set { defaults.set(newValue, forKey: Key.hour) }
    }

    var minute: Int {
        get { defaults.object(forKey: Key.minute) as? Int ?? Self.defaultMinute }
        nonmutating set { defaults.set(newValue, forKey: Key.minute) }
    }

    /// Today's refresh time.
    func refreshTime(on day: Date, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    /// The most recent refresh time at or before `now`: today's if it has passed, else yesterday's.
    func latestRefresh(before now: Date, calendar: Calendar = .current) -> Date {
        let today = refreshTime(on: now, calendar: calendar)
        return today <= now ? today : calendar.date(byAdding: .day, value: -1, to: today)!
    }

    /// The next refresh time after `now`.
    func nextRefresh(after now: Date, calendar: Calendar = .current) -> Date {
        let today = refreshTime(on: now, calendar: calendar)
        return today > now ? today : calendar.date(byAdding: .day, value: 1, to: today)!
    }

    /// A brief is stale once a refresh time has passed since it was made. With no brief yet,
    /// make one now rather than wait for the next refresh time.
    func isDue(lastGenerated: Date?, now: Date, calendar: Calendar = .current) -> Bool {
        guard let lastGenerated else { return true }
        return lastGenerated < latestRefresh(before: now, calendar: calendar)
    }
}

// MARK: - Store

struct DayBriefStore: Sendable {
    let url: URL

    static let `default` = DayBriefStore(url: URL.applicationSupportDirectory.appending(path: "day-brief.json"))

    func load() -> DayBrief? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(DayBrief.self, from: data)
    }

    func save(_ brief: DayBrief) {
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(brief).write(to: url, options: .atomic)
    }
}
