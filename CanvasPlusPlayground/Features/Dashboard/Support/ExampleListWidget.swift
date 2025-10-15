//
//  ExampleListWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/29/25.
//

#if DEBUG
import SwiftUI
import Combine

fileprivate struct ExampleListWidget: @MainActor ListWidget {
    static var widgetID: String { "steps_widget" }
    static var displayName: String { "Steps" }
    static var description: String { "Display latest steps data." }
    static var systemImage: String { "figure.walk" }
    static var color: Color { .orange }

    var title: String { "Steps" }
    var destination: NavigationModel.Destination = .course(.sample)
    @State var dataSource: StepsDataSource = .init()
}

@Observable
private class StepsDataSource: ListWidgetDataSource {
    var fetchStatus: WidgetFetchStatus = .loading
    var widgetData: [ListWidgetData] = []

    func fetchData(context: WidgetContext) async throws {
        fetchStatus = .loading
        // Simulate async fetch
        try await Task.sleep(nanoseconds: 600_000_000)
        widgetData = [
            ListWidgetData(id: "today", title: "Today", description: "6,235 steps"),
            ListWidgetData(id: "yesterday", title: "Yesterday", description: "7,540 steps")
        ]

        fetchStatus = .loaded
    }

    func destinationView(for data: ListWidgetData) -> NavigationModel.Destination {
        .course(.sample)
    }
}

#Preview {
    @Previewable @State var navModel = NavigationModel()

    NavigationStack(path: $navModel.navigationPath) {
        ExampleListWidget().mainBody
            .defaultNavigationDestination(courseID: Course.sample.id)
    }
    .environment(navModel)
}
#endif
