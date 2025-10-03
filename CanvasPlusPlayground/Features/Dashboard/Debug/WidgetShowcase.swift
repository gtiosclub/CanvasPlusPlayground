//
//  WidgetShowcase.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/30/25.
//

import SwiftUI

struct WidgetShowcase: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(WidgetShowcaseSection.all) { section in
                    SectionView(section: section)
                    Divider()
                }
            }
            .padding()
        }
        .navigationTitle("Widget Showcase")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    fileprivate struct SectionView: View {
        let section: WidgetShowcaseSection

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(section.title)
                    .font(.title)
                    .bold()
                    .fontDesign(.rounded)

                Text(section.description)
                    .font(.title3)
                    .fontWeight(.light)

                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(section.widgets, id: \.id) { widget in
                            widget.mainBody
                                .disabled(true)
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }
}

fileprivate struct WidgetShowcaseSection: Identifiable {
    var id: String { title }
    let title: String
    let description: String
    let widgets: [AnyWidget]

    @MainActor
    static let all: [Self] = [
        .init(
            title: "Announcements",
            description: "View all announcements",
            widgets: [.init(AllAnnouncementsWidget())]
        ),
        .init(
            title: "Announcements",
            description: "View all announcements",
            widgets: [.init(AllAnnouncementsWidget())]
        ),
        .init(
            title: "Announcements",
            description: "View all announcements",
            widgets: [.init(AllAnnouncementsWidget())]
        )
    ]
}
