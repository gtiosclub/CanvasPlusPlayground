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
                model.navigate = { evidence in
                    guard let destination = AssistantNavigation.destination(for: evidence, courseManager: courseManager) else { return false }
                    // Push on the screen the student is on, with a spring, instead of jumping tabs.
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                        navigationModel.push(destination)
                    }
                    return true
                }
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
