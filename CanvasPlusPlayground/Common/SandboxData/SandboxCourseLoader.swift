//
//  SandboxCourseLoader.swift
//  CanvasPlusPlayground
//
//  Created for sandbox data system
//

import Foundation

/// Loads sandbox course data from bundled JSON files for development and testing.
///
/// Use this loader to access static course data without requiring API access.
/// All sandbox entities use IDs starting with `99` prefix.
final class SandboxCourseLoader {
    static let shared = SandboxCourseLoader()

    /// The course ID used for all sandbox data
    static let sandboxCourseID = 99001

    private let decoder: JSONDecoder

    private init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Load All Data

    /// Loads all sandbox data into a container
    func loadAll() throws -> SandboxDataContainer {
        SandboxDataContainer(
            course: try loadCourse(),
            tabs: try loadTabs(),
            assignmentGroups: try loadAssignmentGroups(),
            quizzes: try loadQuizzes(),
            announcements: try loadAnnouncements(),
            discussionTopics: try loadDiscussionTopics(),
            folders: try loadFolders(),
            files: try loadFiles(),
            modules: try loadModules(),
            users: try loadUsers(),
            enrollments: try loadEnrollments()
        )
    }

    // MARK: - Individual Loaders

    func loadCourse() throws -> CourseAPI {
        try load("course", as: CourseAPI.self)
    }

    func loadTabs() throws -> [TabAPI] {
        try load("tabs", as: [TabAPI].self)
    }

    func loadAssignmentGroups() throws -> [AssignmentGroupAPI] {
        try load("assignment_groups", as: [AssignmentGroupAPI].self)
    }

    func loadQuizzes() throws -> [QuizAPI] {
        try load("quizzes", as: [QuizAPI].self)
    }

    func loadAnnouncements() throws -> [AnnouncementAPI] {
        try load("announcements", as: [AnnouncementAPI].self)
    }

    func loadDiscussionTopics() throws -> [DiscussionTopicAPI] {
        try load("discussion_topics", as: [DiscussionTopicAPI].self)
    }

    func loadFolders() throws -> [FolderAPI] {
        try load("folders", as: [FolderAPI].self)
    }

    func loadFiles() throws -> [FileAPI] {
        try load("files", as: [FileAPI].self)
    }

    func loadModules() throws -> [APIModule] {
        try load("modules", as: [APIModule].self)
    }

    func loadUsers() throws -> [UserAPI] {
        try load("users", as: [UserAPI].self)
    }

    func loadEnrollments() throws -> [EnrollmentAPI] {
        try load("enrollments", as: [EnrollmentAPI].self)
    }

    // MARK: - Private Helpers

    private func load<T: Decodable>(_ filename: String, as type: T.Type) throws -> T {
        // Try multiple possible subdirectory paths
        let possibleSubdirectories = ["JSON", "SandboxData/JSON", nil]

        var url: URL?
        for subdirectory in possibleSubdirectories {
            url = Bundle.main.url(
                forResource: filename,
                withExtension: "json",
                subdirectory: subdirectory
            )
            if url != nil { break }
        }

        guard let url else {
            LoggerService.main.error("[Sandbox] Bundle path: \(Bundle.main.bundlePath)")
            throw SandboxLoaderError.fileNotFound(filename)
        }

        let data = try Data(contentsOf: url)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw SandboxLoaderError.decodingFailed(filename, error)
        }
    }
}

// MARK: - Errors

enum SandboxLoaderError: LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String, Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Sandbox JSON file not found: \(filename).json"
        case .decodingFailed(let filename, let error):
            return "Failed to decode \(filename).json: \(error.localizedDescription)"
        }
    }
}
