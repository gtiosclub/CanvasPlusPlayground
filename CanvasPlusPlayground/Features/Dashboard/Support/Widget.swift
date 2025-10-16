//
//  Widget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/25/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
/// The base protocol that represents a dashboard widget component.
protocol Widget: Identifiable where ID == String {
    associatedtype Body: View
    associatedtype Contents: View
    associatedtype DataSource: WidgetDataSource

    static var widgetID: String { get }
    static var displayName: String { get }
    static var description: String { get }
    static var systemImage: String { get }
    static var color: Color { get }
    static var allowedSizes: [WidgetSize] { get }
    var title: String { get }
    var mainBody: Body { get }
    var contents: Contents { get }
    func adaptedContents(for size: WidgetSize) -> AnyView
    var destination: NavigationModel.Destination { get }
    var dataSource: DataSource { get set }
}

extension Widget {
    var id: String { Self.widgetID }

    // Instance properties that delegate to static
    var systemImage: String { Self.systemImage }
    var color: Color { Self.color }
    var allowedSizes: [WidgetSize] { Self.allowedSizes }
}

extension Widget {
    var mainBody: some View {
        DefaultWidgetBody(widget: self)
    }

    static var color: Color {
        .accentColor
    }

    static var allowedSizes: [WidgetSize] {
        [.small, .medium, .large]
    }

    func adaptedContents(for size: WidgetSize) -> AnyView {
        AnyView(contents)
    }
}

class WidgetContext {
    enum RefreshTriggerSubject: Equatable {
        case allWidgets
        case singleWidget(id: String)
    }

    static let shared: WidgetContext = .init()

    private(set) var courseManager: CourseManager?
    var refreshTrigger: PassthroughSubject<RefreshTriggerSubject, Never> = .init()

    private init() { }

    static func setup(courseManager: CourseManager) {
        shared.courseManager = courseManager
    }

    @MainActor func requestToRefreshAllWidgets() {
        refreshTrigger.send(.allWidgets)
    }

    @MainActor func requestToRefreshWidget(widget: any Widget.Type) {
        refreshTrigger.send(.singleWidget(id: widget.widgetID))
    }
}

/// A protocol defining the requirements for a data source used by a Dashboard Widget.
protocol WidgetDataSource {
    associatedtype Data: Identifiable

    var widgetData: [Data] { get set }
    var fetchStatus: WidgetFetchStatus { get set }
    func fetchData(context: WidgetContext) async throws
    func destinationView(for data: Data) -> NavigationModel.Destination
}

enum WidgetFetchStatus {
    case loading
    case loaded
    case error
}

struct DefaultWidgetBody: View {
    let widget: any Widget
    @Environment(\.widgetSize) private var widgetSize: WidgetSize
    @Environment(\.isWidgetNavigationEnabled) private var isWidgetNavigationEnabled: Bool

    private func shouldRefresh(trigger: WidgetContext.RefreshTriggerSubject) -> Bool {
        guard case .singleWidget(let requestedID) = trigger else {
            return trigger == .allWidgets
        }

        return widget.id == requestedID
    }

    var body: some View {
        Group {
            if isWidgetNavigationEnabled {
                NavigationLink(value: widget.destination) {
                    label
                }
            } else {
                label
            }
        }
        .buttonStyle(.plain)
    }

    private var label: some View {
        VStack {
            Header(widget: widget)

            ContentView(widget: widget, widgetSize: widgetSize)

            Spacer()
        }
        .task(id: widgetSize) {
            // Only fetch if not already loaded
            guard widget.dataSource.fetchStatus != .loaded else {
                return
            }
            try? await widget.dataSource
                .fetchData(context: WidgetContext.shared)
        }
        .onReceive(WidgetContext.shared.refreshTrigger) { trigger in
            if shouldRefresh(trigger: trigger) {
                Task {
                    try? await widget.dataSource
                        .fetchData(context: WidgetContext.shared)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16.0)
                .fill(.thinMaterial)
                .strokeBorder(.ultraThickMaterial)
        }
    }

    private struct ContentView: View {
        let widget: any Widget
        let widgetSize: WidgetSize

        var body: some View {
            Group {
                switch widget.dataSource.fetchStatus {
                case .loading: ProgressView().controlSize(.small)
                case .loaded: widget.adaptedContents(for: widgetSize)
                case .error: Text("Could not load content")
                }
            }
        }
    }

    private struct Header: View {
        let widget: any Widget

        var body: some View {
            HStack {
                Label(widget.title, systemImage: widget.systemImage)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .bold()

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(widget.color)
        }
    }
}

private struct WidgetNavigationEnabledEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    /// Determines whether tapping on a widget or its contents navigates to a destination.
    var isWidgetNavigationEnabled: Bool {
        get { self[WidgetNavigationEnabledEnvironmentKey.self] }
        set { self[WidgetNavigationEnabledEnvironmentKey.self] = newValue }
    }
}
