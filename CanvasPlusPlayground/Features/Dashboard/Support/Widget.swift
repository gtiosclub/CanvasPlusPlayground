//
//  Widget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/25/25.
//

import Foundation
import SwiftUI

/// The base protocol that represents a dashboard widget component.
protocol Widget: Identifiable {
    associatedtype Body: View
    associatedtype Contents: View
    associatedtype DataSource: WidgetDataSource

    var title: String { get }
    var systemImage: String { get }
    var mainBody: Body { get }
    var contents: Contents { get }
    var destination: NavigationModel.Destination { get }
    var dataSource: DataSource { get set }
}

extension Widget {
    var mainBody: some View {
        DefaultWidgetBody(widget: self)
    }
}

/// A protocol defining the requirements for a data source used by a Dashboard Widget.
protocol WidgetDataSource {
    associatedtype Data: Identifiable

    var widgetData: [Data] { get set }
    var fetchStatus: WidgetFetchStatus { get set }
    func fetchData() async throws
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
                HStack {
                    Label(widget.title, systemImage: widget.systemImage)
                        .font(.headline)
                        .fontDesign(.rounded)
                        .bold()

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }

                Group {
                    switch widget.dataSource.fetchStatus {
                    case .loading: ProgressView().controlSize(.small)
                    case .loaded: AnyView(widget.contents)
                    case .error: Text("Could not load content")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .task {
                try? await widget.dataSource.fetchData()
            }
        }
        .buttonStyle(.plain)
    }
}
