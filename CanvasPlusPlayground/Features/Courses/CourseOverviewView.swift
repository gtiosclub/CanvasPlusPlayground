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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let course: Course

    @State private var gradesVM: GradesViewModel
    @State private var expandedSections: Set<String> = []
    @State private var ringProgress: Double = 0
    @State private var showTodoCreation = false

    @ScaledMetric(relativeTo: .title3) private var addButtonSize: CGFloat = 52
    @ScaledMetric(relativeTo: .title) private var gradeRingSize: CGFloat = 120

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
                    .scaledFont(size: 56, relativeTo: .largeTitle, weight: .heavy)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .padding(.bottom, 4)

                columnLayout {
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
                    .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : 220)
                }
            }
            .padding(24)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showTodoCreation = true
            } label: {
                Image(systemName: "plus")
                    .scaledFont(size: 20, relativeTo: .title3, weight: .semibold)
                    .foregroundStyle(.primary)
                    .frame(width: addButtonSize, height: addButtonSize)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add To-Do")
            #if os(macOS)
            // Popover so clicking outside dismisses; macOS sheets are window-modal
            .popover(isPresented: $showTodoCreation) {
                CourseTodoCreationSheet(course: course)
            }
            #endif
            .padding(24)
        }
        #if !os(macOS)
        .sheet(isPresented: $showTodoCreation) {
            CourseTodoCreationSheet(course: course)
        }
        #endif
        .courseGradientBackground(
            courses: [course],
            isActive: course.rgbColors != nil,
            backgroundStyle: .grouped,
            showIcon: true
        )
        .readableCourseTint(course.rgbColors?.color)
        .navigationTitle(course.displayName)
        .task {
            await gradesVM.getEnrollments(currentUserID: profileManager.currentUser?.id)
        }
    }

    // MARK: - Layout

    private var columnLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 20))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 20))
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
                        .scaledFont(size: 30, relativeTo: .title, weight: .semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

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
                        .scaledFont(size: 30, relativeTo: .title, weight: .semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

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
                        .scaledFont(size: 30, relativeTo: .title, weight: .semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

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
                        .scaledFont(size: 30, relativeTo: .title, weight: .semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }

                gradeRing
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Grade")
        .accessibilityValue(gradeAccessibilityValue)
    }

    private var gradeAccessibilityValue: String {
        guard let score = Double(gradesVM.currentScore), score.isFinite else { return "No Grade" }
        return "\(Int(score)) percent"
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
                .animation(reduceMotion ? nil : .easeOut(duration: 0.8), value: ringProgress)

            Text("\(Int(scoreValue))%")
                .scaledFont(size: 30, relativeTo: .title, weight: .semibold)
        }
        .frame(width: gradeRingSize, height: gradeRingSize)
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
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.8).delay(0.2)) {
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
                        .scaledFont(size: 30, relativeTo: .title, weight: .semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }

                if courseToDoItems.isEmpty {
                    Text("No items")
                        .scaledFont(size: 13, relativeTo: .footnote)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(courseToDoItems.prefix(3)) { item in
                            HStack(spacing: 8) {
                                Image(systemName: "circle")
                                    .scaledFont(size: 13, relativeTo: .footnote)
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                                Text(item.title)
                                    .scaledFont(size: 13, relativeTo: .footnote)
                                    .lineLimit(1)
                                if item.dueDate != nil {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 6, height: 6)
                                        .accessibilityLabel("Has Due Date")
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
