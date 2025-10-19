//
//  TodayWidget.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 10/19/25.
//


import SwiftUI

struct TodayWidget: @MainActor ListWidget {
    static var widgetID: String { "today" }
    static var displayName: String { "Today" }
    static var description: String { "View all your todos, announcements, and calendar events for today in one place." }
    static var systemImage: String { "calendar.badge.clock" }
    static var color: Color { .blue }
    static var allowedSizes: [WidgetSize] { [.small, .medium, .large] }

    var title: String { "Today" }
    var destination: NavigationModel.Destination = .today

    @MainActor
    var dataSource: TodayDataSource = .init()
}