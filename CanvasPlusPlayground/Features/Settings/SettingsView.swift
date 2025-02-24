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
    #endif
    @Environment(NavigationModel.self) private var navigationModel
    @EnvironmentObject private var llmEvaluator: LLMEvaluator
    @EnvironmentObject private var intelligenceManager: IntelligenceManager
    @Environment(\.dismiss) private var dismiss

    @State private var showChangeAccessToken: Bool = false

    var body: some View {
        @Bindable var navigationModel = navigationModel

        NavigationStack {
            mainBody
        }
        .sheet(isPresented: $showChangeAccessToken) {
            NavigationStack {
                SetupView()
            }
        }
        .sheet(isPresented: $navigationModel.showInstallIntelligenceSheet, content: {
            NavigationStack {
                IntelligenceOnboardingView()
            }
            .environmentObject(llmEvaluator)
            .environmentObject(intelligenceManager)
            .interactiveDismissDisabled()
        })
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
                Label("Download & Install Models", systemImage: "square.and.arrow.down")
            }
            .foregroundStyle(.blue)
        } header: {
            Label("Intelligence", systemImage: "wand.and.stars")
        } footer: {
            #if targetEnvironment(simulator)
            Text("Intelligence features are not supported on simulator")
            #else
            if intelligenceManager.installedModels.isEmpty {
                Text("Install models to use the intelligence features.")
            } else {
                let count = intelligenceManager.installedModels.count
                Text(
                    "You have \(count) installed \(count == 1 ? "model" : "models")"
                )
            }
            #endif
        }
        #if targetEnvironment(simulator)
        .disabled(true)
        #endif
    }

    #if DEBUG
    private var debugSettings: some View {
        Section {
            Group {
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
