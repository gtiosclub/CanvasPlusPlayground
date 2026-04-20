//
//  CalendarOverviewView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 4/20/26.
//

import SwiftUI
import SwiftData

struct CalendarOverviewView: View {
    @Environment(NavigationModel.self) private var navigationModel

    let course: Course

    // MARK: - State

    @State private var currentDate: Date = .now
    @State private var icsEvents: [CanvasCalendarEvent] = []
    @State private var assignmentManager: CourseAssignmentManager
    @State private var announcementManager: CourseAnnouncementManager
    @State private var quizzes: [Quiz] = []

    init(course: Course) {
        self.course = course
        self._assignmentManager = State(initialValue: CourseAssignmentManager(courseID: course.id))
        self._announcementManager = State(initialValue: CourseAnnouncementManager(course: course))
    }

    // MARK: - Week helpers

    private var calendar: Calendar { .current }

    private var currentWeekDates: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else {
            return [currentDate]
        }
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekInterval.start)
        }
    }

    private var weekTitle: String {
        let containsToday = currentWeekDates.contains { calendar.isDateInToday($0) }
        if containsToday { return "This Week" }
        guard let first = currentWeekDates.first, let last = currentWeekDates.last else { return "This Week" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: first)) – \(fmt.string(from: last))"
    }

    private func incrementWeek() {
        currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate
    }

    private func decrementWeek() {
        currentDate = calendar.date(byAdding: .day, value: -7, to: currentDate) ?? currentDate
    }

    // MARK: - Unified items

    private var allItems: [CourseCalendarItem] {
        var items: [CourseCalendarItem] = []

        // ICS calendar events (class meetings + canvas events)
        items += icsEvents.map { .calendarEvent($0) }

        // Assignment due dates
        items += assignmentManager.allAssignments
            .filter { $0.dueDate != nil }
            .map { .assignment($0) }

        // Announcement post dates
        items += announcementManager.displayedAnnouncements
            .filter { $0.date != nil }
            .map { .announcement($0) }

        // Quiz due dates
        items += quizzes
            .filter { $0.dueAt != nil }
            .map { .quiz($0) }

        return items
    }

    private func items(for date: Date) -> [CourseCalendarItem] {
        allItems
            .filter { item in
                guard let d = item.date else { return false }
                return calendar.isDate(d, inSameDayAs: date)
            }
            .sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Week navigation header
            HStack {
                Button { decrementWeek() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.plain)

                Text(weekTitle)
                    .font(.system(size: 22, weight: .semibold))
                    .frame(maxWidth: .infinity)

                Button { incrementWeek() } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.plain)
            }

            // 7-day grid
            HStack(alignment: .top, spacing: 4) {
                ForEach(currentWeekDates, id: \.self) { date in
                    DayColumn(
                        date: date,
                        items: items(for: date),
                        onTap: { navigate(to: $0) }
                    )
                }
            }
        }
        .padding(.bottom, 16)
        .task { await fetchAll() }
        .onChange(of: course.id) {
            assignmentManager = CourseAssignmentManager(courseID: course.id)
            announcementManager = CourseAnnouncementManager(course: course)
            Task { await fetchAll() }
        }
    }

    // MARK: - Fetch

    private func fetchAll() async {
        async let ics: [CanvasCalendarEventGroup] = ICSParser.parseEvents(
            from: URL(string: course.calendarIcs ?? ""),
            for: course
        )
        async let _assignments: () = assignmentManager.fetchAssignmentGroups()
        async let _announcements: () = announcementManager.fetchAnnouncements()
        async let _quizzes: () = fetchQuizzes()

        let groups = await ics
        icsEvents = groups.flatMap { $0.events }
        await _assignments
        await _announcements
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
        case .calendarEvent(let event):
            navigationModel.push(.calendarEvent(event, course))

        case .assignment(let api):
            guard let model = try? ModelContext.shared.fetch(
                FetchDescriptor<Assignment>(predicate: #Predicate { $0.id == api.id.asString })
            ).first else { return }
            navigationModel.push(.assignment(model))

        case .announcement(let topic):
            navigationModel.push(.announcement(topic))

        case .quiz(let quiz):
            navigationModel.push(.quiz(quiz))
        }
    }
}

// MARK: - Day Column

private struct DayColumn: View {
    let date: Date
    let items: [CourseCalendarItem]
    let onTap: (CourseCalendarItem) -> Void

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    private var dayAbbrev: String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }

    private var dayNumber: String {
        date.formatted(.dateTime.day())
    }

    var body: some View {
        VStack(spacing: 6) {
            // Day header
            VStack(spacing: 3) {
                Text(dayAbbrev)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                ZStack {
                    if isToday {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 32, height: 32)
                    }
                    Text(dayNumber)
                        .font(.system(size: 18, weight: isToday ? .bold : .regular))
                        .foregroundStyle(isToday ? .white : .primary)
                }
            }

            // Item chips
            ForEach(items) { item in
                Button { onTap(item) } label: {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 11))
                            .padding(.top, 1)
                        Text(item.title)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(item.accentColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(item.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Unified Calendar Item

private enum CourseCalendarItem: Identifiable {
    case calendarEvent(CanvasCalendarEvent)
    case assignment(AssignmentAPI)
    case announcement(DiscussionTopic)
    case quiz(Quiz)

    var id: String {
        switch self {
        case .calendarEvent(let e): "event-\(e.id)"
        case .assignment(let a):   "assignment-\(a.id)"
        case .announcement(let t): "announcement-\(t.id)"
        case .quiz(let q):         "quiz-\(q.id)"
        }
    }

    var date: Date? {
        switch self {
        case .calendarEvent(let e): e.startDate
        case .assignment(let a):   a.dueDate
        case .announcement(let t): t.date
        case .quiz(let q):         q.dueAt
        }
    }

    var title: String {
        switch self {
        case .calendarEvent(let e): e.summary
        case .assignment(let a):   a.name
        case .announcement(let t): t.title ?? ""
        case .quiz(let q):         q.title
        }
    }

    var systemImage: String {
        switch self {
        case .calendarEvent:  "calendar"
        case .assignment:     "circle.inset.filled"
        case .announcement:   "bubble"
        case .quiz:           "questionmark.circle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .calendarEvent:  .blue
        case .assignment:     .orange
        case .announcement:   .purple
        case .quiz:           .green
        }
    }
}
