//
//  SandboxPreviewHelpers.swift
//  CanvasPlusPlayground
//
//  Created for sandbox data system
//

import Foundation

// MARK: - Preview Helpers

extension SandboxCourseLoader {

    /// Sandbox course as a Course model for previews
    static var previewCourse: Course {
        guard let courseAPI = try? shared.loadCourse() else {
            fatalError("Failed to load sandbox course for preview")
        }
        return Course(courseAPI)
    }

    /// Sandbox course API object for previews
    static var previewCourseAPI: CourseAPI {
        guard let course = try? shared.loadCourse() else {
            fatalError("Failed to load sandbox course API for preview")
        }
        return course
    }

    /// Sandbox tabs for previews
    static var previewTabs: [TabAPI] {
        (try? shared.loadTabs()) ?? []
    }

    /// Sandbox assignment groups for previews
    static var previewAssignmentGroups: [AssignmentGroupAPI] {
        (try? shared.loadAssignmentGroups()) ?? []
    }

    /// All sandbox assignments for previews
    static var previewAssignments: [AssignmentAPI] {
        previewAssignmentGroups.flatMap { $0.assignments ?? [] }
    }

    /// Sandbox quizzes for previews
    static var previewQuizzes: [QuizAPI] {
        (try? shared.loadQuizzes()) ?? []
    }

    /// Sandbox announcements for previews
    static var previewAnnouncements: [AnnouncementAPI] {
        (try? shared.loadAnnouncements()) ?? []
    }

    /// Sandbox discussion topics for previews
    static var previewDiscussionTopics: [DiscussionTopicAPI] {
        (try? shared.loadDiscussionTopics()) ?? []
    }

    /// Sandbox folders for previews
    static var previewFolders: [FolderAPI] {
        (try? shared.loadFolders()) ?? []
    }

    /// Sandbox files for previews
    static var previewFiles: [FileAPI] {
        (try? shared.loadFiles()) ?? []
    }

    /// Sandbox modules for previews
    static var previewModules: [APIModule] {
        (try? shared.loadModules()) ?? []
    }

    /// Sandbox users for previews
    static var previewUsers: [UserAPI] {
        (try? shared.loadUsers()) ?? []
    }

    /// Sandbox enrollments for previews
    static var previewEnrollments: [EnrollmentAPI] {
        (try? shared.loadEnrollments()) ?? []
    }

    /// Full sandbox data container for previews
    static var previewContainer: SandboxDataContainer? {
        try? shared.loadAll()
    }
}

// MARK: - Single Item Helpers

extension SandboxCourseLoader {

    /// First sandbox assignment for previews
    static var previewAssignment: AssignmentAPI? {
        previewAssignments.first
    }

    /// First sandbox quiz for previews
    static var previewQuiz: QuizAPI? {
        previewQuizzes.first
    }

    /// First sandbox announcement for previews
    static var previewAnnouncement: AnnouncementAPI? {
        previewAnnouncements.first
    }

    /// First sandbox module for previews
    static var previewModule: APIModule? {
        previewModules.first
    }

    /// Sandbox teacher user for previews
    static var previewTeacher: UserAPI? {
        previewUsers.first { $0.role == "teacher" }
    }

    /// Sandbox student user for previews
    static var previewStudent: UserAPI? {
        previewUsers.first { $0.role == "student" }
    }

    /// First sandbox file for previews
    static var previewFile: FileAPI? {
        previewFiles.first
    }

    /// First sandbox folder for previews
    static var previewFolder: FolderAPI? {
        previewFolders.first
    }
}
