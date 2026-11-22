//
//  CalendarOverviewView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 4/20/26.
//

import SwiftUI
import SwiftData

/// Course Home widget: this week as a compact time grid of class meetings, calendar events and due dates.
struct CalendarOverviewView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(ToDoListManager.self) private var toDoListManager

    let course: Course
    let meetings: [CanvasCourseScheduleMeeting]

    @State private var icsEvents: [CanvasCalendarEvent] = []
    @State private var assignmentManager: CourseAssignmentManager
    @State private var quizzes: [Quiz] = []

    private let gridHeight: CGFloat = 240
    private let hourLabelWidth: CGFloat = 44

    init(course: Course, meetings: [CanvasCourseScheduleMeeting]) {
        self.course = course
        self.meetings = meetings
        self._assignmentManager = State(initialValue: CourseAssignmentManager(courseID: course.id))
    }

    private var calendar: Calendar { .current }

    private var weekDates: [Date] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: .now) else { return [.now] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.start) }
    }

    // MARK: - Items

    private var weekItems: [CourseCalendarItem] {
        var items: [CourseCalendarItem] = []

        for day in weekDates {
            let weekday = calendar.component(.weekday, from: day)
            items += meetings
                .filter { $0.weekday.number(calendar: calendar) == weekday }
                .compactMap { $0.interval(on: day) }
                .map { .meeting($0) }
        }
        items += icsEvents.map { .calendarEvent($0) }
        items += assignmentManager.allAssignments.filter { $0.dueDate != nil }.map { .assignment($0) }
        items += quizzes.filter { $0.dueAt != nil }.map { .quiz($0) }
        items += toDoListManager.displayedToDoItems
            .filter { $0.isUserCreated && $0.courseID.asString == course.id && $0.dueDate != nil }
            .map { .userTodo($0) }

        guard let first = weekDates.first, let last = weekDates.last,
              let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: last)) else { return items }
        let week = DateInterval(start: calendar.startOfDay(for: first), end: end)
        return items.filter { $0.interval.map { week.intersects($0) } ?? false }
    }

    /// Visible hour range: 8 AM–6 PM, stretched to fit this week's items.
    private var hourRange: ClosedRange<Int> {
        let starts = weekItems.compactMap { $0.interval?.start }.map { calendar.component(.hour, from: $0) }
        let ends = weekItems.compactMap { $0.interval?.end }.map {
            calendar.component(.hour, from: $0) + (calendar.component(.minute, from: $0) > 0 ? 1 : 0)
        }
        return min(8, starts.min() ?? 8)...max(18, ends.max() ?? 18)
    }

    // MARK: - Body

    var body: some View {
        CourseWidgetCard(
            title: "Calendar",
            systemImage: "calendar",
            accessoryTitle: "Expand",
            destination: .coursePage(.calendar, course)
        ) {
            VStack(spacing: 8) {
                dayHeaders
                timeGrid
            }
        }
        .task(id: course.id) { await fetchAll() }
    }

    private var dayHeaders: some View {
        HStack(spacing: 2) {
            Color.clear.frame(width: hourLabelWidth, height: 1)
            ForEach(weekDates, id: \.self) { date in
                let isToday = calendar.isDateInToday(date)
                VStack(spacing: 2) {
                    Text(date, format: .dateTime.weekday(.abbreviated))
                        .font(.caption)
                    Text(date, format: .dateTime.day())
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isToday ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                        .frame(width: 28, height: 28)
                        .background {
                            if isToday { Circle().fill(.tint) }
                        }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var timeGrid: some View {
        let range = hourRange
        let hourHeight = gridHeight / CGFloat(range.upperBound - range.lowerBound)

        return HStack(alignment: .top, spacing: 2) {
            ZStack(alignment: .topLeading) {
                ForEach(Array(stride(from: range.lowerBound, to: range.upperBound, by: 3)), id: \.self) { hour in
                    Text(calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now,
                         format: .dateTime.hour())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .offset(y: CGFloat(hour - range.lowerBound) * hourHeight)
                }
            }
            .frame(width: hourLabelWidth, height: gridHeight, alignment: .topLeading)

            ForEach(weekDates, id: \.self) { day in
                // shortcut: overlapping items on the same day draw on top of each other; lay out side by side if that gets common
                ZStack(alignment: .top) {
                    Color.clear
                    ForEach(weekItems.filter { item in
                        item.interval.map { calendar.isDate($0.start, inSameDayAs: day) } ?? false
                    }) { item in
                        chip(item, range: range, hourHeight: hourHeight)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: gridHeight)
            }
        }
    }

    @ViewBuilder
    private func chip(_ item: CourseCalendarItem, range: ClosedRange<Int>, hourHeight: CGFloat) -> some View {
        if let interval = item.interval {
            let startOfRange = calendar.date(bySettingHour: range.lowerBound, minute: 0, second: 0, of: interval.start) ?? interval.start
            let y = CGFloat(interval.start.timeIntervalSince(startOfRange) / 3600) * hourHeight
            let h = max(CGFloat(interval.duration / 3600) * hourHeight, 36)

            Button { navigate(to: item) } label: {
                Text(item.title)
                    .font(.caption2.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(item.accentColor.opacity(0.25), in: .rect(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .frame(height: h)
            .offset(y: y)
            .allowsHitTesting(!item.isMeeting)
        }
    }

    // MARK: - Fetch

    private func fetchAll() async {
        async let ics: [CanvasCalendarEventGroup] = ICSParser.parseEvents(
            from: URL(string: course.calendarIcs ?? ""),
            for: course
        )
        async let _assignments: () = assignmentManager.fetchAssignmentGroups()
        async let _quizzes: () = fetchQuizzes()

        icsEvents = await ics.flatMap { $0.events }
        await _assignments
        await _quizzes
    }

    private func fetchQuizzes() async {
        let request = CanvasRequest.getQuizzes(courseId: course.id)
        guard let fetched: [Quiz] = try? await CanvasService.shared.loadAndSync(request) else { return }
        quizzes = fetched
    }

    // MARK: - Navigation

    private func navigate(to item: CourseCalendarItem) {
        switch item {
        case .meeting:
            break

        case .calendarEvent(let event):
            navigationModel.push(.calendarEvent(event, course))

        case .assignment(let api):
            guard let model = try? ModelContext.shared.fetch(
                FetchDescriptor<Assignment>(predicate: #Predicate { $0.id == api.id.asString })
            ).first else { return }
            navigationModel.push(.assignment(model))

        case .quiz(let quiz):
            navigationModel.push(.quiz(quiz))

        case .userTodo:
            navigationModel.push(.allToDos)
        }
    }
}

// MARK: - Unified Calendar Item

private enum CourseCalendarItem: Identifiable {
    case meeting(DateInterval)
    case calendarEvent(CanvasCalendarEvent)
    case assignment(AssignmentAPI)
    case quiz(Quiz)
    case userTodo(ToDoItem)

    var id: String {
        switch self {
        case .meeting(let i):       "meeting-\(i.start.timeIntervalSince1970)"
        case .calendarEvent(let e): "event-\(e.id)"
        case .assignment(let a):    "assignment-\(a.id)"
        case .quiz(let q):          "quiz-\(q.id)"
        case .userTodo(let item):   "todo-\(item.id)"
        }
    }

    var isMeeting: Bool {
        if case .meeting = self { true } else { false }
    }

    /// Point-in-time items (due dates) get a one-hour block ending at the due time.
    var interval: DateInterval? {
        let dueDate: Date?
        switch self {
        case .meeting(let i):       return i
        case .calendarEvent(let e): return DateInterval(start: e.startDate, end: max(e.startDate, e.endDate))
        case .assignment(let a):    dueDate = a.dueDate
        case .quiz(let q):          dueDate = q.dueAt
        case .userTodo(let item):   dueDate = item.dueDate
        }
        return dueDate.map { DateInterval(start: $0.addingTimeInterval(-3600), end: $0) }
    }

    var title: String {
        switch self {
        case .meeting:              "Class"
        case .calendarEvent(let e): e.summary
        case .assignment(let a):    a.name
        case .quiz(let q):          q.title
        case .userTodo(let item):   item.title
        }
    }

    var accentColor: Color {
        switch self {
        case .meeting:       .green
        case .calendarEvent: .blue
        case .assignment:    .orange
        case .quiz:          .purple
        case .userTodo:      .teal
        }
    }
}
