//
//  AllToDosWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/4/25.
//

import SwiftUI

struct AllToDosWidget: @MainActor ListWidget {
    static var widgetID: String { "all_todos" }

    var title: String = "To-Do"
    var systemImage: String = "checklist"
    var color: Color = .red
    var destination: NavigationModel.Destination = .allToDos

    @MainActor
    var dataSource: ToDoListManager = .init()
}
