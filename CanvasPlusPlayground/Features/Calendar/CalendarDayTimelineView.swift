//
//  CalendarDayTimelineView.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 11/22/26.
//

import SwiftUI

/// A scrolling 24-hour grid with events positioned by start time and sized by duration.
struct CalendarDayTimelineView: View {
    let date: Date
    let events: [CanvasCalendarEvent]
    let calendar: Calendar

    @ScaledMetric private var hourHeight: CGFloat = 60
    @ScaledMetric private var labelWidth: CGFloat = 52
    @ScaledMetric private var minEventHeight: CGFloat = 24

    var body: some View {
        let dayStart = calendar.startOfDay(for: date)
        let slots = GlobalCalendarManager.timelineColumns(for: events)

        ScrollView {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<24, id: \.self) { hour in
                        HStack(alignment: .top, spacing: 8) {
                            Text(calendar.date(byAdding: .hour, value: hour, to: dayStart) ?? dayStart, format: .dateTime.hour())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: labelWidth, alignment: .trailing)
                                .offset(y: -8)
                            Rectangle()
                                .fill(.separator)
                                .frame(height: 0.5)
                        }
                        .frame(height: hourHeight, alignment: .top)
                    }
                }

                GeometryReader { proxy in
                    let columnArea = proxy.size.width - labelWidth - 8
                    ForEach(events) { event in
                        let slot = slots[event.id] ?? (column: 0, columns: 1)
                        let width = columnArea / CGFloat(max(slot.columns, 1))
                        let top = minutes(from: dayStart, to: event.startDate) * hourHeight / 60
                        let bottom = min(minutes(from: dayStart, to: event.endDate), 24 * 60) * hourHeight / 60

                        CalendarEventCard(event: event)
                            .frame(width: width - 2, height: max(bottom - top, minEventHeight))
                            .offset(x: labelWidth + 8 + CGFloat(slot.column) * width, y: top)
                    }
                }
            }
            .frame(height: hourHeight * 24)
            .padding(.vertical, 12)
            .padding(.trailing, 8)
        }
        // Opens around 8 AM instead of midnight.
        .defaultScrollAnchor(UnitPoint(x: 0.5, y: 8.0 / 24))
    }

    private func minutes(from start: Date, to end: Date) -> CGFloat {
        CGFloat(end.timeIntervalSince(start) / 60)
    }
}
