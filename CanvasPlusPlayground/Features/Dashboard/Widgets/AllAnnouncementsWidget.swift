//
//  AllAnnouncementsWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/30/25.
//

import SwiftUI

struct AllAnnouncementsWidget: @MainActor ListWidget {
    static var widgetID: String { "all_announcements" }
    static var displayName: String { "Announcements" }
    static var description: String { "Stay updated with the latest course announcements and important information from your instructors." }
    static var systemImage: String { "bubble.right" }
    static var color: Color { .accentColor }
    static var allowedSizes: [WidgetSize] { [.small, .medium, .large] }
    static var widgetGroups: [WidgetGroup] { [.announcements] }

    var title: String { Self.displayName }
    var destination: NavigationModel.Destination = .allAnnouncements

    @MainActor
    var dataSource: AllAnnouncementsManager = .init()
}
