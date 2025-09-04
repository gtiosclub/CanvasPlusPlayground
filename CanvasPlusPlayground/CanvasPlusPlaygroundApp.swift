//
//  CanvasPlusPlaygroundApp.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI
import SwiftData

@main
struct CanvasPlusPlaygroundApp: App {
    enum LaunchState {
        case loading, failed, ready
    }

    @State var launchState: LaunchState

    // App
    @State private var listManager = ToDoListManager()
    @State private var profileManager = ProfileManager()
    @State private var courseManager = CourseManager()
    @State private var pinnedItemsManager = PinnedItemsManager()
    @State private var remindersManager = RemindersManager()
    #if DEBUG
    @State private var networkRecorder = NetworkRequestRecorder.shared
    
    // System environment functions
    @Environment(\.openWindow) var openWindow
    #endif
    
    
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
                    .environment(remindersManager)
                    .onAppear {
                        CanvasService.shared.setupStorage()
                    }
            }
        }
        #if DEBUG
        .commands {
            CommandMenu("Debug") {
                Button("Show Network Request Recorder") {
                    openWindow(id: NetworkRequestRecorder.networkRequestDebugID)
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])
            }
            
        }
        #endif
        
        #if DEBUG
        Window("Network Request Debug Window", id: NetworkRequestRecorder.networkRequestDebugID) {
            NetworkRequestDebugView()
                .environment(networkRecorder)
        }
        .windowStyle(.automatic)
        #endif

        WindowGroup(for: FocusWindowInfo.self) { $focusWindowInfo in
            if let focusWindowInfo {
                FocusWindowView(info: focusWindowInfo)
                    .environment(listManager)
                    .environment(profileManager)
                    .environment(courseManager)
                    .environment(pinnedItemsManager)
                    .environment(remindersManager)
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
                    self.launchState = .loading
                    try ModelContainer.eraseSQLiteStore()
                    self.launchState = Self.setupModelContainer()
                } catch {
                    self.launchState = .failed
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

