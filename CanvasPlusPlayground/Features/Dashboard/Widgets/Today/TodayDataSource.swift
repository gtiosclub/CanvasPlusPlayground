//
//  TodayDataSource.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 10/19/25.
//

import SwiftUI

@Observable
class TodayDataSource: ListWidgetDataSource {
    private let todoManager: ToDoListManager

    private var todayItems: [TodayItem] = []

    var fetchStatus: WidgetFetchStatus = .loading
    private(set) var todoState: TodaySectionState = .loading
    private(set) var calendarEventState: TodaySectionState = .loading

    var overdueItems: [ListWidgetData] { items(in: .overdue) }
    var dueSoonItems: [ListWidgetData] { items(in: .dueSoon) }
    var calendarEventItems: [ListWidgetData] { items(in: .calendarEvents) }

    /// `true` once every section has finished loading and none of them has anything to show.
    var isEmpty: Bool {
        todoState != .loading && calendarEventState != .loading && todayItems.isEmpty
    }

    init(
        todoManager: ToDoListManager = .init()
    ) {
        self.todoManager = todoManager
    }

    func state(for section: TodaySection) -> TodaySectionState {
        switch section {
        case .overdue, .dueSoon:
            todoState
        case .calendarEvents:
            calendarEventState
        }
    }

    func items(in section: TodaySection) -> [ListWidgetData] {
        todayItems
            .filter { $0.section == section }
            .map(\.listData)
    }

    /// Overdue first since those need attention, then what's due soon, then today's events.
    var widgetData: [ListWidgetData] {
        get {
            TodaySection.allCases.flatMap { items(in: $0) }
        }
        set { }
    }

    func fetchData(context: WidgetContext) async throws {
        guard let courseManager = context.courseManager else {
            await MainActor.run {
                todoState = .failed("Courses haven't loaded yet.")
                calendarEventState = .failed("Courses haven't loaded yet.")
                fetchStatus = .error
            }
            return
        }

        // Keep showing the current items during a refresh; only show spinners on the first load.
        await MainActor.run {
            if todayItems.isEmpty {
                todoState = .loading
                calendarEventState = .loading
                fetchStatus = .loading
            }
        }

        if AppEnvironment.isSandbox {
            await MainActor.run {
                todoState = .loaded
                calendarEventState = .loaded
                aggregateTodayItems(
                    todos: SandboxData.dummyTodayToDoItems,
                    calendarEvents: SandboxData.dummyTodayCalendarEvents,
                    now: .now
                )
                fetchStatus = .loaded
            }
            return
        }

        async let calendarResult = fetchTodayCalendarEvents(courses: courseManager.activeCourses)

        try await todoManager.fetchData(context: context)
        let calendar = await calendarResult

        await MainActor.run {
            if let errorMessage = todoManager.errorMessage {
                todoState = .failed(errorMessage)
            } else {
                todoState = .loaded
            }

            // Only call it a failure if every calendar feed failed; a single
            // course with a broken feed shouldn't hide the others.
            if calendar.attempted > 0 && calendar.failed == calendar.attempted {
                calendarEventState = .failed("Couldn't load your course calendars.")
            } else {
                calendarEventState = .loaded
            }

            aggregateTodayItems(
                todos: todoManager.displayedToDoItems,
                calendarEvents: calendar.events,
                now: .now
            )

            if case .failed = todoState, case .failed = calendarEventState {
                fetchStatus = .error
            } else {
                fetchStatus = .loaded
            }
        }
    }

    private func fetchTodayCalendarEvents(
        courses: [Course]
    ) async -> (events: [(CanvasCalendarEvent, Course)], attempted: Int, failed: Int) {
        var events: [(CanvasCalendarEvent, Course)] = []
        var attempted = 0
        var failed = 0
        let today = Date()

        await withTaskGroup(of: [(CanvasCalendarEvent, Course)]?.self) { group in
            for course in courses {
                guard let icsURL = URL(string: course.calendarIcs ?? "") else {
                    continue
                }

                attempted += 1

                group.addTask {
                    guard let eventGroups = try? await ICSParser.fetchEvents(from: icsURL, for: course) else {
                        return nil
                    }

                    return eventGroups
                        .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
                        .flatMap { $0.events }
                        .map { ($0, course) }
                }
            }

            for await courseEvents in group {
                if let courseEvents {
                    events.append(contentsOf: courseEvents)
                } else {
                    failed += 1
                }
            }
        }

        return (events, attempted, failed)
    }

    private func aggregateTodayItems(
        todos: [ToDoItem],
        calendarEvents: [(CanvasCalendarEvent, Course)],
        now: Date
    ) {
        var items: [TodayItem] = todos.compactMap { todoItem in
            guard let dueDate = todoItem.todayDueDate,
                  let section = TodaySchedule.section(forDueDate: dueDate, now: now) else {
                return nil
            }

            return TodayItem(.todo(todoItem, dueDate: dueDate), section: section, now: now)
        }

        items += calendarEvents.map {
            TodayItem(.calendarEvent($0.0, $0.1), section: .calendarEvents, now: now)
        }

        self.todayItems = items.sorted { $0.sortDate < $1.sortDate }
    }

    func destinationView(for data: ListWidgetData) -> NavigationModel.Destination {
        guard let item = todayItems.first(where: { $0.listData.id == data.id }) else {
            return .today
        }

        switch item.type {
        case .todo(let todoItem, _):
            return todoItem.navigationDestination() ?? .today
        case let .calendarEvent(event, course):
            return .calendarEvent(event, course)
        }
    }
}

private struct TodayItem {
    enum ItemType {
        case todo(ToDoItem, dueDate:
            Date)
        case calendarEvent(CanvasCalendarEvent, Course)
    }

    let type: ItemType
    let section: TodaySection
    let listData: ListWidgetData

    init(_ type: ItemType, section: TodaySection, now: Date) {
        self.type = type
        self.section = section

        switch type {
        case let .todo(todoItem, dueDate):
            listData = ListWidgetData(
                id: "todo-\(todoItem.id)",
                title: todoItem.title,
                description: TodaySchedule.todoDescription(
                    dueDate: dueDate,
                    courseName: todoItem.course?.displayName ?? todoItem.contextName,
                    now: now
                )
            )
        case let .calendarEvent(event, course):
            let timeStr = event.startDate.formatted(date: .omitted, time: .shortened)
            listData = ListWidgetData(
                id: "event-\(event.id)",
                title: event.summary,
                description: "\(timeStr) • \(course.name ?? "Unknown Course")"
            )
        }
    }

    var sortDate: Date {
        switch type {
        case .todo(_, let dueDate):
            return dueDate
        case .calendarEvent(let event, _):
            return event.startDate
        }
    }
}

private extension ToDoItem {
    /// `AssignmentAPI.dueDate` falls back to a placeholder date when `due_at` is missing,
    /// which would make undated assignments look overdue. Only trust a due date that was set.
    var todayDueDate: Date? {
        if let assignmentAPI {
            return assignmentAPI.due_at == nil ? nil : assignmentAPI.dueDate
        }

        return dueDate
    }
}
