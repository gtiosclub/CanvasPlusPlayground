//
//  CanvasPlusPlaygroundApp.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

@main
struct CanvasPlusPlaygroundApp: App {
    // Navigation
    @State private var navigationModel = NavigationModel()

    // App
    @State private var profileManager = ProfileManager()
    @State private var courseManager = CourseManager()
    @State private var pinnedItemsManager = PinnedItemsManager()
    @State private var quickOpenManager = QuickOpenManager()
    // Intelligence
    @StateObject private var intelligenceManager = IntelligenceManager()
    @StateObject private var llmEvaluator = LLMEvaluator()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(profileManager)
                .environment(courseManager)
                .environment(pinnedItemsManager)
                .environment(navigationModel)
                .environment(quickOpenManager)
                .environmentObject(intelligenceManager)
                .environmentObject(llmEvaluator)
                .task {
                    CanvasService.shared.setupStorage()
                    await courseManager.getCourses()
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Quick Open") {
                    quickOpenManager.isActive.toggle()
                }
                .keyboardShortcut("O", modifiers: [.command, .shift])
            }
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .environment(profileManager)
                .environment(courseManager)
                .environment(pinnedItemsManager)
                .environment(navigationModel)
                .environmentObject(intelligenceManager)
                .environmentObject(llmEvaluator)
                .frame(width: 400, height: 500)
        }
        #endif
    }

    init() {
        print(URL.applicationSupportDirectory.path(percentEncoded: false))
    }
}
