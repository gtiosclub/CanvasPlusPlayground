//
//  FocusWindowView.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/1/25.
//

import SwiftUI

struct FocusWindowView: View {
    @Environment(CourseManager.self) private var courseManager
    @State private var navigationModel = NavigationModel()
    @State private var destination: NavigationModel.Destination?
    @State private var isLoading = true
    @State private var errorMessage: String?

    let info: FocusWindowInfo

    var body: some View {
        @Bindable var navigationModel = navigationModel

        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let errorMessage {
                ContentUnavailableView(
                    "Unable to open new window",
                    systemImage: "questionmark.square.dashed",
                    description: Text(errorMessage)
                )
            } else if let destination {
                NavigationStack(path: $navigationModel.navigationPath) {
                    destination.destinationView()
                        .defaultNavigationDestination(courseID: getCourseID())
                }
                .environment(navigationModel)
            }
        }
        .task {
            await loadDestination()
        }
    }

    private func getCourseID() -> Course.ID {
        switch info.destination {
        case .course(let courseID), .coursePage(_, let courseID), .file(_, let courseID), .folder(_, let courseID):
            return courseID
        case .announcement(_, let courseID), .assignment(_, let courseID), .page(_, let courseID):
            return courseID
        }
    }

    @MainActor
    private func loadDestination() async {
        do {
            if courseManager.activeCourses.isEmpty {
                await courseManager.getCourses()
            }

            destination = try await info.destination.loadDestination(courseManager: courseManager)
        } catch {
            errorMessage = "Failed to load content: \(error.localizedDescription)"
            LoggerService.main.error("FocusWindowView: Failed to load destination - \(error)")
        }

        isLoading = false
    }
}


