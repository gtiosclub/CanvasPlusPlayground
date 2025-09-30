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
    #endif

    @Environment(\.dismiss) private var dismiss

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
            Button("Change Access Token", systemImage: .key) {
                showChangeAccessToken = true
            }
        } header: {
            Label("Login", systemImage: .lockFilled)
        }
    }

    @available(macOS 26.0, iOS 26.0, *)
    private var intelligenceSettings: some View {
        Section {
            Text(IntelligenceSupport.modelAvailabilityDescription)
        } header: {
            Label("Intelligence", systemImage: .wandAndStars)
        }
        .foregroundStyle(.secondary)
    }

    #if DEBUG
    @ViewBuilder
    private var debugSettings: some View {
        @Bindable var navigationModel = navigationModel

        Section {
            Group {
                Button("View Item Picker", systemImage: .filemenuAndSelection) {
                    selectedCourseForItemPicker = courseManager.activeCourses.first
                }

                #if os(macOS)
                if #available(macOS 26.0, *) {
                    Button("IGC Playground", systemImage: .plusForwardslashMinus) {
                        openWindow(id: IGCPlayground.windowID)
                    }
                }
                #endif

                Button("Clear Pinned Items", systemImage: .trash) {
                    pinnedItemManager.clearAllPinnedItems()
                }

                Button("Clear Cache", systemImage: .opticaldiscdrive) {
                    CanvasService.shared.clearStorage()
                }

                Button("Delete all files", systemImage: .folderBadgeMinus) {
                    do {
                        try CourseFileService.clearAllFiles()
                    } catch {
                        LoggerService.main.error("Couldn't clear files: \(error)")
                    }
                }

                Button("Show files in Finder", systemImage: .folderBadgePersonCrop) {
                    CourseFileService.showInFinder()
                }
                #if os(iOS)
                .disabled(true)
                #endif
            }
            .foregroundStyle(.red)
        } header: {
            Label("Debug", systemImage: .ant)
        }
    }
    #endif
}

#Preview {
    SettingsView()
        .environment(CourseManager())
}
