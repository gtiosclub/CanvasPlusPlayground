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
    @State private var ringProgress: Double = 0
    @State private var showTodoCreation = false

    init(course: Course) {
        self.course = course
        self._gradesVM = State(initialValue: GradesViewModel(courseId: course.id))
    }

    // MARK: - To-Do Items

    private var courseToDoItems: [ToDoItem] {
        toDoListManager.displayedToDoItems.filter { $0.courseID.asString == course.id }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(course.displayName)
                    .font(.system(size: 56, weight: .heavy))
                    .padding(.bottom, 4)

                HStack(alignment: .top, spacing: 20) {
                    // Left column: expandable page rows
                    VStack(alignment: .leading, spacing: 0) {
                        assignmentsExpandableRow
                        announcementsExpandableRow
                        calendarExpandableRow
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
        .overlay(alignment: .bottomTrailing) {
            Button {
                showTodoCreation = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(24)
        }
        .sheet(isPresented: $showTodoCreation) {
            CourseTodoCreationSheet(course: course)
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

    // MARK: - Assignments Expandable Row

    private var assignmentsExpandableRow: some View {
        let isExpanded = expandedSections.contains("Assignments")

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                    if isExpanded {
                        expandedSections.remove("Assignments")
                    } else {
                        expandedSections.insert("Assignments")
                    }
                }
            } label: {
                HStack {
                    Text("Assignments")
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
                AssignmentOverviewView(course: course)
                    .transition(.opacity)
            }
        }
        .clipped()
    }

    // MARK: - Announcements Expandable Row

    private var announcementsExpandableRow: some View {
        let isExpanded = expandedSections.contains("Announcements")

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                    if isExpanded {
                        expandedSections.remove("Announcements")
                    } else {
                        expandedSections.insert("Announcements")
                    }
                }
            } label: {
                HStack {
                    Text("Announcements")
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
                AnnouncementOverviewView(course: course)
                    .transition(.opacity)
            }
        }
        .clipped()
    }

    // MARK: - Calendar Expandable Row

    private var calendarExpandableRow: some View {
        let isExpanded = expandedSections.contains("Calendar")

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                    if isExpanded {
                        expandedSections.remove("Calendar")
                    } else {
                        expandedSections.insert("Calendar")
                    }
                }
            } label: {
                HStack {
                    Text("Calendar")
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
                CalendarOverviewView(course: course)
                    .transition(.opacity)
            }
        }
        .clipped()
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

        return ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 12)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: ringProgress)

            Text("\(Int(scoreValue))%")
                .font(.system(size: 30, weight: .semibold))
        }
        .frame(width: 120, height: 120)
        .onAppear {
            animateRingToCurrentScore()
        }
        .onDisappear {
            ringProgress = 0
        }
        .onChange(of: gradesVM.currentScore) {
            ringProgress = 0
            animateRingToCurrentScore()
        }
        .onChange(of: course.id) {
            ringProgress = 0
            animateRingToCurrentScore()
        }
    }

    private func animateRingToCurrentScore() {
        let target = (Double(gradesVM.currentScore) ?? 0) / 100.0
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            ringProgress = target
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
