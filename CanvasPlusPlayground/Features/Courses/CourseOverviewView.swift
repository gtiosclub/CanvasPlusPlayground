//
//  CourseOverviewView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 4/13/26.
//

import SwiftUI

struct CourseOverviewView: View {
    @Environment(ProfileManager.self) private var profileManager
    @Environment(ToDoListManager.self) private var toDoListManager
    @Environment(NavigationModel.self) private var navigationModel

    let course: Course

    @State private var gradesVM: GradesViewModel
    @State private var expandedSections: Set<String> = []
    @State private var animateRing = false

    init(course: Course) {
        self.course = course
        self._gradesVM = State(initialValue: GradesViewModel(courseId: course.id))
    }

    private var courseToDoItems: [ToDoItem] {
        toDoListManager.displayedToDoItems.filter { $0.courseID.asString == course.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Course Dashboard")
                    .font(.system(size: 56, weight: .heavy))
                    .padding(.bottom, 4)

                HStack(alignment: .top, spacing: 20) {
                    // Left column: expandable page rows
                    VStack(alignment: .leading, spacing: 0) {
                        expandableRow("Assignments", page: .assignments)
                        expandableRow("Announcements", page: .announcements)
                        expandableRow("Calendar", page: .calendar)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Right column: grade + to-do cards
                    VStack(spacing: 16) {
                        gradeCard
                        toDoCard
                    }
                    .frame(width: 220)
                }
            }
            .padding(24)
        }
        .courseGradientBackground(
            courses: [course],
            isActive: course.rgbColors != nil,
            backgroundStyle: .grouped,
            showIcon: true
        )
        .tint(course.rgbColors?.color)
        .navigationTitle(course.displayName)
        .task {
            await gradesVM.getEnrollments(currentUserID: profileManager.currentUser?.id)
        }
    }

    // MARK: - Expandable Row

    @ViewBuilder
    private func expandableRow(_ title: String, page: NavigationModel.CoursePage) -> some View {
        let isExpanded = expandedSections.contains(title)

        Button {
            withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                if isExpanded {
                    expandedSections.remove(title)
                } else {
                    expandedSections.insert(title)
                }
            }
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
            }
            .contentShape(Rectangle())
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)

        if isExpanded {
            // Placeholder for expanded content
            Text("No items to display")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Grade Card

    private var gradeCard: some View {
        Button {
            navigationModel.push(.coursePage(.grades, course))
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Grade")
                        .font(.system(size: 30, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }

                gradeRing
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var gradeRing: some View {
        let scoreValue = Double(gradesVM.currentScore) ?? 0
        let progress = animateRing ? scoreValue / 100.0 : 0

        return ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(scoreValue))%")
                .font(.system(size: 30, weight: .semibold))
        }
        .frame(width: 120, height: 120)
        .animation(.easeOut(duration: 0.8), value: animateRing)
        .onAppear {
            animateRing = false
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateRing = true
            }
        }
        .onDisappear {
            animateRing = false
        }
    }

    // MARK: - To-Do Card

    private var toDoCard: some View {
        Button {
            navigationModel.push(.allToDos)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("To-Do List")
                        .font(.system(size: 30, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }

                if courseToDoItems.isEmpty {
                    Text("No items")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(courseToDoItems.prefix(3)) { item in
                            HStack(spacing: 8) {
                                Image(systemName: "circle")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                Text(item.title)
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                                if item.dueDate != nil {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
