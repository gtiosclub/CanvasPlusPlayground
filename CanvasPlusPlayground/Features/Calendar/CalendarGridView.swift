//
//  CalendarGridView.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 11/22/26.
//

import SwiftUI

/// Week (one row) and month (5–6 rows) layouts: a Sunday-first weekday header over equal-height rows of day cells.
struct CalendarGridView: View {
    let manager: GlobalCalendarManager

    var body: some View {
        let dates = manager.visibleDates
        let blanks = manager.leadingBlankDays
        let rowCount = (blanks + dates.count + 6) / 7
        let maxChips = manager.viewMode == .month ? 3 : 12

        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { column in
                    Text(manager.calendar.veryShortStandaloneWeekdaySymbols[column])
                        .font(.subheadline)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 4)

            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { column in
                        let index = row * 7 + column - blanks
                        Group {
                            if dates.indices.contains(index) {
                                CalendarDayCell(
                                    date: dates[index],
                                    events: manager.events(on: dates[index]),
                                    maxChips: maxChips
                                ) {
                                    manager.showDay(dates[index])
                                }
                            } else {
                                Color.clear
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay {
                            Rectangle().strokeBorder(.separator, lineWidth: 0.5)
                        }
                    }
                }
            }
        }
    }
}
