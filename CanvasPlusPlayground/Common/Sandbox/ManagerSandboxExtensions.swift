//
//  ManagerSandboxExtensions.swift
//  CanvasPlusPlayground
//
//  Extensions that add sandbox support to managers. When AppEnvironment.isSandbox is true,
//  these managers return static data instead of making network calls.
//
//  Created by Steven Liu on 1/31/26.
//

import Foundation
import SwiftData

// MARK: - CourseManager

extension CourseManager {
    func getSandboxedCourses() async {
        guard AppEnvironment.isSandbox else {
            await getCourses()
            return
        }
        let courses = SandboxData.dummyCourses
        self.activeCourses = courses
        LoggerService.main.debug("[Sandbox] Loaded dummy course")
    }
}

// MARK: - ProfileManager

extension ProfileManager {
    func getSandboxedCurrentUserAndProfile() async {
        guard AppEnvironment.isSandbox else {
            await getCurrentUserAndProfile()
            return
        }
        setSandboxUserAndProfile(user: SandboxData.dummyUser, profile: SandboxData.dummyProfile)
        LoggerService.main.debug("[Sandbox] Loaded dummy user and profile")
    }
}

// MARK: - ToDoListManager

extension ToDoListManager {
    func fetchSandboxedToDoItemCount() async {
        guard AppEnvironment.isSandbox else {
            await fetchToDoItemCount()
            return
        }
        self.toDoItemCount = SandboxData.dummyToDoCount
        LoggerService.main.debug("[Sandbox] Loaded dummy to-do count")
    }
}

// MARK: - Sandbox SwiftData Persistence

@MainActor
enum SandboxDataLoader {
    /// Inserts all sandbox dummy data into SwiftData so that
    /// SpotlightSearch and other SwiftData queries work in sandbox mode.
    static func persistSandboxData() {
        let context = ModelContext.shared

        // Courses (and their tabs)
        for course in SandboxData.dummyCourses {
            context.insert(course)
        }

        // Announcements
        for announcement in SandboxData.dummyAnnouncements {
            context.insert(announcement)
        }

        // Assignment Groups
        for group in SandboxData.dummyAssignmentGroups {
            context.insert(group)
        }

        // Assignments
        for assignment in SandboxData.dummyAssignments {
            context.insert(assignment)
        }

        // Quizzes
        for quiz in SandboxData.dummyQuizzes {
            context.insert(quiz)
        }

        // Pages
        for page in SandboxData.dummyPages {
            context.insert(page)
        }

        // Files
        for file in SandboxData.dummyFiles {
            context.insert(file)
        }

        // Modules
        for module in SandboxData.dummyModules {
            context.insert(module)
        }

        // Users / People
        for user in SandboxData.dummyUsers {
            context.insert(user)
        }

        // Groups
        for group in SandboxData.dummyGroups {
            context.insert(group)
        }

        LoggerService.main.debug("[Sandbox] Persisted all dummy data to SwiftData")
    }
}
