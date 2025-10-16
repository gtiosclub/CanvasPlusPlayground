//
//  RecentItemsWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/11/25.
//

import SwiftUI

struct RecentItemsWidget: @MainActor ListWidget {
    static var widgetID: String { "recent_items" }
    static var displayName: String { "Recent Items" }
    static var description: String { "Quick access to your recently viewed assignments, quizzes, files, and announcements." }
    static var systemImage: String { "clock" }
    static var color: Color { .accentColor }
    static var allowedSizes: [WidgetSize] { [.small, .medium, .large] }

    var title: String { Self.displayName }
    var destination: NavigationModel.Destination = .recentItems

    @MainActor
    var dataSource: RecentItemsManager = .shared
}
