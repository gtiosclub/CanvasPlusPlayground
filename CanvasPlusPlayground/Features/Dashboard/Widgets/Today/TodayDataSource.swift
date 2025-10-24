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

    var todoItems: [ListWidgetData] {
        todayItems.compactMap { item in
            guard case .todo(let todoItem) = item.type else { return nil }
            return ListWidgetData(
                id: "todo-\(todoItem.id)",
                title: todoItem.title,
                description: "Due \(todoItem.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "-")"
            )
        }
    }

    var calendarEventItems: [ListWidgetData] {
        todayItems.compactMap { item in
            guard case .calendarEvent(let event, let course) = item.type else { return nil }
            let timeStr = event.startDate.formatted(date: .omitted, time: .shortened)
            return ListWidgetData(
                id: "event-\(event.id)",
                title: event.summary,
                description: "\(timeStr) • \(course.name ?? "Unknown Course")"
            )
        }
    }

    init(
        todoManager: ToDoListManager = .init()
    ) {
        self.todoManager = todoManager
    }

    var fetchStatus: WidgetFetchStatus {
        get {
            if todoManager.fetchStatus == .loaded {
                return .loaded
            } else if todoManager.fetchStatus == .error {
                return .error
            } else {
                return .loading
            }
        }
        set { }
    }

    var widgetData: [ListWidgetData] {
        get {
            todayItems.map { item in
                switch item.type {
                case .todo(let todoItem):
                    return ListWidgetData(
                        id: "todo-\(todoItem.id)",
                        title: todoItem.title,
                        description: "Due today"
                    )
                case .calendarEvent(let event, let course):
                    let timeStr = event.startDate.formatted(date: .omitted, time: .shortened)
                    return ListWidgetData(
                        id: "event-\(event.id)",
                        title: event.summary,
                        description: "\(timeStr) • \(course.name ?? "Unknown Course")"
                    )
                }
            }
        }
        set { }
    }

    func fetchData(context: WidgetContext) async throws {
        guard let courseManager = context.courseManager else {
            fetchStatus = .error
            return
        }

        try await todoManager.fetchData(context: context)

        let calendarEvents = await fetchTodayCalendarEvents(courses: courseManager.activeCourses)

        await MainActor.run {
            aggregateTodayItems(calendarEvents: calendarEvents)
        }
    }

    private func fetchTodayCalendarEvents(courses: [Course]) async -> [(CanvasCalendarEvent, Course)] {
        var events: [(CanvasCalendarEvent, Course)] = []
        let today = Date()

        await withTaskGroup(of: [(CanvasCalendarEvent, Course)].self) { group in
            for course in courses {
                guard let icsURL = URL(string: course.calendarIcs ?? "") else {
                    continue
                }

                group.addTask {
                    let eventGroups = await ICSParser.parseEvents(from: icsURL, for: course)
                    let todayEvents = eventGroups
                        .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
                        .flatMap { $0.events }
                        .map { ($0, course) }
                    return todayEvents
                }
            }

            for await courseEvents in group {
                events.append(contentsOf: courseEvents)
            }
        }

        return events
    }

    private func aggregateTodayItems(calendarEvents: [(CanvasCalendarEvent, Course)]) {
        var items: [TodayItem] = []

        let today = Date()
        let twoDaysFromNow = Calendar.current.date(byAdding: .day, value: 2, to: today) ?? today
        let todosWithinTwoDays = todoManager.displayedToDoItems.filter { todoItem in
            guard let dueDate = todoItem.dueDate else { return false }
            return dueDate <= twoDaysFromNow
        }
        items.append(contentsOf: todosWithinTwoDays.map { TodayItem(.todo($0)) })

        items.append(contentsOf: calendarEvents.map { TodayItem(.calendarEvent($0.0, $0.1)) })

        self.todayItems = items.sorted { item1, item2 in
            let date1 = item1.sortDate
            let date2 = item2.sortDate
            return date1 < date2
        }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    func destinationView(for data: ListWidgetData) -> NavigationModel.Destination {
        guard let item = todayItems.first(where: { item in
            switch item.type {
            case .todo(let todoItem):
                return "todo-\(todoItem.id)" == data.id
            case .calendarEvent(let event, _):
                return "event-\(event.id)" == data.id
            }
        }) else {
            return .today
        }

        switch item.type {
        case .todo(let todoItem):
            return todoItem.navigationDestination() ?? .today
        case .calendarEvent(let event, let course):
            return .calendarEvent(event, course)
        }
    }
}


private struct TodayItem {
    enum ItemType {
        case todo(ToDoItem)
        case calendarEvent(CanvasCalendarEvent, Course)
    }

    let type: ItemType

    init(_ type: ItemType) {
        self.type = type
    }

    var sortDate: Date {
        switch type {
        case .todo(let todoItem):
            return todoItem.dueDate ?? Date()
        case .calendarEvent(let event, _):
            return event.startDate
        }
    }
}
