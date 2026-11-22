//
//  CalendarDayCell.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 11/22/26.
//

import SwiftUI

/// One square of the week/month grid. Tapping it opens that day's timeline, where events are full-size tap targets.
struct CalendarDayCell: View {
    let date: Date
    let events: [CanvasCalendarEvent]
    /// Chips that fit before collapsing the rest into "+N".
    let maxChips: Int
    let onSelect: () -> Void

    private var visibleEvents: ArraySlice<CanvasCalendarEvent> {
        events.count > maxChips ? events.prefix(maxChips - 1) : events.prefix(maxChips)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(date, format: .dateTime.day())
                    .font(.headline)
                    .foregroundStyle(date.isInToday ? Color.white : .primary)
                    .padding(.horizontal, 6)
                    .background {
                        if date.isInToday {
                            Capsule().fill(.red)
                        }
                    }

                ForEach(visibleEvents) { event in
                    Text(event.summary)
                        .font(.caption)
                        .lineLimit(1)
                        .padding(.horizontal, 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            (event.course.rgbColors?.color ?? .accentColor).opacity(0.25),
                            in: .rect(cornerRadius: 4)
                        )
                }

                if events.count > visibleEvents.count {
                    Text("+\(events.count - visibleEvents.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .contentShape(.rect)
            .clipped()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(date, format: .dateTime.weekday(.wide).month().day()), ^[\(events.count) event](inflect: true)"))
    }
}
