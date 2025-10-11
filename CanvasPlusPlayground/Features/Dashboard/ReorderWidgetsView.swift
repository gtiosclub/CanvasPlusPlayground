//
//  ReorderWidgetsView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/10/25.
//

import SwiftUI

struct ReorderWidgetsView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var widgetStore = WidgetStore.shared

    var body: some View {
        List {
            ForEach(widgetStore.widgetConfigurations) { config in
                if let widgetTypeInfo = widgetStore.widgetTypeInfo(for: config) {
                    Label(
                        widgetTypeInfo.displayName,
                        systemImage: widgetTypeInfo.systemImage
                    )
                    .font(.title3)
                    .bold()
                    .listItemTint(.fixed(widgetTypeInfo.color))
                }
            }
            .onMove { source, destination in
                widgetStore.reorderWidgets(from: source, to: destination)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Reorder Widgets")
        #if os(iOS)
        .environment(\.editMode, .constant(.active))
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}
