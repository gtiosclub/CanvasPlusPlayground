//
//  PinnedAnnouncementsWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/18/25.
//

import SwiftUI

struct PinnedAnnouncementsWidget: @MainActor ListWidget {
    static var widgetID: String { "pinned_announcements" }
    static var displayName: String { "Pinned Announcements" }
    static var description: String { "Quick access to your pinned announcements from all courses." }
    static var systemImage: String { "pin.fill" }
    static var color: Color { .orange }
    static var allowedSizes: [WidgetSize] { [.small, .medium, .large] }

    var title: String { "Pinned Announcements" }
    var destination: NavigationModel.Destination = .pinnedItems

    @MainActor
    var dataSource: PinnedAnnouncementsDataSource = .init()
}
