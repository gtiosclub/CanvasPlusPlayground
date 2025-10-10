//
//  ListWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/29/25.
//

import SwiftUI

protocol ListWidget: Widget where DataSource: ListWidgetDataSource { }

extension ListWidget {
    var contents: some View {
        DefaultListWidgetBody(widget: self)
    }
}

protocol ListWidgetDataSource: WidgetDataSource where Data == ListWidgetData { }

struct ListWidgetData: Identifiable {
    var id: String
    var title: String
    var description: String
}

private struct DefaultListWidgetBody: View {
    let widget: any ListWidget

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(widget.dataSource.widgetData.prefix(3)) { item in
                NavigationLink(
                    value: widget.dataSource.destinationView(for: item)) {
                        Row(item: item)
                    }
                    .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private struct Row: View {
        let item: ListWidgetData

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title).bold()
                    Text(item.description)
                        .lineLimit(2)
                }
                Spacer()
            }
        }
    }
}
