//
//  GlobalCalendarView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/26/25.
//

import SwiftUI

struct GlobalCalendarView: View {
    @Environment(CourseManager.self) private var courseManager

    @State private var calendarManager = GlobalCalendarManager()
    @State private var isShowingNewItemSheet = false

    var body: some View {
        @Bindable var calendarManager = calendarManager

        VStack(spacing: 0) {
            switch calendarManager.viewMode {
            case .day:
                CalendarDayTimelineView(
                    date: calendarManager.currentDate,
                    events: calendarManager.events(on: calendarManager.currentDate),
                    calendar: calendarManager.calendar
                )
            case .week, .month:
                CalendarGridView(manager: calendarManager)
            }
        }
        .contentShape(.rect)
        .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded(pageOnSwipe))
        .accessibilityAction(named: "Previous") { calendarManager.step(by: -1) }
        .accessibilityAction(named: "Next") { calendarManager.step(by: 1) }
        .overlay(alignment: .bottomTrailing) {
            CalendarFloatingButtons(addAction: showNewItemSheet, assistantAction: askAssistant)
                #if os(macOS)
                .popover(isPresented: $isShowingNewItemSheet) { newItemSheet }
                #endif
        }
        #if !os(macOS)
        .sheet(isPresented: $isShowingNewItemSheet) { newItemSheet }
        #endif
        .navigationTitle(calendarManager.title)
        .toolbarTitleMenu {
            Button("Today", systemImage: "calendar.badge.clock", action: calendarManager.setToNow)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("View", selection: $calendarManager.viewMode) {
                        ForEach(CalendarViewMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.systemImage)
                        }
                    }
                } label: {
                    Label(calendarManager.viewMode.title, systemImage: calendarManager.viewMode.systemImage)
                        .labelStyle(.titleAndIcon)
                }
            }
        }
        .task {
            await calendarManager.getCalendarEventsForCourses(courses: courseManager.favoritedCourses)
        }
    }

    // Items belong to a course, so with no favorited courses there's nothing to attach one to.
    @ViewBuilder
    private var newItemSheet: some View {
        if let firstCourse = courseManager.favoritedCourses.first {
            CourseTodoCreationSheet(
                course: firstCourse,
                courseOptions: courseManager.favoritedCourses,
                initialDate: calendarManager.defaultNewItemDate
            )
        } else {
            ContentUnavailableView("No Courses", systemImage: "book.closed", description: Text("Favorite a course to add items to it."))
        }
    }

    private func showNewItemSheet() {
        isShowingNewItemSheet = true
    }

    private func askAssistant() {
        // Stub: AI assistant entry point, not wired up yet.
    }

    private func pageOnSwipe(_ value: DragGesture.Value) {
        let dx = value.translation.width
        guard abs(dx) > 60, abs(dx) > abs(value.translation.height) * 2 else { return }
        withAnimation(.snappy) {
            calendarManager.step(by: dx < 0 ? 1 : -1)
        }
    }
}
