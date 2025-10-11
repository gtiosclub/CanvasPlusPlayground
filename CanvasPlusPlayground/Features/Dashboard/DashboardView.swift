//
//  DashboardView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/8/25.
//

import SwiftUI

fileprivate typealias ConfiguredWidget = WidgetStore.ConfiguredWidget

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(CourseManager.self) private var courseManager
    @Environment(ProfileManager.self) private var profileManager

    @Bindable var widgetStore = WidgetStore.shared
    @State private var showWidgetShowcase = false
    @State private var showReorderWidgets = false

    var body: some View {
        ScrollView {
            Dashboard(
                vSpacing: vSpacing,
                maxSmallWidgetWidth: maxSmallWidgetWidth,
                maxMediumWidgetWidth: maxMediumWidgetWidth,
                maxLargeWidgetWidth: maxLargeWidgetWidth
            ) {
                ForEach(widgetStore.widgets) { item in
                    item.widget.mainBody
                        .widgetSize(item.configuration.size)
                        .contextMenu {
                            WidgetContextMenu(item: item)
                        }
                        .transition(.scale.combined(with: .blurReplace))
                }
            }
            .padding()
            .animation(.spring, value: widgetStore.widgetConfigurations)
        }
        .courseGradientBackground(courses: courseManager.activeCourses)
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
            ToolbarItem(placement: .primaryAction) {
                Menu("Customize...", systemImage: "ellipsis") {
                    Button(
                        "Add Widgets...",
                        systemImage: "widget.large.badge.plus"
                    ) {
                        showWidgetShowcase = true
                    }

                    Button(
                        "Reorder Widgets...",
                        systemImage: "arrow.up.arrow.down"
                    ) {
                        showReorderWidgets = true
                    }
                    .disabled(widgetStore.widgets.isEmpty)
                }
            }

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
        .sheet(isPresented: $showWidgetShowcase) {
            NavigationStack {
                WidgetShowcase()
            }
            #if os(macOS)
            .frame(width: 650, height: 550)
            #endif
        }
        .sheet(isPresented: $showReorderWidgets) {
            NavigationStack {
                ReorderWidgetsView()
            }
            #if os(macOS)
            .frame(width: 500, height: 600)
            #endif
        }
        .defaultNavigationDestination(courseID: "")
    }

    private var vSpacing: CGFloat {
        horizontalSizeClass == .compact ? 80 : 20
    }

    private var maxSmallWidgetWidth: CGFloat? {
        guard horizontalSizeClass == .regular else { return nil }

        return 200
    }

    private var maxMediumWidgetWidth: CGFloat? {
        guard horizontalSizeClass == .regular else { return nil }

        return 250
    }

    private var maxLargeWidgetWidth: CGFloat? {
        guard horizontalSizeClass == .regular else { return nil }

        return 350
    }
}

private struct WidgetContextMenu: View {
    let item: ConfiguredWidget
    @Bindable var widgetStore = WidgetStore.shared

    var body: some View {
        if let configurationBinding {
            Picker("Size", selection: configurationBinding.size) {
                ForEach(item.widget.allowedSizes, id: \.self) { size in
                    Label(size.label, systemImage: size.systemImage)
                        .tag(size)
                }
            }
            .pickerStyle(.inline)

            Divider()
        }

        Button(role: .destructive) {
            widgetStore.removeWidget(configurationID: item.configuration.id)
        } label: {
            Label("Remove Widget", systemImage: "trash")
        }
    }

    var configurationBinding: Binding<WidgetConfiguration>? {
        let configID = item.configuration.id
        guard let configIndex = widgetStore.widgetConfigurations.firstIndex(where: { $0.id == configID }) else {
            return nil
        }
        return $widgetStore.widgetConfigurations[configIndex]
    }
}
