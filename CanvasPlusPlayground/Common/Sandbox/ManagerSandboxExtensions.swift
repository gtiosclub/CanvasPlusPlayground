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

// MARK: - CourseManager

extension CourseManager {
    func getCoursesIfNeeded() async {
        guard AppEnvironment.isSandbox else {
            await getCourses()
            return
        }
        self.activeCourses = [SandboxData.dummyCourse]
        LoggerService.main.debug("[Sandbox] Loaded dummy course")
    }
}

// MARK: - ProfileManager

extension ProfileManager {
    func getCurrentUserAndProfileIfNeeded() async {
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
    func fetchToDoItemCountIfNeeded() async {
        guard AppEnvironment.isSandbox else {
            await fetchToDoItemCount()
            return
        }
        self.toDoItemCount = SandboxData.dummyToDoCount
        LoggerService.main.debug("[Sandbox] Loaded dummy to-do count")
    }
}
