//
//  DashboardView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/8/25.
//

import SwiftUI

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    typealias ConfiguredWidget = WidgetStore.ConfiguredWidget

    @Bindable var widgetStore = WidgetStore.shared

    var body: some View {
        ScrollView {
            Dashboard(
                vSpacing: vSpacing,
                maxSmallWidgetWidth: maxSmallWidgetWidth,
                maxMediumWidgetWidth: maxMediumWidgetWidth,
                maxLargeWidgetWidth: maxLargeWidgetWidth
            ) {
                ForEach(widgetStore.widgets.indices, id: \.self) { index in
                    let item = widgetStore.widgets[index]
                    item.widget.mainBody
                        .widgetSize(item.configuration.size)
                        .contextMenu {
                            widgetContextMenu(for: item, configBinding: configurationBinding(at: index))
                        }
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }

    private func configurationBinding(at index: Int) -> Binding<WidgetConfiguration> {
        let configID = widgetStore.widgets[index].configuration.id
        guard let configIndex = widgetStore.widgetConfigurations.firstIndex(where: { $0.id == configID }) else {
            fatalError("Configuration not found")
        }
        return $widgetStore.widgetConfigurations[configIndex]
    }

    @ViewBuilder
    private func widgetContextMenu(for item: ConfiguredWidget, configBinding: Binding<WidgetConfiguration>) -> some View {
        Picker("Size", selection: configBinding.size) {
            ForEach(item.widget.allowedSizes, id: \.self) { size in
                Label(size.label, systemImage: size.systemImage)
                    .tag(size)
            }
        }
        .pickerStyle(.inline)

        Divider()

        Button(role: .destructive) {
            widgetStore.removeWidget(configurationID: item.configuration.id)
        } label: {
            Label("Remove Widget", systemImage: "trash")
        }
    }

    var vSpacing: CGFloat {
        if horizontalSizeClass == .compact {
            60
        } else {
            20
        }
    }

    var maxSmallWidgetWidth: CGFloat? {
        guard horizontalSizeClass == .regular else { return nil }

        return 200
    }

    var maxMediumWidgetWidth: CGFloat? {
        guard horizontalSizeClass == .regular else { return nil }

        return 250
    }

    var maxLargeWidgetWidth: CGFloat? {
        guard horizontalSizeClass == .regular else { return nil }

        return 350
    }
}
