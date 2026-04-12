//
//  CanvasPlusPlaygroundApp.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI
import SwiftData
import CoreSpotlight

#if os(iOS) || os(visionOS)
import UIKit

final class SpotlightAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        SpotlightAppDelegate.handle(userActivity: userActivity)
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if let userActivity = launchOptions?[.userActivityDictionary] as? [AnyHashable: Any],
           let activity = userActivity["UIApplicationLaunchOptionsUserActivityKey"] as? NSUserActivity {
            _ = SpotlightAppDelegate.handle(userActivity: activity)
        }
        return true
    }

    @discardableResult
    static func handle(userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == CSSearchableItemActionType,
              let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return false
        }
        NotificationCenter.default.post(
            name: .openSpotlightDeepLink,
            object: nil,
            userInfo: [SpotlightDeepLinkUserInfoKey.identifier: identifier]
        )
        return true
    }
}
#elseif os(macOS)
import AppKit

final class SpotlightAppDelegate: NSObject, NSApplicationDelegate {
    func application(
        _ application: NSApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void
    ) -> Bool {
        SpotlightAppDelegate.handle(userActivity: userActivity)
    }

    @discardableResult
    static func handle(userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == CSSearchableItemActionType,
              let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return false
        }
        NotificationCenter.default.post(
            name: .openSpotlightDeepLink,
            object: nil,
            userInfo: [SpotlightDeepLinkUserInfoKey.identifier: identifier]
        )
        return true
    }
}
#endif

@main
struct CanvasPlusPlaygroundApp: App {
    enum LaunchState {
        case loading, failed, ready
    }

    #if os(iOS) || os(visionOS)
    @UIApplicationDelegateAdaptor(SpotlightAppDelegate.self) private var spotlightAppDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(SpotlightAppDelegate.self) private var spotlightAppDelegate
    #endif

    @State var launchState: LaunchState

    // App
    @State private var listManager = ToDoListManager()
    @State private var profileManager = ProfileManager()
    @State private var courseManager = CourseManager()
    @State private var pinnedItemsManager = PinnedItemsManager.shared
    @State private var recentItemsManager = RecentItemsManager.shared
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
                    .environment(recentItemsManager)
                    .environment(remindersManager)
                    .task {
                        WidgetContext.setup(courseManager: courseManager)
                    }
            }
        }
        .commands {
            #if os(macOS)
            CommandGroup(after: .newItem) {
                Button("New Tab") {
                    NSApplication.addTabbedWindow()
                }
                .keyboardShortcut("T")
            }
            #if DEBUG
            CommandMenu("Debug") {
                Button("Show Network Request Recorder") {
                    openWindow(id: NetworkRequestRecorder.networkRequestDebugID)
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])
            }
            #endif
            #endif
            CommandGroup(after: .textEditing) {
                Button("Search Everywhere") {
                    NotificationCenter.default.post(
                        name: .openSpotlightSearch,
                        object: nil
                    )
                }
                .keyboardShortcut("k", modifiers: .command)
            }
        }

#if DEBUG && os(macOS)
        Window("Network Request Debug Window", id: NetworkRequestRecorder.networkRequestDebugID) {
            NetworkRequestDebugView()
                .environment(networkRecorder)
        }
        .windowStyle(.automatic)

        if #available(macOS 26.0, *) {
            Window("IGC Playground", id: IGCPlayground.windowID) {
                IGCPlayground()
                    .environment(courseManager)
            }
        }
#endif

        WindowGroup(for: FocusWindowInfo.self) { $focusWindowInfo in
            if let focusWindowInfo {
                FocusWindowView(info: focusWindowInfo)
                    .environment(listManager)
                    .environment(profileManager)
                    .environment(courseManager)
                    .environment(pinnedItemsManager)
                    .environment(recentItemsManager)
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
                    .environment(recentItemsManager)
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

        CanvasService.shared.setupStorage()
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

