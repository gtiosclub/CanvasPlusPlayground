//
//  SettingsView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/11/24.
//

import SwiftUI

struct SettingsView: View {
    #if DEBUG
    @Environment(\.openWindow) private var openWindow
    @Environment(PinnedItemsManager.self) private var pinnedItemManager
    @Environment(CourseManager.self) private var courseManager

    @State private var selectedItem: (any PickableItem)?
    @State private var selectedCourseForItemPicker: Course?
    @State private var showWidgetShowcase = false
    #endif

    @Environment(\.dismiss) private var dismiss
    @Environment(RecentItemsManager.self) private var recentItemsManager

    @State private var showChangeAccessToken: Bool = false

    @State private var navigationModel = NavigationModel()

    var body: some View {
        NavigationStack {
            mainBody
        }
        #if DEBUG
        .sheet(item: $selectedCourseForItemPicker) {
            CourseItemPicker(course: $0, selectedItem: $selectedItem)
        }
        .sheet(isPresented: $showWidgetShowcase) {
            NavigationStack {
                WidgetShowcase()
            }
            .environment(courseManager)
        }
        #endif
        .sheet(isPresented: $showChangeAccessToken) {
            NavigationStack {
                SetupView()
            }
        }
    }

    private var mainBody: some View {
        Form {
            loginSettings
            recentItemsSettings
            if #available(macOS 26.0, iOS 26.0, *) {
                intelligenceSettings
            }
            #if DEBUG
            debugSettings
            #endif
        }
        .formStyle(.grouped)
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        #endif
        .navigationTitle("Settings")
    }

    private var loginSettings: some View {
        Section {
            Button("Change Access Token", systemImage: "key") {
                showChangeAccessToken = true
            }
        } header: {
            Label("Login", systemImage: "lock.fill")
        }
    }

    @ViewBuilder
    private var recentItemsSettings: some View {
        @Bindable var recentItemsManager = recentItemsManager

        Section {
            Picker("Max Recent Items", selection: $recentItemsManager.maxRecentItems) {
                ForEach(RecentItemsManager.maxRecentItemsOptions, id: \.self) { option in
                    Text("\(option)").tag(option)
                }
            }

            Button("Clear Recent Items", systemImage: "clock.arrow.circlepath") {
                recentItemsManager.clearAllRecentItems()
            }
        } header: {
            Label("Recent Items", systemImage: "clock")
        } footer: {
            Text("Currently tracking \(recentItemsManager.recentItems.count) recent items.")
        }
    }

    @available(macOS 26.0, iOS 26.0, *)
    private var intelligenceSettings: some View {
        Section {
            Text(IntelligenceSupport.modelAvailabilityDescription)
        } header: {
            Label("Intelligence", systemImage: "wand.and.stars")
        }
        .foregroundStyle(.secondary)
    }

    #if DEBUG
    @ViewBuilder
    private var debugSettings: some View {
        @Bindable var navigationModel = navigationModel

        Section {
            Group {
                Button("Show Widget Showcase", systemImage: "widget.small") {
                    showWidgetShowcase = true
                }
                Button("View Item Picker", systemImage: "filemenu.and.selection") {
                    selectedCourseForItemPicker = courseManager.activeCourses.first
                }

                #if os(macOS)
                if #available(macOS 26.0, *) {
                    Button("IGC Playground", systemImage: "plus.forwardslash.minus") {
                        openWindow(id: IGCPlayground.windowID)
                    }
                }
                #endif

                Button("Clear Pinned Items", systemImage: "trash") {
                    pinnedItemManager.clearAllPinnedItems()
                }

                Button("Clear Cache", systemImage: "opticaldiscdrive") {
                    CanvasService.shared.clearStorage()
                }

                Button("Delete all files", systemImage: "folder.badge.minus") {
                    do {
                        try CourseFileService.clearAllFiles()
                    } catch {
                        LoggerService.main.error("Couldn't clear files: \(error)")
                    }
                }

                Button("Show files in Finder", systemImage: "folder.badge.person.crop") {
                    CourseFileService.showInFinder()
                }
                #if os(iOS)
                .disabled(true)
                #endif
            }
            .foregroundStyle(.red)
        } header: {
            Label("Debug", systemImage: "ant")
        }
    }
    #endif
}

#Preview {
    SettingsView()
        .environment(CourseManager())
}
