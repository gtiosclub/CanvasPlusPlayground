//
//  SettingsView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/11/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showChangeAccessToken: Bool = false

    var body: some View {
        NavigationStack {
            mainBody
        }
        .sheet(isPresented: $showChangeAccessToken) {
            NavigationStack {
                SetupView()
            }
        }
    }

    private var mainBody: some View {
        Form {
            loginSettings
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

    private var debugSettings: some View {
        Section {
            Group {
                Button("Clear cache", systemImage: "opticaldiscdrive") {
                    CanvasService.shared.clearStorage()
                }

                Button("Delete all files", systemImage: "folder.badge.minus") {
                    do {
                        try CourseFileService.clearAllFiles()
                    } catch {
                        print("Couldn't clear files: \(error)")
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
}

#Preview {
    SettingsView()
        .environment(CourseManager())
}
