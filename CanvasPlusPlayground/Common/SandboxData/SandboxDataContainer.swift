//
//  SandboxDataContainer.swift
//  CanvasPlusPlayground
//
//  Created for sandbox data system
//

import Foundation

/// Container holding all sandbox course data.
///
/// Provides access to all loaded API objects and computed helpers
/// for common data access patterns.
struct SandboxDataContainer {
    let course: CourseAPI
    let tabs: [TabAPI]
    let assignmentGroups: [AssignmentGroupAPI]
    let quizzes: [QuizAPI]
    let announcements: [AnnouncementAPI]
    let discussionTopics: [DiscussionTopicAPI]
    let folders: [FolderAPI]
    let files: [FileAPI]
    let modules: [APIModule]
    let users: [UserAPI]
    let enrollments: [EnrollmentAPI]

    // MARK: - Computed Helpers

    /// All assignments flattened from assignment groups
    var allAssignments: [AssignmentAPI] {
        assignmentGroups.flatMap { $0.assignments ?? [] }
    }

    /// All module items flattened from modules
    var allModuleItems: [APIModuleItem] {
        modules.flatMap { $0.items ?? [] }
    }

    /// The teacher user (ID 99101)
    var teacher: UserAPI? {
        users.first { $0.id == 99101 }
    }

    /// The TA user (ID 99102)
    var teachingAssistant: UserAPI? {
        users.first { $0.id == 99102 }
    }

    /// All student users (IDs 99103-99105)
    var students: [UserAPI] {
        users.filter { $0.role == "student" }
    }

    /// Student enrollments with grades
    var studentEnrollments: [EnrollmentAPI] {
        enrollments.filter { $0.type == "StudentEnrollment" }
    }

    /// Root folder (course files)
    var rootFolder: FolderAPI? {
        folders.first { $0.parent_folder_id == nil }
    }

    /// Subfolders of the root folder
    var subfolders: [FolderAPI] {
        guard let rootId = rootFolder?.id else { return [] }
        return folders.filter { $0.parent_folder_id == rootId }
    }

    /// Published quizzes only
    var publishedQuizzes: [QuizAPI] {
        quizzes.filter { $0.published == true }
    }

    /// Published modules only
    var publishedModules: [APIModule] {
        modules.filter { $0.published == true }
    }

    /// Graded quizzes (type == assignment)
    var gradedQuizzes: [QuizAPI] {
        quizzes.filter { $0.quiz_type == .assignment }
    }

    /// Practice quizzes
    var practiceQuizzes: [QuizAPI] {
        quizzes.filter { $0.quiz_type == .practiceQuiz }
    }

    // MARK: - Lookup Helpers

    /// Find an assignment by ID
    func assignment(withId id: Int) -> AssignmentAPI? {
        allAssignments.first { $0.id == id }
    }

    /// Find a quiz by ID
    func quiz(withId id: Int) -> QuizAPI? {
        quizzes.first { $0.id == id }
    }

    /// Find a module by ID
    func module(withId id: Int) -> APIModule? {
        modules.first { $0.id == id }
    }

    /// Find a user by ID
    func user(withId id: Int) -> UserAPI? {
        users.first { $0.id == id }
    }

    /// Find an enrollment by user ID
    func enrollment(forUserId userId: Int) -> EnrollmentAPI? {
        enrollments.first { $0.user_id == userId }
    }

    /// Find files in a specific folder
    func files(inFolderId folderId: Int) -> [FileAPI] {
        files.filter { $0.folder_id == folderId }
    }

    /// Find a folder by ID
    func folder(withId id: Int) -> FolderAPI? {
        folders.first { $0.id == id }
    }
}
