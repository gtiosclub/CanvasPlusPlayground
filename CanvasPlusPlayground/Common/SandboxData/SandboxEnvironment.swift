//
//  SandboxEnvironment.swift
//  CanvasPlusPlayground
//
//  Created for sandbox data system
//

import Foundation

/// Manages the sandbox environment for development and testing.
///
/// When no access token is provided, the app can run in sandbox mode,
/// displaying fake course data so developers can work on the UI without
/// needing Canvas API access.
///
/// ## Usage
///
/// Check if sandbox mode should be active:
/// ```swift
/// if SandboxEnvironment.isActive {
///     // Load sandbox data instead of fetching from API
/// }
/// ```
///
/// Load sandbox course for CourseManager:
/// ```swift
/// if SandboxEnvironment.isActive {
///     courseManager.activeCourses = SandboxEnvironment.loadSandboxCourses()
/// }
/// ```
enum SandboxEnvironment {

    // MARK: - State

    /// Whether sandbox mode is currently active.
    ///
    /// Returns `true` when no access token is configured, allowing the app
    /// to display sandbox data instead of requiring authentication.
    static var isActive: Bool {
        StorageKeys.needsAuthorization
    }

    /// Whether sandbox mode is enabled via launch argument (for testing).
    ///
    /// Pass `-sandbox` as a launch argument to force sandbox mode.
    static var isForcedByLaunchArgument: Bool {
        ProcessInfo.processInfo.arguments.contains("-sandbox")
    }

    /// Whether the app should use sandbox mode.
    ///
    /// Returns `true` if either:
    /// - No access token is configured, OR
    /// - The `-sandbox` launch argument is present
    static var shouldUseSandbox: Bool {
        let result = isActive || isForcedByLaunchArgument
        LoggerService.main.debug("[Sandbox] shouldUseSandbox=\(result), isActive=\(isActive), isForcedByLaunchArgument=\(isForcedByLaunchArgument)")
        return result
    }

    // MARK: - Data Loading

    /// Loads the sandbox course as a Course model.
    ///
    /// Use this in `CourseManager` when sandbox mode is active.
    ///
    /// - Returns: Array containing the sandbox course, or empty array on failure.
    @MainActor
    static func loadSandboxCourses() -> [Course] {
        LoggerService.main.debug("[Sandbox] Loading sandbox courses...")
        do {
            let courseAPI = try SandboxCourseLoader.shared.loadCourse()
            let course = Course(courseAPI)
            // Mark as favorite so it appears in the sidebar
            course.isFavorite = true
            LoggerService.main.debug("[Sandbox] Loaded course: \(course.name ?? "unnamed")")
            return [course]
        } catch {
            LoggerService.main.error("[Sandbox] Failed to load sandbox course: \(error)")
            return []
        }
    }

    /// Loads all sandbox data into a container.
    ///
    /// Use this when you need access to all sandbox data types
    /// (assignments, quizzes, modules, etc.).
    ///
    /// - Returns: A `SandboxDataContainer` with all loaded data, or `nil` on failure.
    static func loadAllSandboxData() -> SandboxDataContainer? {
        do {
            return try SandboxCourseLoader.shared.loadAll()
        } catch {
            LoggerService.main.error("Failed to load sandbox data: \(error)")
            return nil
        }
    }

    // MARK: - Sandbox User

    /// A mock user for sandbox mode.
    ///
    /// Use this when `ProfileManager` needs a current user in sandbox mode.
    static var sandboxUser: UserAPI? {
        try? SandboxCourseLoader.shared.loadUsers().first { $0.role == "student" }
    }
}
