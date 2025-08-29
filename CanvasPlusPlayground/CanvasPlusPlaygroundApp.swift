//
//  CanvasPlusPlaygroundApp.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftData
import SwiftUI

@main
struct CanvasPlusPlaygroundApp: App {
    enum LaunchState {
        case loading, failed, ready
    }

    @State private var launchState: LaunchState
    // Navigation
    @State private var navigationModel = NavigationModel()

    // App
    @State private var listManager = ToDoListManager()
    @State private var profileManager = ProfileManager()
    @State private var courseManager = CourseManager()
    @State private var pinnedItemsManager = PinnedItemsManager()
    @State private var remindersManager = RemindersManager()

    var body: some Scene {
        WindowGroup {
            switch launchState {
            case .loading:
                ProgressView()
            case .failed:
                launchFailurePage
            case .ready:
                HomeView()
                    .environment(listManager)
                    .environment(profileManager)
                    .environment(courseManager)
                    .environment(pinnedItemsManager)
                    .environment(navigationModel)
                    .environment(remindersManager)
                    .onAppear {
                        CanvasService.shared.setupStorage()
                    }
            }
        }

        #if os(macOS)
        Settings {
            switch launchState {
            case .loading:
                ProgressView()
            case .failed:
                launchFailurePage
            case .ready:
                SettingsView()
                    .environment(profileManager)
                    .environment(courseManager)
                    .environment(pinnedItemsManager)
                    .environment(navigationModel)
                    .frame(width: 400, height: 500)
            }
        }
        #endif
    }

    var launchFailurePage: some View {
        VStack {
            Image(systemName: "externaldrive.fill.trianglebadge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.yellow)

            Text("Local Storage Failure")
                .font(.largeTitle)
                .bold()

            Text(
                 """
                 Local storage data has been corrupted. Please reset local storage to continue using the app.
                 Note that this will only affect the data you have on-device (Pinned Items, Grade Calculator, etc.), and will not affect the server-side data.
                 """
            )

            Spacer()

            Button("Reset local storage") {
                do {
                    launchState = .loading
                    try ModelContainer.eraseSQLiteStore()
                    launchState = Self.setupModelContainer()
                } catch {
                    launchState = .failed
                    LoggerService.main.error("Erasing SQLite store failed with: \(error)")
                }
            }
        }
        .padding()
    }

    init() {
        #if DEBUG
        LoggerService.main.debug("App Sandbox: \(URL.applicationSupportDirectory.path(percentEncoded: false))")
        #endif

        self.launchState = Self.setupModelContainer()
    }

    /// Attempts to setup the model container and returns app launch status based on success of setup
    static func setupModelContainer() -> LaunchState {
        do {
            try ModelContainer.setupSharedModelContainer()
            return .ready
        } catch {
            LoggerService.main.error("Model container init has failed: \(error)")
            return .failed
        }
    }
}
