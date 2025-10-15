//
//  TodayWidget.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 10/11/25.
//


import SwiftUI


struct TodayWidget: @MainActor ListWidget {
    static var widgetID: String { "today" }
    static var displayName: String { "Today" }
    static var description: String { "View today's schedule including courses, announcements, and assignments due today all in one place." }
    static var systemImage: String { "calendar.day.timeline.left" }
    static var color: Color { .blue }
    static var allowedSizes: [WidgetSize] { [.large] }

    var title: String { "Today" }
    var destination: NavigationModel.Destination = .today

    var dataSource: TodayWidgetManager = .init()
}


