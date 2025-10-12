//
//  ToDoCountWidget.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/11/25.
//

import SwiftUI

struct ToDoCountWidget: @MainActor BigNumberWidget {
    static var widgetID: String { "todo_count" }
    static var displayName: String { "To-Do Count" }
    static var description: String { "Get a quick count of all your to-do items." }
    static var systemImage: String { "checklist" }
    static var color: Color { .red }
    static var allowedSizes: [WidgetSize] { [.small] }

    var title: String { Self.displayName }
    var destination: NavigationModel.Destination = .allToDos

    @MainActor
    var dataSource: ToDoListManager = .init()
}
