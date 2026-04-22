//
//  AssignmentOverviewView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 4/20/26.
//

import SwiftUI
import SwiftData

struct AssignmentOverviewView: View {
    @Environment(NavigationModel.self) private var navigationModel

    let course: Course

    @State private var assignmentManager: CourseAssignmentManager

    init(course: Course) {
        self.course = course
        self._assignmentManager = State(initialValue: CourseAssignmentManager(courseID: course.id))
    }

    // MARK: - Assignment Buckets

    private var calendar: Calendar { .current }

    private func assignmentStatus(_ a: AssignmentAPI) -> AssignmentStatus {
        if a.submission?.missing == true { return .missing }
        switch a.submission?.workflow_state {
        case "graded", "submitted": return .completed
        default:                    return .inProgress
        }
    }

    /// All assignments sorted: in-progress first, then by due date ascending.
    // Mark - Might need to slightly adjust based on real course manager. Currently using sandbox environment. 
    private var prioritisedAssignments: [AssignmentAPI] {
        assignmentManager.allAssignments
            .filter { $0.dueDate != nil }
            .sorted {
                let aComplete = assignmentStatus($0) == .completed
                let bComplete = assignmentStatus($1) == .completed
                if aComplete != bComplete { return !aComplete }
                return ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture)
            }
    }

    private var todayAssignments: [AssignmentAPI] {
        prioritisedAssignments.filter { calendar.isDateInToday($0.dueDate!) }
    }

    private var thisWeekAssignments: [AssignmentAPI] {
        prioritisedAssignments.filter { a in
            let date = a.dueDate!
            return !calendar.isDateInToday(date)
                && calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
        }
    }

    /// Respects a combined cap of 5, giving today's slots priority.
    private var shownToday: [AssignmentAPI] {
        Array(todayAssignments.prefix(5))
    }

    private var shownThisWeek: [AssignmentAPI] {
        Array(thisWeekAssignments.prefix(max(0, 5 - shownToday.count)))
    }

    // MARK: - Body

    var body: some View {
        let hasToday    = !shownToday.isEmpty
        let hasThisWeek = !shownThisWeek.isEmpty

        Group {
            if !hasToday && !hasThisWeek {
                Text("No upcoming assignments")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)
                    .padding(.leading, 4)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    if hasToday {
                        assignmentSection(
                            title: "Today",
                            assignments: shownToday,
                            all: todayAssignments,
                            barColor: .accentColor
                        )
                    }
                    if hasThisWeek {
                        assignmentSection(
                            title: "This Week",
                            assignments: shownThisWeek,
                            all: thisWeekAssignments,
                            barColor: Color.secondary.opacity(0.4)
                        )
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .task {
            await assignmentManager.fetchAssignmentGroups()
        }
        .onChange(of: course.id) {
            assignmentManager = CourseAssignmentManager(courseID: course.id)
            Task { await assignmentManager.fetchAssignmentGroups() }
        }
    }

    // MARK: - Section

    @ViewBuilder
    private func assignmentSection(
        title: String,
        assignments: [AssignmentAPI],
        all: [AssignmentAPI],
        barColor: Color
    ) -> some View {
        let completedCount = all.filter { assignmentStatus($0) == .completed }.count
        let totalCount     = all.count
        let progress       = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 6)
                        Capsule()
                            .fill(barColor)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)

                Text("\(completedCount)/\(totalCount)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            VStack(spacing: 8) {
                ForEach(assignments, id: \.id) { assignment in
                    assignmentCard(assignment)
                }
            }
        }
    }

    // MARK: - Card

    @ViewBuilder
    private func assignmentCard(_ assignment: AssignmentAPI) -> some View {
        let status = assignmentStatus(assignment)

        Button {
            if let model = try? ModelContext.shared.fetch(
                FetchDescriptor<Assignment>(
                    predicate: #Predicate { $0.id == assignment.id.asString }
                )
            ).first {
                navigationModel.push(.assignment(model))
            }
        } label: {
            HStack(alignment: .top) {
                Text(assignment.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(status.label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(status.color)

                    if let dueDate = assignment.dueDate {
                        Text(dueDate, format: .dateTime.month(.abbreviated).day().hour().minute())
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Assignment Status

private enum AssignmentStatus {
    case inProgress, completed, missing

    var label: String {
        switch self {
        case .inProgress: "In Progress"
        case .completed:  "Completed"
        case .missing:    "Missing"
        }
    }

    var color: Color {
        switch self {
        case .inProgress: .secondary
        case .completed:  .green
        case .missing:    .red
        }
    }
}
