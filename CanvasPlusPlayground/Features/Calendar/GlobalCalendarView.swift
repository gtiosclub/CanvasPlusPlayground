//
//  GlobalCalendarView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/26/25.
//

import SwiftUI

struct GlobalCalendarView: View {
    @Environment(CourseManager.self) private var courseManager
    @Environment(ToDoListManager.self) private var toDoListManager

    @State private var calendarManager = GlobalCalendarManager()
    @State private var isShowingNewItemSheet = false

    var body: some View {
        @Bindable var calendarManager = calendarManager

        // One outer, never-scrolling ScrollView for every mode. The large nav title tracks the first scroll
        // view it finds; letting Day's timeline drive it left the title collapsed or blank after switching
        // to Week/Month, since grids never scroll it back open. Day's timeline scrolls inside this one.
        ScrollView {
            VStack(spacing: 0) {
                switch calendarManager.viewMode {
                case .day:
                    CalendarDayTimelineView(
                        date: calendarManager.currentDate,
                        events: calendarManager.events(on: calendarManager.currentDate),
                        calendar: calendarManager.calendar,
                        destination: calendarManager.destination(for:)
                    )
                case .week, .month:
                    CalendarGridView(manager: calendarManager)
                }
            }
            .containerRelativeFrame(.vertical)
        }
        .scrollBounceBehavior(.basedOnSize)
        // Day's timeline runs to the screen edge; its own bottom padding keeps late events reachable.
        .ignoresSafeArea(.container, edges: calendarManager.viewMode == .day ? .bottom : [])
        .contentShape(.rect)
        .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded(pageOnSwipe))
        .accessibilityAction(named: "Previous") { calendarManager.step(by: -1) }
        .accessibilityAction(named: "Next") { calendarManager.step(by: 1) }
        .overlay(alignment: .bottomTrailing) {
            CalendarFloatingButtons(addAction: showNewItemSheet)
                #if os(macOS)
                .popover(isPresented: $isShowingNewItemSheet) { newItemSheet }
                #endif
        }
        #if !os(macOS)
        .sheet(isPresented: $isShowingNewItemSheet) { newItemSheet }
        #endif
        .navigationTitle(calendarManager.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("View", selection: $calendarManager.viewMode) {
                        ForEach(CalendarViewMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.systemImage)
                        }
                    }
                    // toolbarTitleMenu doesn't attach to large titles, so "jump to today" lives here.
                    Divider()
                    Button("Today", systemImage: "calendar.badge.clock", action: calendarManager.setToNow)
                } label: {
                    // Toolbars render a Label icon-only; an HStack keeps the mode name visible.
                    HStack {
                        Image(systemName: calendarManager.viewMode.systemImage)
                        Text(calendarManager.viewMode.title)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .task {
            // The environment to-do manager is only filled when a screen fetches into it (dashboard widgets keep their own).
            async let toDos: () = toDoListManager.fetchToDoItems(courses: courseManager.activeCourses)
            await calendarManager.getCalendarEventsForCourses(courses: courseManager.favoritedCourses)
            await toDos
        }
        // Includes items saved from the + sheet, so they appear as soon as it closes.
        .onChange(of: toDoListManager.toDoItems, initial: true, refreshToDos)
        .onChange(of: courseManager.activeCourses, refreshToDos)
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

    private func refreshToDos() {
        calendarManager.setToDoItems(Array(toDoListManager.toDoItems), courses: courseManager.activeCourses)
    }

    private func showNewItemSheet() {
        isShowingNewItemSheet = true
    }


    private func pageOnSwipe(_ value: DragGesture.Value) {
        let dx = value.translation.width
        guard abs(dx) > 60, abs(dx) > abs(value.translation.height) * 2 else { return }
        withAnimation(.snappy) {
            calendarManager.step(by: dx < 0 ? 1 : -1)
        }
    }
}
