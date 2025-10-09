//
//  Widget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/25/25.
//

import Foundation
import SwiftUI

@MainActor
/// The base protocol that represents a dashboard widget component.
protocol Widget: Identifiable where ID == String {
    associatedtype Body: View
    associatedtype Contents: View
    associatedtype DataSource: WidgetDataSource

    static var widgetID: String { get }
    var title: String { get }
    var systemImage: String { get }
    var color: Color { get }
    var mainBody: Body { get }
    var contents: Contents { get }
    var destination: NavigationModel.Destination { get }
    var dataSource: DataSource { get set }
}

extension Widget {
    var id: String { Self.widgetID }
}

extension Widget {
    var mainBody: some View {
        DefaultWidgetBody(widget: self)
    }

    var color: Color {
        .accentColor
    }
}

class WidgetContext {
    static let shared: WidgetContext = .init()

    private(set) var courseManager: CourseManager?

    private init() { }

    static func setup(courseManager: CourseManager) {
        shared.courseManager = courseManager
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

    var body: some View {
        NavigationLink(value: widget.destination) {
            VStack {
                Header(widget: widget)

                Group {
                    switch widget.dataSource.fetchStatus {
                    case .loading: ProgressView().controlSize(.small)
                    case .loaded: AnyView(widget.contents)
                    case .error: Text("Could not load content")
                    }
                }
            }
            .task {
                try? await widget.dataSource
                    .fetchData(context: WidgetContext.shared)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 16.0)
                    .fill(.thickMaterial)
                    .strokeBorder(.thickMaterial)
            }
        }
        .buttonStyle(.plain)
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
