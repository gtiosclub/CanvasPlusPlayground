//
//  AllToDosWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/4/25.
//

import SwiftUI

struct AllToDosWidget: @MainActor ListWidget {
    static var widgetID: String { "all_todos" }
    static var displayName: String { "To-Do List" }
    static var description: String { "Keep track of your upcoming assignments, quizzes, and tasks across all your courses." }
    static var systemImage: String { "checklist" }
    static var color: Color { .red }
    static var allowedSizes: [WidgetSize] { [.small, .medium, .large] }

    var title: String { "To-Do" }
    var destination: NavigationModel.Destination = .allToDos

    @MainActor
    var dataSource: ToDoListManager = .init()
}
