//
//  DashboardView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/8/25.
//

import SwiftUI

struct DashboardView: View {
    typealias ConfiguredWidget = WidgetStore.ConfiguredWidget

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(CourseManager.self) private var courseManager
    @Environment(ProfileManager.self) private var profileManager

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
            .animation(.spring, value: widgetStore.widgetConfigurations)
        }
        .scrollIndicators(.hidden)
        .background {
            VStack(spacing: 0) {
                DashboardMeshGradient(
                    colors: DashboardGradientColors
                        .getColors(from: courseManager.activeCourses)
                )
                .frame(height: 400)
                Spacer()
            }
            .ignoresSafeArea()
        }
        .navigationTitle("Dashboard")
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Settings", systemImage: "gear") {
                    navigationModel.showSettingsSheet.toggle()
                }
            }
        }
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if let currentUser = profileManager.currentUser {
                    Button {
                        navigationModel.showProfileSheet.toggle()
                    } label: {
                        #if os(macOS)
                        ProfilePicture(user: currentUser, size: 19)
                        #else
                        ProfilePicture(user: currentUser, size: 24)
                        #endif
                    }
                }
            }
        }
        .defaultNavigationDestination(courseID: "")
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
