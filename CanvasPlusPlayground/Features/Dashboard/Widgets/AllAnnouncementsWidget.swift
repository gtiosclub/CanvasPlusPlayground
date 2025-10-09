//
//  AllAnnouncementsWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/30/25.
//

import SwiftUI

struct AllAnnouncementsWidget: @MainActor ListWidget {
    static var widgetID: String { "all_announcements" }

    var title: String = "Announcements"
    var systemImage: String = "bubble.right"
    var destination: NavigationModel.Destination = .allAnnouncements
    var allowedSizes: [WidgetSize] = [.small, .medium, .large]

    @MainActor
    var dataSource: AllAnnouncementsManager = .init()
}
