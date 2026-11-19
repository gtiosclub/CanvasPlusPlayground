//
//  ExamDatesView.swift
//  CanvasPlusPlayground
//

import CryptoKit
import SwiftUI

/// Scans a course's syllabus for exam dates, caches what it found per course, and remembers
/// which syllabus version it scanned so the review screen can offer a re-scan when it changes.
@MainActor
@Observable
final class ExamDateScanner {
    struct Scan: Codable, Equatable {
        var courseID: String
        var syllabusHash: String
        var scannedAt: Date
        var usedModel: Bool
        var candidates: [ExamDateCandidate]
        /// Ids the student added or dismissed, so a re-scan doesn't bring them back.
        var handledIDs: Set<UUID> = []
    }

    enum State: Equatable {
        case idle
        case scanning
        case done
        case noSyllabus
        case failed(String)
    }

    private(set) var state = State.idle
    private(set) var scan: Scan?

    private let course: Course
    private let store: ExamDateScanStore

    init(course: Course, store: ExamDateScanStore = .default) {
        self.course = course
        self.store = store
        scan = store.load(courseID: course.id)
        if scan != nil { state = .done }
    }

    var syllabusHash: String {
        Self.hash(course.syllabusBody ?? "")
    }

    /// The saved scan was made from an older version of the syllabus.
    var isStale: Bool {
        guard let scan else { return false }
        return scan.syllabusHash != syllabusHash
    }

    var pending: [ExamDateCandidate] {
        guard let scan else { return [] }
        return scan.candidates.filter { !scan.handledIDs.contains($0.id) }
    }

    func scanSyllabus(existing: [(title: String, date: Date)]) async {
        guard let html = course.syllabusBody, !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state = .noSyllabus
            return
        }

        state = .scanning
        let text = ExamDateExtractor.relevantText(fromHTML: html)
        let term = Self.termInterval(for: course)
        var found: [ExamDateCandidate] = []
        var usedModel = false

        if #available(iOS 26.0, macOS 26.0, *) {
            let provider = AgentModelRouter().provider()
            if provider.tier == .onDevice, provider.isAvailable, !text.isEmpty {
                do {
                    found = try await ExamDateExtractor.modelCandidates(in: text, term: term, provider: provider)
                    usedModel = true
                } catch {
                    LoggerService.main.debug("[ExamDates] Model extraction failed, using date detection: \(error)")
                }
            }
        }
        if !usedModel {
            found = ExamDateExtractor.detectorCandidates(in: text, term: term)
        }

        let candidates = ExamDateExtractor.removingDuplicates(found, existing: existing)
        let result = Scan(courseID: course.id, syllabusHash: syllabusHash, scannedAt: .now, usedModel: usedModel, candidates: candidates)
        scan = result
        store.save(result)
        state = .done
    }

    func markHandled(_ ids: [UUID]) {
        guard var scan else { return }
        scan.handledIDs.formUnion(ids)
        self.scan = scan
        store.save(scan)
    }

    static func termInterval(for course: Course) -> DateInterval? {
        let start = course.term?.startAt ?? course.startAt
        let end = course.term?.endAt ?? course.endAt
        guard let start, let end, end > start else { return nil }
        return DateInterval(start: start, end: end)
    }

    static func hash(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).prefix(12).map { String(format: "%02x", $0) }.joined()
    }
}

/// One JSON file per course in Application Support.
struct ExamDateScanStore: Sendable {
    let directory: URL

    static let `default` = ExamDateScanStore(directory: URL.applicationSupportDirectory.appending(path: "exam-date-scans"))

    func load(courseID: String) -> ExamDateScanner.Scan? {
        guard let data = try? Data(contentsOf: url(for: courseID)) else { return nil }
        return try? JSONDecoder().decode(ExamDateScanner.Scan.self, from: data)
    }

    func save(_ scan: ExamDateScanner.Scan) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(scan).write(to: url(for: scan.courseID), options: .atomic)
        } catch {
            LoggerService.main.error("[ExamDates] Couldn't save scan: \(error)")
        }
    }

    private func url(for courseID: String) -> URL {
        directory.appending(path: "\(courseID).json")
    }
}

/// Review exam dates found in the syllabus: edit, remove or confirm each, then add the
/// confirmed ones to the course's to-dos as events.
struct ExamDatesView: View {
    @Environment(ToDoListManager.self) private var toDoListManager
    @Environment(\.dismiss) private var dismiss

    let course: Course

    @State private var scanner: ExamDateScanner
    @State private var drafts: [ExamDateCandidate] = []
    @State private var confirmed: Set<UUID> = []

    init(course: Course) {
        self.course = course
        _scanner = State(initialValue: ExamDateScanner(course: course))
    }

    var body: some View {
        Form {
            switch scanner.state {
            case .idle:
                Section {
                    Button("Scan Syllabus", systemImage: "doc.text.magnifyingglass") { Task { await scan() } }
                } footer: {
                    Text(availabilityNote)
                }
            case .scanning:
                Section { ProgressView("Reading the syllabus…") }
            case .noSyllabus:
                ContentUnavailableView("No Syllabus", systemImage: "doc.questionmark", description: Text("This course doesn't have a syllabus on Canvas."))
            case .failed(let message):
                Section { Text(message).foregroundStyle(.secondary) }
            case .done:
                results
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Exam Dates")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add \(confirmed.count)") { addConfirmed() }
                    .disabled(confirmed.isEmpty)
            }
        }
        .onAppear { drafts = scanner.pending }
    }

    @ViewBuilder
    private var results: some View {
        if scanner.isStale {
            Section {
                Button("Syllabus Changed: Re-scan", systemImage: "arrow.clockwise") { Task { await scan() } }
            }
        }

        if drafts.isEmpty {
            Section {
                Text("No new exam dates found.")
                    .foregroundStyle(.secondary)
                Button("Scan Again", systemImage: "arrow.clockwise") { Task { await scan() } }
            } footer: {
                Text(availabilityNote)
            }
        } else {
            Section {
                ForEach($drafts) { $draft in
                    ExamDateRow(candidate: $draft, isConfirmed: Binding {
                        confirmed.contains(draft.id)
                    } set: { isOn in
                        if isOn { confirmed.insert(draft.id) } else { confirmed.remove(draft.id) }
                    })
                    .swipeActions {
                        Button("Remove", role: .destructive) { remove(draft) }
                    }
                }
            } header: {
                Text("Found in the Syllabus")
            } footer: {
                Text("Check each date against the quote before adding it. \(scanner.scan?.usedModel == true ? "Found with Apple Intelligence." : "Found with basic date detection.")")
            }
        }
    }

    private var availabilityNote: String {
        if #available(iOS 26.0, macOS 26.0, *), IntelligenceSupport.isModelAvailable {
            return "Apple Intelligence reads the syllabus on this device."
        }
        if #available(iOS 26.0, macOS 26.0, *) {
            return "\(IntelligenceSupport.modelAvailabilityDescription) Basic date detection is used instead and may miss some dates."
        }
        return "Apple Intelligence needs iOS 26 or macOS 26. Basic date detection is used instead and may miss some dates."
    }

    private func scan() async {
        await scanner.scanSyllabus(existing: await existingEvents())
        drafts = scanner.pending
        confirmed = []
    }

    /// Calendar-feed events and the student's own to-dos for this course, to skip duplicates.
    private func existingEvents() async -> [(title: String, date: Date)] {
        var events: [(title: String, date: Date)] = toDoListManager.toDoItems
            .filter { $0.courseID.asString == course.id }
            .compactMap { item in item.dueDate.map { (item.title, $0) } }

        if let url = URL(string: course.calendarIcs ?? ""), let groups = try? await ICSParser.fetchEvents(from: url, for: course) {
            events += groups.flatMap(\.events).map { ($0.summary, $0.startDate) }
        }
        return events
    }

    private func remove(_ draft: ExamDateCandidate) {
        drafts.removeAll { $0.id == draft.id }
        confirmed.remove(draft.id)
        scanner.markHandled([draft.id])
    }

    private func addConfirmed() {
        guard let courseID = Int(course.id) else { return }
        let toAdd = drafts.filter { confirmed.contains($0.id) }

        for draft in toAdd {
            let item = ToDoItem(
                courseID: courseID,
                contextName: course.displayName,
                title: draft.title,
                dueDate: draft.date,
                location: draft.location ?? ""
            )
            toDoListManager.addUserCreatedItem(item, course: course)
        }

        scanner.markHandled(toAdd.map(\.id))
        drafts.removeAll { confirmed.contains($0.id) }
        confirmed = []
        if drafts.isEmpty { dismiss() }
    }
}

private struct ExamDateRow: View {
    @Binding var candidate: ExamDateCandidate
    @Binding var isConfirmed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: candidate.kind.systemImage).foregroundStyle(.tint)
                TextField("Title", text: $candidate.title).font(.headline)
                Toggle("Add", isOn: $isConfirmed).labelsHidden()
            }
            Picker("Kind", selection: $candidate.kind) {
                ForEach(ExamDateCandidate.Kind.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            DatePicker(
                "Date",
                selection: $candidate.date,
                displayedComponents: candidate.hasTime ? [.date, .hourAndMinute] : [.date]
            )
            Text("“\(candidate.sourceSnippet)”")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)
        }
        .padding(.vertical, 4)
    }
}
