//
//  CourseGradeWidget.swift
//  CanvasPlusPlayground
//

import SwiftUI

/// Course Home widget: current score ring plus the assignment group weights (when the course weights groups).
struct CourseGradeWidget: View {
    @Environment(ProfileManager.self) private var profileManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let course: Course

    @State private var gradesVM: GradesViewModel
    @State private var assignmentManager: CourseAssignmentManager
    @State private var ringProgress = 0.0

    init(course: Course) {
        self.course = course
        self._gradesVM = State(initialValue: GradesViewModel(courseId: course.id))
        self._assignmentManager = State(initialValue: CourseAssignmentManager(courseID: course.id))
    }

    private var score: Double? { Double(gradesVM.currentScore) }

    private var weightedGroups: [AssignmentGroup] {
        guard course.applyAssignmentGroupWeights == true else { return [] }
        return assignmentManager.assignmentGroups.filter { ($0.groupWeight ?? 0) > 0 }
    }

    var body: some View {
        CourseWidgetCard(
            title: "Grade",
            systemImage: "a.circle",
            destination: .coursePage(.grades, course)
        ) {
            HStack(spacing: 24) {
                ring
                    .frame(width: 112, height: 112)
                    .padding(14)

                if !weightedGroups.isEmpty {
                    weightsTable
                }
            }
            .frame(maxWidth: .infinity)
        }
        .task(id: course.id) {
            await gradesVM.getEnrollments(currentUserID: profileManager.currentUser?.id)
            await assignmentManager.fetchAssignmentGroups()
        }
        .onChange(of: score, initial: true) {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.8).delay(0.2)) {
                ringProgress = (score ?? 0) / 100
            }
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(.tint.opacity(0.3), lineWidth: 16)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(.tint, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text(score.map { "\(Int($0))%" } ?? "--")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.tint)
                .minimumScaleFactor(0.5)
                .padding(19)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current grade")
        .accessibilityValue(score.map { "\(Int($0)) percent" } ?? "Unavailable")
    }

    private var weightsTable: some View {
        Grid(alignment: .leading, verticalSpacing: 8) {
            GridRow {
                Text("Group")
                Text("Weight")
                    .gridColumnAlignment(.trailing)
            }
            .foregroundStyle(.secondary)

            Divider()

            ForEach(weightedGroups) { group in
                GridRow {
                    Text(group.name)
                        .lineLimit(1)
                    Text((group.groupWeight ?? 0) / 100, format: .percent)
                }
            }
        }
        .foregroundStyle(.secondary)
    }
}
