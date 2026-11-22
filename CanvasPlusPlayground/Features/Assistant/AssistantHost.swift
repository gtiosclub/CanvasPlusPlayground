//
//  AssistantHost.swift
//  CanvasPlusPlayground
//

import SwiftUI

/// Owns the assistant for the main window and keeps it told which screen is showing.
@available(iOS 26.0, macOS 26.0, *)
struct AssistantHost: View {
    let navigationModel: NavigationModel
    let courseManager: CourseManager
    let toDoListManager: ToDoListManager

    @State private var model = AssistantModel()

    var body: some View {
        AgentOrbOverlay(model: model)
            .environment(courseManager)
            .onAppear {
                model.configure(dataSource: CanvasCacheAgentDataSource(courseManager: courseManager, toDoListManager: toDoListManager))
                syncContext()
            }
            .onChange(of: navigationModel.breadcrumbs) { syncContext() }
            .onChange(of: navigationModel.selectedTab) { syncContext() }
    }

    private func syncContext() {
        model.updateContext(AssistantPageContext(navigation: navigationModel) { id in
            courseManager.course(withID: id)?.displayName
        })
    }
}
