//
//  SettingsView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/11/24.
//

import SwiftUI

struct SettingsView: View {
    #if DEBUG
    @Environment(PinnedItemsManager.self) private var pinnedItemManager
    @Environment(CourseManager.self) private var courseManager

    @State private var selectedItem: (any PickableItem)?
    #endif

    @Environment(NavigationModel.self) private var navigationModel
    @EnvironmentObject private var intelligenceManager: IntelligenceManager
    @Environment(\.dismiss) private var dismiss

    @State private var showChangeAccessToken: Bool = false

    var body: some View {
        @Bindable var navigationModel = navigationModel

        NavigationStack {
            mainBody
        }
        #if DEBUG
        .sheet(item: $navigationModel.selectedCourseForItemPicker) {
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
            intelligenceSettings
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

    private var intelligenceSettings: some View {
        Section {
            Button {
                navigationModel.showInstallIntelligenceSheet = true
            } label: {
                Label("Setup Intelligence", systemImage: "square.and.arrow.down")
            }
            .foregroundStyle(.blue)
        } header: {
            Label("Intelligence", systemImage: "wand.and.stars")
        } footer: {
            Group {
                #if targetEnvironment(simulator)
                Text("Intelligence features are not supported on simulator.")
                #else
                if true { // FIXME: Fix with Foundation Models implementation
                    Text("Intelligence is not installed yet.")
                } else {
                    Text("Intelligence is setup.")
                }
                #endif
            }
            .font(.caption)
        }
        #if true /*targetEnvironment(simulator)*/
        .disabled(true) // FIXME: Fix with Foundation Models implementation
        #endif
    }

    #if DEBUG
    @ViewBuilder
    private var debugSettings: some View {
        @Bindable var navigationModel = navigationModel

        Section {
            Group {
                Button("View Item Picker", systemImage: "filemenu.and.selection") {
                    navigationModel.selectedCourseForItemPicker = courseManager.activeCourses.first
                }

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
