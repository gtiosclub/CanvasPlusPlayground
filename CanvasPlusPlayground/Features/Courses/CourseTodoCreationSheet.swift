//
//  CourseTodoCreationSheet.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 4/20/26.
//

import SwiftUI

struct CourseTodoCreationSheet: View {
    @Environment(ToDoListManager.self) private var toDoListManager
    @Environment(\.dismiss) private var dismiss

    let course: Course

    // MARK: - State

    enum ItemKind: Int { case event, task }

    @State private var kind: ItemKind = .event
    @State private var title: String = ""

    // Event-only
    @State private var location: String = ""

    // Task-only
    @State private var urgency: Urgency = .none
    @State private var relatedEntity: RelatedEntity = .none

    // Shared
    @State private var dueDate: Date = .now
    @State private var hasDueDate: Bool = false

    // Backing data for related picker
    @State private var assignmentManager: CourseAssignmentManager
    @State private var quizzes: [Quiz] = []

    // MARK: - Enums

    enum Urgency: String, CaseIterable, Identifiable {
        case none   = "None"
        case low    = "Low"
        case medium = "Medium"
        case high   = "High"
        var id: String { rawValue }
    }

    enum RelatedEntity: Equatable {
        case none
        case assignment(AssignmentAPI)
        case quiz(Quiz)

        static func == (lhs: RelatedEntity, rhs: RelatedEntity) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none): return true
            case (.assignment(let a), .assignment(let b)): return a.id == b.id
            case (.quiz(let a), .quiz(let b)): return a.id == b.id
            default: return false
            }
        }

        var displayName: String {
            switch self {
            case .none:                return "Select Related"
            case .assignment(let a):   return a.name
            case .quiz(let q):         return q.title
            }
        }
    }

    // MARK: - Init

    init(course: Course) {
        self.course = course
        self._assignmentManager = State(
            initialValue: CourseAssignmentManager(courseID: course.id)
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            kindPicker
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 20)

            fieldsCard
                .padding(.horizontal, 16)

            Spacer()

            saveButton
                .padding(16)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            async let _a: () = assignmentManager.fetchAssignmentGroups()
            async let _q: () = fetchQuizzes()
            await _a; await _q
        }
    }

    // MARK: - Kind Picker

    private var kindPicker: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(.quaternary)
                    .frame(height: 36)

                // Sliding indicator
                Capsule()
                    .fill(.background)
                    .frame(width: geo.size.width / 2, height: 32)
                    .padding(.horizontal, 2)
                    .offset(x: kind == .event ? 0 : geo.size.width / 2)
                    .animation(.spring(response: 0.35, dampingFraction: 0.65), value: kind)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

                // Labels — full-width tap targets
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                            kind = .event
                        }
                    } label: {
                        Text("Event")
                            .font(.system(size: 15, weight: kind == .event ? .semibold : .regular))
                            .foregroundStyle(kind == .event ? .primary : .secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                            kind = .task
                        }
                    } label: {
                        Text("Task")
                            .font(.system(size: 15, weight: kind == .task ? .semibold : .regular))
                            .foregroundStyle(kind == .task ? .primary : .secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 36)
            }
        }
        .frame(height: 36)
    }

    // MARK: - Fields Card

    @ViewBuilder
    private var fieldsCard: some View {
        VStack(spacing: 10) {
            // Group 1: Title
            card {
                fieldRow {
                    TextField(kind == .event ? "New Event" : "New Task", text: $title)
                        .font(.system(size: 16))
                }
            }

            // Course pill — standalone capsule, no wrapper needed
            Text(course.displayName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(course.rgbColors?.color ?? .accentColor, in: Capsule())

            // Related picker — its own card, task only
            if kind == .task {
                card { relatedPicker }
            }

            // Group 3: Time + Location (event) or Time + Urgency (task)
            card {
                fieldRow {
                    HStack {
                        Toggle("Add Time", isOn: $hasDueDate.animation())
                            .labelsHidden()
                        Text("Add Time")
                            .foregroundStyle(hasDueDate ? .primary : .secondary)
                        Spacer()
                        if hasDueDate {
                            DatePicker("", selection: $dueDate)
                                .labelsHidden()
                        }
                    }
                }

                if kind == .event {
                    divider()
                    fieldRow {
                        TextField("Add Location", text: $location)
                    }
                }

                if kind == .task {
                    divider()
                    fieldRow {
                        HStack {
                            Text("Urgency")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Picker("", selection: $urgency) {
                                ForEach(Urgency.allCases) { u in
                                    Text(u.rawValue).tag(u)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: kind)
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .clipped()
    }

    // MARK: - Related Picker

    private var relatedPicker: some View {
        Menu {
            Button("None") { relatedEntity = .none }

            if !assignmentManager.allAssignments.isEmpty {
                Section("Assignments") {
                    ForEach(assignmentManager.allAssignments, id: \.id) { a in
                        Button(a.name) { relatedEntity = .assignment(a) }
                    }
                }
            }

            if !quizzes.isEmpty {
                Section("Quizzes") {
                    ForEach(quizzes) { q in
                        Button(q.title) { relatedEntity = .quiz(q) }
                    }
                }
            }
        } label: {
            fieldRow {
                HStack {
                    if relatedEntity != .none {
                        Image(systemName: relatedEntity == .none ? "" : "link")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    Text(relatedEntity.displayName)
                        .foregroundStyle(relatedEntity == .none ? .secondary : .primary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        let empty = title.trimmingCharacters(in: .whitespaces).isEmpty
        return Button { save() } label: {
            Text("Add \(kind == .event ? "Event" : "Task")")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    empty ? Color.secondary.opacity(0.3) : Color.accentColor,
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .foregroundStyle(empty ? Color.secondary : .white)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: kind)
        }
        .disabled(empty)
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func fieldRow<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }

    private func divider(leading: CGFloat = 16) -> some View {
        Divider().padding(.leading, leading)
    }

    private func fetchQuizzes() async {
        let request = CanvasRequest.getQuizzes(courseId: course.id)
        guard let fetched: [Quiz] = try? await CanvasService.shared.loadAndSync(request) else { return }
        quizzes = fetched
    }

    // MARK: - Save

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let courseIDInt = Int(course.id) else { return }

        let item = ToDoItem(
            courseID: courseIDInt,
            contextName: course.displayName,
            title: trimmed,
            dueDate: hasDueDate ? dueDate : nil,
            urgency: urgency == .none ? nil : urgency.rawValue,
            location: kind == .event ? location.trimmingCharacters(in: .whitespaces) : nil
        )

        switch relatedEntity {
        case .assignment(let a): item.assignmentAPI = a
        case .quiz(let q):       item.quizAPI = q.toAPI()
        case .none:              break
        }

        toDoListManager.addUserCreatedItem(item, course: course)
        dismiss()
    }
}
