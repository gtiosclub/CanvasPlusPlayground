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
            VStack(spacing: 24) {
                ForEach(WidgetStore.availableWidgetTypes) { widgetType in
                    WidgetTypeSection(widgetType: widgetType)
                }
            }
            .padding()
        }
        .navigationTitle("Widget Showcase")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

private struct WidgetTypeSection: View {
    let widgetType: WidgetStore.WidgetTypeInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(widgetType.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: widgetType.systemImage)
                        .font(.title3)
                        .foregroundStyle(widgetType.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(widgetType.displayName)
                        .font(.title2)
                        .bold()
                        .fontDesign(.rounded)

                    Text(widgetType.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
        }
    }
}
