//
//  CourseContractView.swift
//  CanvasPlusPlayground
//

import SwiftUI

/// Builds, verifies and caches a course's contract. Cached per course with the syllabus hash,
/// so it's rebuilt only when the syllabus changes (or the student asks).
@MainActor
@Observable
final class CourseContractModel {
    enum State: Equatable {
        case loading
        case loaded
        case noSyllabus
    }

    private(set) var state = State.loading
    private(set) var contract: CourseContract?

    private let course: Course
    private let store: CourseContractStore

    init(course: Course, store: CourseContractStore = .default) {
        self.course = course
        self.store = store
    }

    func load(force: Bool = false) async {
        guard let html = course.syllabusBody, !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state = .noSyllabus
            return
        }

        let hash = ExamDateScanner.hash(html)
        if !force, let cached = store.load(courseID: course.id), cached.syllabusHash == hash {
            contract = cached
            state = .loaded
            // Canvas may have changed since; re-verify against it without re-reading the syllabus.
            contract = await verify(cached)
            return
        }

        state = .loading
        let text = CourseContractExtractor.plainText(fromHTML: html)
        let examText = ExamDateExtractor.relevantText(fromHTML: html)
        let term = ExamDateScanner.termInterval(for: course)

        var fields = CourseContractExtractor.Extracted()
        var exams: [ExamDateCandidate] = []
        var usedModel = false

        if #available(iOS 26.0, macOS 26.0, *) {
            let provider = AgentModelRouter().provider()
            if provider.tier == .onDevice, provider.isAvailable {
                do {
                    fields = try await CourseContractExtractor.modelFields(in: text, provider: provider)
                    exams = try await ExamDateExtractor.modelCandidates(in: examText, term: term, provider: provider)
                    usedModel = true
                } catch {
                    LoggerService.main.debug("[Contract] Model extraction failed, using patterns: \(error)")
                }
            }
        }
        if !usedModel {
            fields = CourseContractExtractor.patternFields(in: text)
            exams = ExamDateExtractor.detectorCandidates(in: examText, term: term)
        }

        let built = CourseContract(
            courseID: course.id,
            syllabusHash: hash,
            extractedAt: .now,
            usedModel: usedModel,
            weights: fields.weights,
            examDates: ExamDateExtractor.removingDuplicates(exams, existing: []).map { .init($0, excerpt: $0.sourceSnippet) },
            latePolicy: fields.latePolicy,
            dropRules: fields.dropRules,
            attendance: fields.attendance,
            officeHours: fields.officeHours
        )

        let verified = await verify(built)
        contract = verified
        store.save(verified)
        state = .loaded
    }

    private func verify(_ contract: CourseContract) async -> CourseContract {
        CourseContractVerifier.verify(contract, groups: await canvasGroups(), calendarEvents: await calendarEvents())
    }

    private func canvasGroups() async -> [CourseContractVerifier.CanvasGroup] {
        let groups: [AssignmentGroup]
        if AppEnvironment.isSandbox {
            groups = SandboxData.dummyAssignmentGroups(forCourseID: course.id)
        } else {
            let request = CanvasRequest.getAssignmentGroups(courseId: course.id)
            if let cached = try? await CanvasService.shared.load(request), !cached.isEmpty {
                groups = cached
            } else {
                groups = (try? await CanvasService.shared.syncWithAPI(request)) ?? []
            }
        }
        return groups.map { .init(id: $0.id, name: $0.name, weight: $0.groupWeight, dropLowest: $0.rules?.dropLowest.flatMap { $0 > 0 ? $0 : nil }) }
    }

    private func calendarEvents() async -> [(title: String, date: Date)] {
        guard let url = URL(string: course.calendarIcs ?? ""),
              let groups = try? await ICSParser.fetchEvents(from: url, for: course) else {
            return []
        }
        return groups.flatMap(\.events).map { ($0.summary, $0.startDate) }
    }
}

struct CourseContractStore: Sendable {
    let directory: URL

    static let `default` = CourseContractStore(directory: URL.applicationSupportDirectory.appending(path: "course-contracts"))

    func load(courseID: String) -> CourseContract? {
        guard let data = try? Data(contentsOf: directory.appending(path: "\(courseID).json")) else { return nil }
        return try? JSONDecoder().decode(CourseContract.self, from: data)
    }

    func save(_ contract: CourseContract) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(contract).write(to: directory.appending(path: "\(contract.courseID).json"), options: .atomic)
        } catch {
            LoggerService.main.error("[Contract] Couldn't save: \(error)")
        }
    }
}

/// The course contract: grading weights, exam dates and policies from the syllabus, each with
/// a badge for whether Canvas agrees and the excerpt it came from.
struct CourseContractView: View {
    let course: Course

    @State private var model: CourseContractModel
    @State private var showExamDates = false

    init(course: Course) {
        self.course = course
        _model = State(initialValue: CourseContractModel(course: course))
    }

    var body: some View {
        List {
            if let contract = model.contract {
                summary(contract)

                if !contract.weights.isEmpty {
                    Section("Grade Weights") {
                        ForEach(contract.weights, id: \.self) { field in
                            ContractFieldRow(title: field.value.name, value: "\(field.value.percent.formatted())%", field: field)
                        }
                    }
                }

                if !contract.dropRules.isEmpty {
                    Section("Dropped Scores") {
                        ForEach(contract.dropRules, id: \.self) { field in
                            ContractFieldRow(title: field.value.group.capitalized, value: "Lowest \(field.value.dropLowest)", field: field)
                        }
                    }
                }

                Section {
                    if contract.examDates.isEmpty {
                        Text("No exam dates found.").foregroundStyle(.secondary)
                    }
                    ForEach(contract.examDates, id: \.self) { field in
                        ContractFieldRow(
                            title: field.value.title,
                            value: field.value.date.formatted(date: .abbreviated, time: field.value.hasTime ? .shortened : .omitted),
                            field: field
                        )
                    }
                    if contract.examDates.contains(where: { $0.status == .notFound }) {
                        Button("Add Missing Dates…", systemImage: "calendar.badge.plus") { showExamDates = true }
                    }
                } header: {
                    Text("Exam Dates")
                }

                Section("Policies") {
                    policyRow("Late Work", contract.latePolicy)
                    policyRow("Attendance", contract.attendance)
                    if contract.officeHours.isEmpty {
                        LabeledContent("Office Hours", value: "Not found").foregroundStyle(.secondary)
                    }
                    ForEach(contract.officeHours, id: \.self) { field in
                        ContractFieldRow(title: "Office Hours", value: nil, field: field, showsValueAsText: true)
                    }
                }
            }
        }
        .overlay {
            switch model.state {
            case .loading where model.contract == nil:
                ProgressView("Reading the syllabus…")
            case .noSyllabus:
                ContentUnavailableView("No Syllabus", systemImage: "doc.questionmark", description: Text("This course doesn't have a syllabus on Canvas."))
            default:
                EmptyView()
            }
        }
        .navigationTitle("Course Contract")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Re-read Syllabus", systemImage: "arrow.clockwise") {
                    Task { await model.load(force: true) }
                }
                .disabled(model.state == .loading)
            }
        }
        .sheet(isPresented: $showExamDates) {
            NavigationStack { ExamDatesView(course: course) }
        }
        .task { await model.load() }
    }

    private func summary(_ contract: CourseContract) -> some View {
        Section {
            ForEach(contract.notes, id: \.self) { note in
                Label(note.text, systemImage: ContractBadge.icon(note.status))
                    .foregroundStyle(ContractBadge.color(note.status))
            }
        } footer: {
            Text("From the syllabus\(contract.usedModel ? ", read on this device with Apple Intelligence" : " by pattern matching (Apple Intelligence isn't available)"). Badges show whether Canvas agrees. The syllabus and your instructor have the final word.")
        }
    }

    @ViewBuilder
    private func policyRow(_ title: String, _ field: CourseContract.Field<String>?) -> some View {
        if let field {
            ContractFieldRow(title: title, value: nil, field: field, showsValueAsText: true)
        } else {
            LabeledContent(title, value: "Not found").foregroundStyle(.secondary)
        }
    }
}

private struct ContractFieldRow<Value: Codable & Hashable & Sendable>: View {
    let title: String
    let value: String?
    let field: CourseContract.Field<Value>
    var showsValueAsText = false

    @State private var showsExcerpt = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.headline)
                Spacer()
                if let value { Text(value).monospacedDigit() }
                ContractBadge(status: field.status)
            }
            if showsValueAsText, let text = field.value as? String, text != field.excerpt {
                Text(text).font(.subheadline)
            }
            if let detail = field.detail {
                Text(detail).font(.caption).foregroundStyle(ContractBadge.color(field.status))
            }
            Button(showsExcerpt ? "Hide syllabus text" : "Show syllabus text") { showsExcerpt.toggle() }
                .font(.caption)
                .buttonStyle(.borderless)
            if showsExcerpt {
                Text("“\(field.excerpt)”").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct ContractBadge: View {
    let status: CourseContract.Status

    var body: some View {
        Label(Self.label(status), systemImage: Self.icon(status))
            .labelStyle(.iconOnly)
            .foregroundStyle(Self.color(status))
            .accessibilityLabel(Self.label(status))
    }

    static func label(_ status: CourseContract.Status) -> String {
        switch status {
        case .confirmed: "Confirmed on Canvas"
        case .unverified: "Not checked"
        case .notFound: "Not found on Canvas"
        case .conflict: "Canvas disagrees"
        }
    }

    static func icon(_ status: CourseContract.Status) -> String {
        switch status {
        case .confirmed: "checkmark.seal.fill"
        case .unverified: "questionmark.circle"
        case .notFound: "magnifyingglass.circle"
        case .conflict: "exclamationmark.triangle.fill"
        }
    }

    static func color(_ status: CourseContract.Status) -> Color {
        switch status {
        case .confirmed: .green
        case .unverified: .secondary
        case .notFound: .orange
        case .conflict: .red
        }
    }
}
