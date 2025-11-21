//
//  GlobalCalendarView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/26/25.
//

import SwiftUI

struct GlobalCalendarView: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State var calendarManager = GlobalCalendarManager()
    @Environment(CourseManager.self) var courseManager

    private var calendarColumns: some View {
        HStack(spacing: 0) {
            ForEach(Array(calendarManager.currentWeekDates.enumerated()), id: \.element) { index, date in
                if index > 0 {
                    Divider()
                }
                DayColumn(date: date, events: calendarManager.calendarEvents.filter { event in
                    Calendar.current.isDate(event.startDate, inSameDayAs: date)
                })
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let minColumnHeight: CGFloat = 600 // Estimate or adjust for your minimum expected height per column
            let shouldScroll = minColumnHeight > geo.size.height
            Group {
                if shouldScroll {
                    ScrollView(.vertical) {
                        calendarColumns
                    }
                } else {
                    calendarColumns
                }
            }
        }
        .task {
            if let horizontalSizeClass {
                setDisplayMode(sizeClass: horizontalSizeClass)
            }
            await calendarManager.getCalendarEventsForCourses(courses: courseManager.favoritedCourses)
        }
        .toolbar {
            ToolbarItem {
                Button("Previous Week", systemImage: "chevron.left", action: calendarManager.decrementWeek)
            }
            ToolbarItem {
                Button("Next Week", systemImage: "chevron.right", action: calendarManager.incrementWeek)
            }
            ToolbarItem {
                Button("Current", action: calendarManager.setToNow)
            }
        }
        .onChange(of: horizontalSizeClass) { newValue in
            guard let newValue else { return }
            setDisplayMode(sizeClass: newValue)
        }
    }

    private struct DayColumn: View {
        let date: Date
        let events: [CanvasCalendarEvent]

        private var sortedEvents: [CanvasCalendarEvent] {
            events.sorted { $0.startDate < $1.startDate }
        }
        var backgroundTint: Color? {
            date.isInToday ? .blue.opacity(0.15) : nil
        }

        var body: some View {
            VStack {
                Text(date.dayNumberString)
                VStack(spacing: 5) {
                    ForEach(sortedEvents) { event in
                        EventCardView(event: event)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(backgroundTint ?? .clear)
        }
    }

    private struct EventCardView: View {
        let event: CanvasCalendarEvent

        private var timeRangeString: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
        }

        var body: some View {
            NavigationLink(value: NavigationModel.Destination.calendarEvent(event, event.course)) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.summary)
                            .bold()
                        Text(timeRangeString)
                            .font(.subheadline)
                            .foregroundColor(.secondary)


                        Text(event.location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .lineLimit(nil)
                    Spacer()
                }
                .padding(5)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: .rect(cornerRadius: 8))
                .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)
        }
    }

    func setDisplayMode(sizeClass: UserInterfaceSizeClass) {
        calendarManager.displayMode = sizeClass == .compact ? .compact : .entireWeek
    }
}
