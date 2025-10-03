//
//  AllAnnouncementsWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/30/25.
//

import SwiftUI

struct AllAnnouncementsWidget: ListWidget {
    var id: String = "all_announcements"
    var title: String = "Announcements"
    var systemImage: String = "bubble.right"
    var destination: NavigationModel.Destination = .allAnnouncements

    @MainActor
    var dataSource: AllAnnouncementsManager = .init()
}
