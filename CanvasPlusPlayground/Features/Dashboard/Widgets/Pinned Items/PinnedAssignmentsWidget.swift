//
//  PinnedAssignmentsWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/18/25.
//

import SwiftUI

struct PinnedAssignmentsWidget: @MainActor ListWidget {
    static var widgetID: String { "pinned_assignments" }
    static var displayName: String { "Pinned Assignments" }
    static var description: String { "Quick access to your pinned assignments from all courses." }
    static var systemImage: String { "pin.fill" }
    static var color: Color { .orange }
    static var allowedSizes: [WidgetSize] { [.small, .medium, .large] }

    var title: String { "Pinned Assignments" }
    var destination: NavigationModel.Destination = .pinnedItems

    @MainActor
    var dataSource: PinnedAssignmentsDataSource = .init()
}
