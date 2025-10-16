//
//  UnreadAnnouncementsWidget.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/11/25.
//

import SwiftUI

struct UnreadAnnouncementsCountWidget: @MainActor BigNumberWidget {
    static var widgetID: String { "unread_announcements_count" }
    static var displayName: String { "Unread Announcements" }
    static var description: String { "Get a quick count of all your unread announcements." }
    static var systemImage: String { "bubble.right" }
    static var color: Color { .accentColor }
    static var widgetGroups: [WidgetGroup] { [.announcements] }

    var title: String { Self.displayName }
    var destination: NavigationModel.Destination = .allAnnouncements

    @MainActor
    var dataSource: AllAnnouncementsManager = .init()
}
