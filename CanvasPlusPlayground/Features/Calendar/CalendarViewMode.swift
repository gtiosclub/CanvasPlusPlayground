//
//  CalendarViewMode.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 11/22/26.
//

import Foundation

enum CalendarViewMode: String, CaseIterable, Identifiable {
    case day, week, month

    var id: Self { self }

    var title: String {
        switch self {
        case .day: "Day"
        case .week: "Week"
        case .month: "Month"
        }
    }

    var systemImage: String {
        switch self {
        case .day: "calendar.day.timeline.left"
        case .week: "rectangle.split.3x1"
        case .month: "calendar"
        }
    }

    /// The calendar unit one page of this mode covers, and that a swipe steps by.
    var component: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        }
    }
}
