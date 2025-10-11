//
//  ListWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/29/25.
//

import SwiftUI

@MainActor
protocol ListWidget: Widget where DataSource: ListWidgetDataSource { }

extension ListWidget {
    var contents: some View {
        DefaultListWidgetBody(widget: self, size: .medium)
    }

    func adaptedContents(for size: WidgetSize) -> AnyView {
        AnyView(DefaultListWidgetBody(widget: self, size: size))
    }
}

protocol ListWidgetDataSource: WidgetDataSource where Data == ListWidgetData { }

struct ListWidgetData: Identifiable {
    var id: String
    var title: String
    var description: String
}

private struct DefaultListWidgetBody: View {
    @Environment(\.isWidgetNavigationEnabled) var isWidgetNavigationEnabled: Bool

    let widget: any ListWidget
    let size: WidgetSize

    private var itemLimit: Int {
        switch size {
        case .small: return 2
        case .medium: return 3
        case .large: return 6
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: size == .small ? 4 : 8) {
            ForEach(widget.dataSource.widgetData.prefix(itemLimit)) { item in
                Group {
                    if isWidgetNavigationEnabled {
                        NavigationLink(
                            value: widget.dataSource.destinationView(for: item)) {
                                Row(item: item, size: size)
                            }
                    } else {
                        Row(item: item, size: size)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private struct Row: View {
        let item: ListWidgetData
        let size: WidgetSize

        private var showDescription: Bool {
            size != .small
        }

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: size == .small ? 2 : 4) {
                    Text(item.title)
                        .bold()
                        .font(size == .small ? .caption : .body)
                        .lineLimit(1)

                    if showDescription {
                        Text(item.description)
                            .font(size == .large ? .body : .caption)
                            .lineLimit(size == .large ? 3 : 2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
    }
}
