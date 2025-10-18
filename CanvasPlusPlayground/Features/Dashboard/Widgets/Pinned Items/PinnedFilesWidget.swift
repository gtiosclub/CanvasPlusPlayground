//
//  PinnedFilesWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/18/25.
//

import SwiftUI

struct PinnedFilesWidget: @MainActor ListWidget {
    static var widgetID: String { "pinned_files" }
    static var displayName: String { "Pinned Files" }
    static var description: String { "Quick access to your pinned files from all courses." }
    static var systemImage: String { "pin.fill" }
    static var color: Color { .orange }
    static var allowedSizes: [WidgetSize] { [.small, .medium, .large] }

    var title: String { "Pinned Files" }
    var destination: NavigationModel.Destination = .pinnedItems

    @MainActor
    var dataSource: PinnedFilesDataSource = .init()
}
