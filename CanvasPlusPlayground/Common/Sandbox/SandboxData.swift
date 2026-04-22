//
//  SandboxData.swift
//  CanvasPlusPlayground
//
//  Static dummy data for sandbox environment. Used when AppEnvironment.isSandbox is true.
//  Enables developers without API access to explore the app workflow.
//
//  Created by Steven Liu on 1/31/26.
//


import Foundation
import SwiftData

enum SandboxData {
    static let courseID = "12345"
    static let courseID2 = "67890"
    private static let courseIntID = 12345
    private static let courseInt2ID = 67890

    /// Map between String courseID and its Int form.
    private static func intID(for courseID: String) -> Int {
        courseID == Self.courseID2 ? courseInt2ID : courseIntID
    }

    // MARK: - Course

    private static func buildCourse(
        id: String, intID: Int, name: String, courseCode: String,
        originalName: String, color: String,
        syllabus: String, publicDescription: String
    ) -> Course {
        let tabsAPI = TabAPI.sandboxTabs(forCourseIntID: intID)
        let courseAPI = CourseAPI(
            id: intID,
            name: name,
            course_code: courseCode,
            original_name: originalName,
            course_color: color,
            workflow_state: .available,
            account_id: 5432,
            created_at: Date.now.addingTimeInterval(-7776000),
            start_at: Date.now.addingTimeInterval(-5184000),
            end_at: Date.now.addingTimeInterval(5184000),
            locale: "en",
            enrollments: [
                CourseEnrollment(
                    type: "student",
                    role: "StudentEnrollment",
                    roleId: 3,
                    userId: 54321,
                    enrollmentState: .active,
                    limitPrivilegesToCourseSection: false
                )
            ],
            total_students: 1,
            calendar: CalendarLink(ics: nil),
            default_view: .assignments,
            syllabus_body: syllabus,
            term: CourseTermAPI(
                id: 876,
                name: "Sandbox Term",
                start_at: Date.now.addingTimeInterval(-5184000),
                end_at: Date.now.addingTimeInterval(5184000),
                created_at: nil,
                workflow_state: .active,
                grading_period_group_id: nil
            ),
            course_progress: nil,
            apply_assignment_group_weights: true,
            teachers: [CourseTeacher.sample],
            permissions: CoursePermissions(createAnnouncement: true, createDiscussionTopic: true),
            is_public: false,
            homeroom_course: false,
            public_description: publicDescription,
            hide_final_grades: false,
            access_restricted_by_date: false,
            blueprint: false,
            banner_image_download_url: nil,
            image_download_url: nil,
            is_favorite: true,
            sections: [CourseSectionRef.sample],
            tabs: tabsAPI,
            settings: nil,
            concluded: false,
            grading_scheme: CourseAPI.sample.grading_scheme
        )
        let course = Course(courseAPI)
        let tabs = tabsAPI.map { CanvasTab(from: $0, tabOrigin: .course(id: id)) }
        for tab in tabs {
            tab.course = course
        }
        course.tabs = tabs
        return course
    }

    static var dummyCourse: Course {
        buildCourse(
            id: courseID, intID: courseIntID,
            name: "Example Course",
            courseCode: "SANDBOX101",
            originalName: "Sandbox - Introduction to Canvas Plus",
            color: "#0077B6",
            syllabus: "<p>Welcome to the Canvas Plus sandbox! This course contains sample data for exploring the app.</p>",
            publicDescription: "Sandbox course for development"
        )
    }

    static var dummyCourse2: Course {
        buildCourse(
            id: courseID2, intID: courseInt2ID,
            name: "Mobile App Development",
            courseCode: "CS4261",
            originalName: "CS 4261 - Mobile Applications & Services",
            color: "#F4A261",
            syllabus: "<p>Build iOS apps with SwiftUI and Swift. Labs, projects, and quizzes throughout the semester.</p>",
            publicDescription: "Sandbox CS4261 course for development"
        )
    }

    static var dummyCourses: [Course] {
        [dummyCourse, dummyCourse2]
    }

    // MARK: - User & Profile

    static var dummyUser: User {
        User(from: UserAPI.sample1)
    }

    static var dummyProfile: Profile {
        Profile(from: ProfileAPI(
            id: 1001,
            name: "Steven Liu",
            short_name: "Steven",
            sortable_name: "Liu, Steven",
            title: nil,
            bio: "Sandbox user for development",
            pronunciation: nil,
            primary_email: "sandbox@example.edu",
            login_id: "sandbox_user",
            sis_user_id: nil,
            lti_user_id: nil,
            avatar_url: nil,
            calendar: nil,
            time_zone: "America/New_York",
            locale: "en",
            k5_user: nil,
            use_classic_font_in_k5: nil
        ))
    }

    // MARK: - Announcements

    private static func makeAnnouncement(
        id: Int,
        courseID: String,
        authorName: String,
        authorId: Int,
        title: String,
        message: String,
        postedDaysAgo: Double,
        pinned: Bool = false,
        readState: DiscussionTopic.ReadState = .read
    ) -> DiscussionTopic {
        let postedAt = Date.now.addingTimeInterval(-86400 * postedDaysAgo)
        let topic = DiscussionTopic(from: DiscussionTopicAPI(
            id: id,
            author: DiscussionParticipantAPI(
                id: authorId,
                display_name: authorName,
                avatar_image_url: nil,
                html_url: nil,
                pronouns: nil
            ),
            title: title,
            message: "<p>\(message)</p>",
            html_url: nil,
            posted_at: postedAt,
            last_reply_at: nil,
            require_initial_post: false,
            user_can_see_posts: true,
            discussion_subentry_count: 0,
            read_state: readState,
            unread_count: readState == .unread ? 1 : 0,
            subscribed: false,
            subscription_hold: nil,
            assignment_id: nil,
            delayed_post_at: nil,
            published: true,
            lock_at: nil,
            locked: false,
            pinned: pinned,
            locked_for_user: false,
            user_name: authorName,
            group_topic_children: nil,
            root_topic_id: nil,
            podcast_url: nil,
            discussion_type: nil,
            group_category_id: nil,
            attachments: nil,
            permissions: nil,
            allow_rating: false,
            only_graders_can_rate: false,
            sort_by_rating: false,
            context_code: "course_\(intID(for: courseID))",
            is_announcement: true,
            is_section_specific: false,
            anonymous_state: nil,
            assignment: nil,
            position: 0,
            created_at: postedAt,
            sections: nil
        ))
        topic.courseId = courseID
        return topic
    }

    private static var course1Announcements: [DiscussionTopic] {
        [
            makeAnnouncement(
                id: 1, courseID: courseID, authorName: "Ivan Li", authorId: 1002,
                title: "Welcome to the Sandbox Course",
                message: "This is a sandbox environment. All data is static for demonstration purposes.",
                postedDaysAgo: 14, pinned: true
            ),
            makeAnnouncement(
                id: 2, courseID: courseID, authorName: "Ivan Li", authorId: 1002,
                title: "Midterm Review Session",
                message: "We will hold a review session this Friday at 3 PM in Room 205. Bring your notes!",
                postedDaysAgo: 3
            ),
            makeAnnouncement(
                id: 3, courseID: courseID, authorName: "Ivan Li", authorId: 1002,
                title: "Office Hours Canceled This Week",
                message: "Due to a conference, office hours are canceled this Thursday. Email me if you need help.",
                postedDaysAgo: 1, readState: .unread
            ),
            makeAnnouncement(
                id: 4, courseID: courseID, authorName: "Jane Smith", authorId: 1003,
                title: "Study Group Forming",
                message: "Looking for people to form a study group for the final project. Reply here if interested!",
                postedDaysAgo: 0.5, readState: .unread
            ),
        ]
    }

    private static var course2Announcements: [DiscussionTopic] {
        [
            makeAnnouncement(
                id: 101, courseID: courseID2, authorName: "Ivan Li", authorId: 1002,
                title: "Welcome to Mobile App Development!",
                message: "Excited to have you all in CS4261. We'll be building iOS apps with SwiftUI this semester.",
                postedDaysAgo: 14, pinned: true
            ),
            makeAnnouncement(
                id: 102, courseID: courseID2, authorName: "Ivan Li", authorId: 1002,
                title: "App Pitch Presentations Next Week",
                message: "Please come prepared with a 5-minute pitch for your final app project. Slides optional.",
                postedDaysAgo: 2
            ),
            makeAnnouncement(
                id: 103, courseID: courseID2, authorName: "Ivan Li", authorId: 1002,
                title: "Xcode 16 Required for Labs",
                message: "Make sure you've updated to Xcode 16 before starting Lab 2 next week.",
                postedDaysAgo: 1, readState: .unread
            ),
        ]
    }

    static func dummyAnnouncements(forCourseID id: String) -> [DiscussionTopic] {
        id == courseID2 ? course2Announcements : course1Announcements
    }

    static var dummyAnnouncements: [DiscussionTopic] {
        course1Announcements + course2Announcements
    }

    // MARK: - Assignments

    private static func makeAssignment(
        id: Int, courseIntID: Int, name: String, groupID: Int,
        dueDaysFromNow: Double, points: Double,
        submissionTypes: [String] = ["online_upload"]
    ) -> AssignmentAPI {
        var a = AssignmentAPI(id: id, name: name, groupID: groupID)
        a.due_at = ISO8601DateFormatter().string(from: Date.now.addingTimeInterval(86400 * dueDaysFromNow))
        a.points_possible = points
        a.published = true
        a.course_id = courseIntID
        a.submission_types = submissionTypes
        return a
    }

    private static var course1AssignmentGroups: [AssignmentGroup] {
        let homeworkGroup = AssignmentGroupAPI(
            id: 1,
            name: "Assignments",
            position: 0,
            group_weight: 40,
            assignments: [
                makeAssignment(id: 1, courseIntID: courseIntID, name: "Introduction Assignment", groupID: 1, dueDaysFromNow: 7, points: 100),
                makeAssignment(id: 2, courseIntID: courseIntID, name: "Week 1 Reading Response", groupID: 1, dueDaysFromNow: 1, points: 50),
                makeAssignment(id: 3, courseIntID: courseIntID, name: "Data Structures Problem Set", groupID: 1, dueDaysFromNow: 14, points: 75),
                makeAssignment(id: 4, courseIntID: courseIntID, name: "Essay Draft", groupID: 1, dueDaysFromNow: -2, points: 100,
                               submissionTypes: ["online_text_entry"]),
            ],
            rules: nil
        )

        let examsGroup = AssignmentGroupAPI(
            id: 2,
            name: "Exams",
            position: 1,
            group_weight: 40,
            assignments: [
                makeAssignment(id: 5, courseIntID: courseIntID, name: "Midterm Exam", groupID: 2, dueDaysFromNow: 21, points: 200),
                makeAssignment(id: 6, courseIntID: courseIntID, name: "Final Exam", groupID: 2, dueDaysFromNow: 60, points: 300),
            ],
            rules: nil
        )

        let participationGroup = AssignmentGroupAPI(
            id: 3,
            name: "Participation",
            position: 2,
            group_weight: 20,
            assignments: [
                makeAssignment(id: 7, courseIntID: courseIntID, name: "Discussion Post Week 1", groupID: 3, dueDaysFromNow: -5, points: 10,
                               submissionTypes: ["discussion_topic"]),
                makeAssignment(id: 8, courseIntID: courseIntID, name: "Discussion Post Week 2", groupID: 3, dueDaysFromNow: 2, points: 10,
                               submissionTypes: ["discussion_topic"]),
            ],
            rules: nil
        )

        return [
            AssignmentGroup(from: homeworkGroup),
            AssignmentGroup(from: examsGroup),
            AssignmentGroup(from: participationGroup),
        ]
    }

    private static var course2AssignmentGroups: [AssignmentGroup] {
        let labsGroup = AssignmentGroupAPI(
            id: 101,
            name: "Labs",
            position: 0,
            group_weight: 30,
            assignments: [
                makeAssignment(id: 101, courseIntID: courseInt2ID, name: "Lab 1: Hello SwiftUI", groupID: 101, dueDaysFromNow: 5, points: 50),
                makeAssignment(id: 102, courseIntID: courseInt2ID, name: "Lab 2: Navigation & State", groupID: 101, dueDaysFromNow: 12, points: 50),
                makeAssignment(id: 103, courseIntID: courseInt2ID, name: "Lab 3: Networking", groupID: 101, dueDaysFromNow: 19, points: 75),
            ],
            rules: nil
        )

        let projectsGroup = AssignmentGroupAPI(
            id: 102,
            name: "Projects",
            position: 1,
            group_weight: 50,
            assignments: [
                makeAssignment(id: 104, courseIntID: courseInt2ID, name: "Project Proposal", groupID: 102, dueDaysFromNow: 3, points: 50,
                               submissionTypes: ["online_text_entry"]),
                makeAssignment(id: 105, courseIntID: courseInt2ID, name: "Final App Submission", groupID: 102, dueDaysFromNow: 45, points: 300),
            ],
            rules: nil
        )

        let quizzesGroup = AssignmentGroupAPI(
            id: 103,
            name: "Quizzes",
            position: 2,
            group_weight: 20,
            assignments: [
                makeAssignment(id: 106, courseIntID: courseInt2ID, name: "Quiz 1: Swift Fundamentals", groupID: 103, dueDaysFromNow: 1, points: 25),
                makeAssignment(id: 107, courseIntID: courseInt2ID, name: "Quiz 2: SwiftUI Layout", groupID: 103, dueDaysFromNow: 8, points: 25),
            ],
            rules: nil
        )

        return [
            AssignmentGroup(from: labsGroup),
            AssignmentGroup(from: projectsGroup),
            AssignmentGroup(from: quizzesGroup),
        ]
    }

    static func dummyAssignmentGroups(forCourseID id: String) -> [AssignmentGroup] {
        id == courseID2 ? course2AssignmentGroups : course1AssignmentGroups
    }

    static var dummyAssignmentGroups: [AssignmentGroup] {
        course1AssignmentGroups + course2AssignmentGroups
    }

    static var dummyAssignments: [Assignment] {
        dummyAssignmentGroups.flatMap { group in
            (group.assignments ?? []).map { Assignment(from: $0) }
        }
    }

    // MARK: - Files / Folders

    private static func makeFolder(
        id: Int, parentID: Int?, name: String, fullName: String,
        contextIntID: Int, filesCount: Int, foldersCount: Int,
        createdDaysAgo: Double = 14
    ) -> Folder {
        let createdISO = "2024-01-01T00:00:00Z"
        return Folder(api: FolderAPI(
            id: id,
            name: name,
            full_name: fullName,
            context_id: contextIntID,
            context_type: "Course",
            parent_folder_id: parentID,
            created_at: createdISO,
            updated_at: createdISO,
            lock_at: nil,
            unlock_at: nil,
            position: 0,
            locked: false,
            folders_url: nil,
            files_url: nil,
            files_count: filesCount,
            folders_count: foldersCount,
            hidden: nil,
            locked_for_user: nil,
            hidden_for_user: nil,
            for_submissions: nil,
            can_upload: nil
        ))
    }

    private static var course1RootFolder: Folder {
        makeFolder(id: 1, parentID: nil, name: "Course Files",
                   fullName: "course files/Course Files",
                   contextIntID: courseIntID, filesCount: 5, foldersCount: 1)
    }

    private static var course2RootFolder: Folder {
        makeFolder(id: 101, parentID: nil, name: "Course Files",
                   fullName: "course files/Course Files",
                   contextIntID: courseInt2ID, filesCount: 4, foldersCount: 1)
    }

    static func dummyRootFolder(forCourseID id: String) -> Folder {
        id == courseID2 ? course2RootFolder : course1RootFolder
    }

    static var dummyRootFolder: Folder { course1RootFolder }

    private static func makeFile(
        id: Int, folderId: Int, name: String,
        contentType: String, mimeClass: String, size: Int,
        daysAgo: Double
    ) -> File {
        File(api: FileAPI(
            id: id,
            uuid: "sandbox-uuid-\(id)",
            folder_id: folderId,
            display_name: name,
            filename: name,
            content_type: contentType,
            url: nil,
            size: size,
            created_at: Date.now.addingTimeInterval(-86400 * daysAgo),
            updated_at: Date.now.addingTimeInterval(-86400 * daysAgo),
            unlock_at: nil,
            locked: false,
            hidden: false,
            lock_at: nil,
            hidden_for_user: false,
            thumbnail_url: nil,
            modified_at: Date.now.addingTimeInterval(-86400 * daysAgo),
            mime_class: mimeClass,
            media_entry_id: nil,
            locked_for_user: false,
            lock_explanation: nil,
            preview_url: nil,
            avatar: nil,
            usage_rights: nil,
            visibility_level: "course"
        ))
    }

    private static var course1Files: [File] {
        [
            makeFile(id: 1, folderId: 1, name: "Syllabus.pdf",
                     contentType: "application/pdf", mimeClass: "pdf", size: 102400, daysAgo: 14),
            makeFile(id: 2, folderId: 1, name: "Lecture 1 Slides.pdf",
                     contentType: "application/pdf", mimeClass: "pdf", size: 2048000, daysAgo: 10),
            makeFile(id: 3, folderId: 1, name: "Lecture 2 Slides.pdf",
                     contentType: "application/pdf", mimeClass: "pdf", size: 1835000, daysAgo: 7),
            makeFile(id: 4, folderId: 1, name: "Project Guidelines.docx",
                     contentType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                     mimeClass: "doc", size: 45200, daysAgo: 12),
            makeFile(id: 5, folderId: 1, name: "Sample Data.csv",
                     contentType: "text/csv", mimeClass: "file", size: 8500, daysAgo: 5),
            makeFile(id: 6, folderId: 2, name: "Homework 1 Solutions.pdf",
                     contentType: "application/pdf", mimeClass: "pdf", size: 320000, daysAgo: 3),
        ]
    }

    private static var course2Files: [File] {
        [
            makeFile(id: 101, folderId: 101, name: "CS4261 Syllabus.pdf",
                     contentType: "application/pdf", mimeClass: "pdf", size: 142000, daysAgo: 14),
            makeFile(id: 102, folderId: 101, name: "SwiftUI Cheatsheet.pdf",
                     contentType: "application/pdf", mimeClass: "pdf", size: 680000, daysAgo: 9),
            makeFile(id: 103, folderId: 101, name: "Starter Project.zip",
                     contentType: "application/zip", mimeClass: "file", size: 4500000, daysAgo: 6),
            makeFile(id: 104, folderId: 101, name: "App Design Rubric.docx",
                     contentType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                     mimeClass: "doc", size: 52000, daysAgo: 5),
            makeFile(id: 105, folderId: 102, name: "Demo App Screenshots.zip",
                     contentType: "application/zip", mimeClass: "file", size: 9200000, daysAgo: 2),
        ]
    }

    static func dummyFiles(forCourseID id: String) -> [File] {
        id == courseID2 ? course2Files : course1Files
    }

    static var dummyFiles: [File] { course1Files + course2Files }

    private static var course1Subfolders: [Folder] {
        [makeFolder(id: 2, parentID: 1, name: "Solutions",
                    fullName: "course files/Solutions",
                    contextIntID: courseIntID, filesCount: 1, foldersCount: 0,
                    createdDaysAgo: 9)]
    }

    private static var course2Subfolders: [Folder] {
        [makeFolder(id: 102, parentID: 101, name: "Demos",
                    fullName: "course files/Demos",
                    contextIntID: courseInt2ID, filesCount: 1, foldersCount: 0,
                    createdDaysAgo: 9)]
    }

    static func dummySubfolders(forCourseID id: String) -> [Folder] {
        id == courseID2 ? course2Subfolders : course1Subfolders
    }

    static var dummySubfolders: [Folder] { course1Subfolders + course2Subfolders }

    // MARK: - People

    private static func makeEnrollment(
        id: Int, courseIntID: Int, type: String, roleId: Int, userId: Int
    ) -> EnrollmentAPI {
        EnrollmentAPI(
            id: id, course_id: courseIntID, course_section_id: nil,
            enrollment_state: .active, type: type, user_id: userId,
            associated_user_id: nil, role: type, role_id: roleId,
            start_at: nil, end_at: nil, last_activity_at: nil,
            grades: nil, user: nil,
            computed_current_score: nil, computed_final_score: nil,
            computed_current_grade: nil, computed_current_letter_grade: nil,
            computed_final_grade: nil, multiple_grading_periods_enabled: nil,
            totals_for_all_grading_periods_option: nil,
            current_grading_period_id: nil,
            current_period_computed_current_score: nil,
            current_period_computed_final_score: nil,
            current_period_computed_current_grade: nil,
            current_period_computed_final_grade: nil,
            observed_user: nil
        )
    }

    private static func makeUser(
        id: Int, first: String, last: String,
        enrollment: EnrollmentAPI, role: String,
        email: String, bio: String, pronouns: String? = nil
    ) -> UserAPI {
        UserAPI(
            id: id,
            name: "\(first) \(last)",
            sortable_name: "\(last), \(first)",
            last_name: last,
            first_name: first,
            short_name: first,
            sis_user_id: nil,
            sis_import_id: nil,
            integration_id: nil,
            login_id: "\(first.lowercased()).\(last.lowercased())",
            avatar_url: nil,
            avatar_state: nil,
            enrollments: [enrollment],
            email: email,
            locale: "en",
            last_login: nil,
            time_zone: "America/New_York",
            bio: bio,
            pronouns: pronouns,
            role: role
        )
    }

    private static var course1Users: [User] {
        let studentEnrollment1 = makeEnrollment(id: 1, courseIntID: courseIntID, type: "StudentEnrollment", roleId: 3, userId: 1001)
        let studentEnrollment2 = makeEnrollment(id: 3, courseIntID: courseIntID, type: "StudentEnrollment", roleId: 3, userId: 1003)
        let studentEnrollment3 = makeEnrollment(id: 4, courseIntID: courseIntID, type: "StudentEnrollment", roleId: 3, userId: 1004)
        let studentEnrollment4 = makeEnrollment(id: 5, courseIntID: courseIntID, type: "StudentEnrollment", roleId: 3, userId: 1005)
        let studentEnrollment5 = makeEnrollment(id: 6, courseIntID: courseIntID, type: "StudentEnrollment", roleId: 3, userId: 1006)
        let teacherEnrollment = makeEnrollment(id: 2, courseIntID: courseIntID, type: "TeacherEnrollment", roleId: 4, userId: 1002)
        let taEnrollment = makeEnrollment(id: 7, courseIntID: courseIntID, type: "TaEnrollment", roleId: 5, userId: 1007)

        return [
            makeUser(id: 1001, first: "Aziz", last: "Albahar",
                     enrollment: studentEnrollment1, role: "student",
                     email: "aziz.albahar@example.edu",
                     bio: "CS student interested in mobile app development.", pronouns: "he/him"),
            makeUser(id: 1002, first: "Ivan", last: "Li",
                     enrollment: teacherEnrollment, role: "teacher",
                     email: "ivan.li@example.edu",
                     bio: "Instructor for the sandbox course."),
            makeUser(id: 1003, first: "Rahul", last: "Narayanan",
                     enrollment: studentEnrollment2, role: "student",
                     email: "rahul.narayanan@example.edu",
                     bio: "Design student focused on UI/UX.", pronouns: "they/them"),
            makeUser(id: 1004, first: "Jane", last: "Smith",
                     enrollment: studentEnrollment3, role: "student",
                     email: "jane.smith@example.edu",
                     bio: "Double major in math and CS.", pronouns: "she/her"),
            makeUser(id: 1005, first: "Alex", last: "Chen",
                     enrollment: studentEnrollment4, role: "student",
                     email: "alex.chen@example.edu",
                     bio: "Studying machine learning."),
            makeUser(id: 1006, first: "Maria", last: "Garcia",
                     enrollment: studentEnrollment5, role: "student",
                     email: "maria.garcia@example.edu",
                     bio: "Transfer student from community college.", pronouns: "she/her"),
            makeUser(id: 1007, first: "Taylor", last: "Nguyen",
                     enrollment: taEnrollment, role: "ta",
                     email: "taylor.nguyen@example.edu",
                     bio: "Graduate TA — office hours Wed 3-5pm."),
        ].map { User(from: $0) }
    }

    private static var course2Users: [User] {
        let studentE1 = makeEnrollment(id: 101, courseIntID: courseInt2ID, type: "StudentEnrollment", roleId: 3, userId: 2001)
        let studentE2 = makeEnrollment(id: 102, courseIntID: courseInt2ID, type: "StudentEnrollment", roleId: 3, userId: 2002)
        let studentE3 = makeEnrollment(id: 103, courseIntID: courseInt2ID, type: "StudentEnrollment", roleId: 3, userId: 2003)
        let teacherE = makeEnrollment(id: 104, courseIntID: courseInt2ID, type: "TeacherEnrollment", roleId: 4, userId: 1002)
        let taE = makeEnrollment(id: 105, courseIntID: courseInt2ID, type: "TaEnrollment", roleId: 5, userId: 2004)

        return [
            makeUser(id: 2001, first: "Rahul", last: "Shrestha",
                     enrollment: studentE1, role: "student",
                     email: "rahul.shrestha@example.edu", bio: "iOS dev enthusiast.", pronouns: "he/him"),
            makeUser(id: 1002, first: "Ivan", last: "Li",
                     enrollment: teacherE, role: "teacher",
                     email: "ivan.li@example.edu", bio: "Instructor for CS4261 — iOS apps & Swift."),
            makeUser(id: 2002, first: "Priya", last: "Anand",
                     enrollment: studentE2, role: "student",
                     email: "priya.anand@example.edu", bio: "Full-stack dev turning mobile.", pronouns: "she/her"),
            makeUser(id: 2003, first: "Chris", last: "O'Connell",
                     enrollment: studentE3, role: "student",
                     email: "chris.oconnell@example.edu", bio: "Indie game developer."),
            makeUser(id: 2004, first: "Dana", last: "Kim",
                     enrollment: taE, role: "ta",
                     email: "dana.kim@example.edu", bio: "TA — previous student of CS4261."),
        ].map { User(from: $0) }
    }

    static func dummyUsers(forCourseID id: String) -> [User] {
        id == courseID2 ? course2Users : course1Users
    }

    static var dummyUsers: [User] {
        var seen = Set<String>()
        return (course1Users + course2Users).filter { user in
            seen.insert(user.id).inserted
        }
    }

    // MARK: - Grades (Enrollment)

    private static func makeGradesEnrollment(
        enrollmentId: Int, courseIntID: Int,
        gradesURL: String, letterGrade: String, score: Double
    ) -> Enrollment {
        Enrollment(from: EnrollmentAPI(
            id: enrollmentId,
            course_id: courseIntID,
            course_section_id: nil,
            enrollment_state: .active,
            type: "StudentEnrollment",
            user_id: 1001,
            associated_user_id: nil,
            role: "StudentEnrollment",
            role_id: 3,
            start_at: nil,
            end_at: nil,
            last_activity_at: nil,
            grades: Grades(
                html_url: gradesURL,
                current_grade: letterGrade,
                final_grade: nil,
                current_score: score,
                final_score: nil,
                override_grade: nil,
                override_score: nil,
                unposted_current_grade: nil,
                unposted_current_score: nil
            ),
            user: UserAPI.sample1,
            computed_current_score: nil,
            computed_final_score: nil,
            computed_current_grade: nil,
            computed_current_letter_grade: nil,
            computed_final_grade: nil,
            multiple_grading_periods_enabled: nil,
            totals_for_all_grading_periods_option: nil,
            current_grading_period_id: nil,
            current_period_computed_current_score: nil,
            current_period_computed_final_score: nil,
            current_period_computed_current_grade: nil,
            current_period_computed_final_grade: nil,
            observed_user: nil
        ))
    }

    static func dummyEnrollment(forCourseID id: String) -> Enrollment {
        if id == courseID2 {
            return makeGradesEnrollment(
                enrollmentId: 2, courseIntID: courseInt2ID,
                gradesURL: "https://canvas.example.edu/courses/67890/grades",
                letterGrade: "A-", score: 92
            )
        }
        return makeGradesEnrollment(
            enrollmentId: 1, courseIntID: courseIntID,
            gradesURL: "https://canvas.example.edu/courses/12345/grades",
            letterGrade: "B+", score: 87
        )
    }

    static var dummyEnrollment: Enrollment { dummyEnrollment(forCourseID: courseID) }

    // MARK: - Quizzes

    private static func makeQuiz(
        id: Int, courseID: String, courseIntID: Int,
        title: String, description: String,
        questionCount: Int, points: Double, timeLimit: Double?,
        dueDaysFromNow: Double, attempts: Int = 1,
        quizType: QuizType = .assignment
    ) -> Quiz {
        let htmlURL = URL(string: "https://canvas.example.edu/courses/\(courseIntID)/quizzes/\(id)")!
        let quizAPI = QuizAPI(
            id: id,
            access_code: nil,
            all_dates: nil,
            allowed_attempts: attempts,
            assignment_id: nil,
            cant_go_back: false,
            description: description,
            due_at: Date.now.addingTimeInterval(86400 * dueDaysFromNow),
            has_access_code: false,
            hide_correct_answers_at: nil,
            hide_results: nil,
            html_url: htmlURL,
            ip_filter: nil, lock_at: nil, lock_explanation: nil,
            locked_for_user: false,
            mobile_url: htmlURL,
            one_question_at_a_time: false, points_possible: points,
            published: true, question_count: questionCount,
            question_types: nil, quiz_type: quizType,
            require_lockdown_browser_for_results: false,
            require_lockdown_browser: false,
            scoring_policy: nil,
            show_correct_answers: true,
            show_correct_answers_at: nil,
            show_correct_answers_last_attempt: false,
            shuffle_answers: true,
            time_limit: timeLimit,
            title: title,
            unlock_at: nil,
            unpublishable: false,
            anonymous_submissions: false
        )
        var quiz = Quiz(api: quizAPI)
        quiz.courseID = courseID
        return quiz
    }

    private static var course1Quizzes: [Quiz] {
        [
            makeQuiz(id: 1, courseID: courseID, courseIntID: courseIntID,
                     title: "Syllabus Quiz", description: "Quiz on the course syllabus.",
                     questionCount: 5, points: 10, timeLimit: 15, dueDaysFromNow: 3, attempts: 3,
                     quizType: .practiceQuiz),
            makeQuiz(id: 2, courseID: courseID, courseIntID: courseIntID,
                     title: "Week 1 Knowledge Check", description: "Covers Lectures 1 and 2.",
                     questionCount: 10, points: 20, timeLimit: 30, dueDaysFromNow: 7),
            makeQuiz(id: 3, courseID: courseID, courseIntID: courseIntID,
                     title: "Midterm Practice Exam", description: "Ungraded practice for the midterm.",
                     questionCount: 25, points: 50, timeLimit: 60, dueDaysFromNow: 18, attempts: -1,
                     quizType: .practiceQuiz),
        ]
    }

    private static var course2Quizzes: [Quiz] {
        [
            makeQuiz(id: 101, courseID: courseID2, courseIntID: courseInt2ID,
                     title: "Swift Basics Check", description: "Warm-up quiz on Swift syntax & types.",
                     questionCount: 8, points: 15, timeLimit: 20, dueDaysFromNow: 2, attempts: 2),
            makeQuiz(id: 102, courseID: courseID2, courseIntID: courseInt2ID,
                     title: "SwiftUI Layout Quiz", description: "HStack, VStack, ZStack and friends.",
                     questionCount: 12, points: 25, timeLimit: 30, dueDaysFromNow: 9),
        ]
    }

    static func dummyQuizzes(forCourseID id: String) -> [Quiz] {
        id == courseID2 ? course2Quizzes : course1Quizzes
    }

    static var dummyQuizzes: [Quiz] {
        course1Quizzes + course2Quizzes
    }

    // MARK: - Modules

    private static func makeModuleItem(
        id: Int, moduleId: Int, position: Int, title: String,
        type: APIModuleItemType, contentId: Int? = nil,
        pageUrl: String? = nil
    ) -> APIModuleItem {
        APIModuleItem(
            id: id, module_id: moduleId, position: position,
            title: title, indent: 0, type: type,
            content_id: contentId, html_url: nil, url: nil,
            page_url: pageUrl, external_url: nil, new_tab: nil,
            completion_requirement: nil, content_details: nil,
            published: true, quiz_lti: nil
        )
    }

    private static var course1Modules: [Module] {
        let module1 = APIModule(
            id: 1, workflow_state: .active, position: 0,
            name: "Getting Started", unlock_at: nil,
            require_sequential_progress: false,
            prerequisite_module_ids: [],
            items_count: 2,
            items_url: nil,
            items: [
                APIModuleItem(
                    id: 1,
                    module_id: 1,
                    position: 0,
                    title: "Welcome Page",
                    indent: 0,
                    type: .page,
                    content_id: 1,
                    html_url: nil,
                    url: nil,
                    page_url: "welcome",
                    external_url: nil,
                    new_tab: nil,
                    completion_requirement: nil,
                    content_details: nil,
                    published: true,
                    quiz_lti: nil
                ),
                APIModuleItem(
                    id: 2,
                    module_id: 1,
                    position: 1,
                    title: "Introduction Assignment",
                    indent: 0,
                    type: .assignment,
                    content_id: 1,
                    html_url: nil,
                    url: nil,
                    page_url: nil,
                    external_url: nil,
                    new_tab: nil,
                    completion_requirement: nil,
                    content_details: nil,
                    published: true,
                    quiz_lti: nil
                )
            ],
            state: .unlocked,
            completed_at: nil,
            published: true
        )
        let module = Module(from: module1)
        module.courseID = courseID
        return [module]
    }

    private static var course2Modules: [Module] {
        let module1 = APIModule(
            id: 101, workflow_state: .active, position: 0,
            name: "Intro to Swift", unlock_at: nil,
            require_sequential_progress: false,
            prerequisite_module_ids: [], items_count: 3, items_url: nil,
            items: [
                makeModuleItem(id: 101, moduleId: 101, position: 0, title: "Welcome to CS4261",
                               type: .page, pageUrl: "cs4261-welcome"),
                makeModuleItem(id: 102, moduleId: 101, position: 1, title: "Swift Basics Check",
                               type: .quiz, contentId: 101),
                makeModuleItem(id: 103, moduleId: 101, position: 2, title: "Lab 1: Hello SwiftUI",
                               type: .assignment, contentId: 101),
            ],
            state: .unlocked, completed_at: nil, published: true
        )

        let module2 = APIModule(
            id: 102, workflow_state: .active, position: 1,
            name: "SwiftUI Fundamentals", unlock_at: nil,
            require_sequential_progress: false,
            prerequisite_module_ids: [101], items_count: 3, items_url: nil,
            items: [
                makeModuleItem(id: 104, moduleId: 102, position: 0, title: "SwiftUI Cheatsheet",
                               type: .file, contentId: 102),
                makeModuleItem(id: 105, moduleId: 102, position: 1, title: "Layout Containers",
                               type: .page, pageUrl: "cs4261-layout"),
                makeModuleItem(id: 106, moduleId: 102, position: 2, title: "Lab 2: Navigation & State",
                               type: .assignment, contentId: 102),
            ],
            state: .unlocked, completed_at: nil, published: true
        )

        let module3 = APIModule(
            id: 103, workflow_state: .active, position: 2,
            name: "Networking & Persistence", unlock_at: nil,
            require_sequential_progress: false,
            prerequisite_module_ids: [102], items_count: 3, items_url: nil,
            items: [
                makeModuleItem(id: 107, moduleId: 103, position: 0, title: "async/await Overview",
                               type: .page, pageUrl: "cs4261-async"),
                makeModuleItem(id: 108, moduleId: 103, position: 1, title: "Starter Project",
                               type: .file, contentId: 103),
                makeModuleItem(id: 109, moduleId: 103, position: 2, title: "Lab 3: Networking",
                               type: .assignment, contentId: 103),
            ],
            state: .locked, completed_at: nil, published: true
        )

        return [module1, module2, module3].map { api in
            var m = Module(from: api)
            m.courseID = courseID2
            return m
        }
    }

    static func dummyModules(forCourseID id: String) -> [Module] {
        id == courseID2 ? course2Modules : course1Modules
    }

    static var dummyModules: [Module] {
        course1Modules + course2Modules
    }

    static func dummyModuleItems(forCourseID id: String) -> [ModuleItem] {
        dummyModules(forCourseID: id).flatMap { module in
            (module.items ?? []).map { ModuleItem(from: $0) }
        }
    }

    static var dummyModuleItems: [ModuleItem] {
        dummyModules.flatMap { module in
            (module.items ?? []).map { apiItem in
                let item = ModuleItem(from: apiItem)
                return item
            }
        }
    }

    // MARK: - Pages

    private static func makePage(
        id: Int, courseID: String, url: String, title: String,
        body: String, isFront: Bool, daysAgo: Double
    ) -> Page {
        let page = Page(pageAPI: PageAPI(
            page_id: id, url: url, title: title,
            created_at: Date.now.addingTimeInterval(-86400 * daysAgo),
            updated_at: Date.now.addingTimeInterval(-86400 * daysAgo),
            body: body, published: true, publish_at: nil, front_page: isFront
        ))
        page.courseID = courseID
        return page
    }

    private static var course1Pages: [Page] {
        [
            makePage(id: 1, courseID: courseID, url: "welcome", title: "Welcome",
                     body: "<h2>Welcome!</h2><p>This is the sandbox course homepage. Use the navigation tabs to explore.</p>",
                     isFront: true, daysAgo: 14),
            makePage(id: 2, courseID: courseID, url: "resources", title: "Resources",
                     body: "<h2>Helpful Resources</h2><ul><li>Textbook: Intro to CS, 4th Ed.</li><li>Office Hours: Tues/Thurs 2-4 PM</li><li>Tutoring Center: Room 110</li></ul>",
                     isFront: false, daysAgo: 10),
            makePage(id: 3, courseID: courseID, url: "faq", title: "FAQ",
                     body: "<h2>Frequently Asked Questions</h2><p><strong>Q: How is the grade calculated?</strong></p><p>A: Homework 40%, Exams 40%, Participation 20%.</p><p><strong>Q: Can I submit late?</strong></p><p>A: Late work loses 10% per day.</p>",
                     isFront: false, daysAgo: 10),
            makePage(id: 4, courseID: courseID, url: "schedule", title: "Course Schedule",
                     body: "<h2>Schedule</h2><p>Week 1: Intro &amp; Setup</p><p>Week 2: Data Structures</p><p>Week 3: Algorithms</p><p>Week 4: Midterm Review</p>",
                     isFront: false, daysAgo: 8),
        ]
    }

    private static var course2Pages: [Page] {
        [
            makePage(id: 101, courseID: courseID2, url: "cs4261-welcome", title: "Welcome to CS4261",
                     body: "<h2>Welcome to Mobile App Development!</h2><p>We'll build iOS apps with SwiftUI and Swift. Check the schedule page for weekly topics.</p>",
                     isFront: true, daysAgo: 14),
            makePage(id: 102, courseID: courseID2, url: "cs4261-layout", title: "Layout Containers",
                     body: "<h2>SwiftUI Layout Containers</h2><ul><li>HStack — horizontal</li><li>VStack — vertical</li><li>ZStack — overlapping</li><li>Grid — 2D layout</li></ul>",
                     isFront: false, daysAgo: 8),
            makePage(id: 103, courseID: courseID2, url: "cs4261-async", title: "async/await Overview",
                     body: "<h2>Structured Concurrency</h2><p>Swift's async/await makes networking simple. Use <code>Task</code> to bridge UI events and async work.</p>",
                     isFront: false, daysAgo: 5),
        ]
    }

    static func dummyPages(forCourseID id: String) -> [Page] {
        id == courseID2 ? course2Pages : course1Pages
    }

    static var dummyPages: [Page] {
        course1Pages + course2Pages
    }

    // MARK: - Groups

    private static var course1Groups: [CanvasGroup] {
        let projectTeams = APIGroup.GroupCategory(
            id: 42, name: "Project Teams",
            group_limit: 6, allows_multiple_memberships: false
        )

        let group1 = APIGroup(
            id: 101, name: "Team Alpha",
            description: "Working on the data visualization project.",
            concluded: false, members_count: 3, course_id: courseIntID,
            group_category: projectTeams,
            storage_quota_mb: 1024, is_public: false,
            users: [UserAPI.sample1, UserAPI.sample2],
            permissions: APIGroup.Permissions(
                create_discussion_topic: true,
                join: false,
                create_announcement: true
            ),
            join_level: .invitationOnly,
            avatar_url: nil,
            max_membership: 8
        )

        let group2 = APIGroup(
            id: 102, name: "Team Beta",
            description: "Responsible for the testing framework.",
            concluded: false, members_count: 2, course_id: courseIntID,
            group_category: projectTeams,
            storage_quota_mb: 1024, is_public: false,
            users: [UserAPI.sample1],
            permissions: APIGroup.Permissions(
                create_discussion_topic: true, join: true,
                create_announcement: false
            ),
            join_level: .parentContextAutoJoin, avatar_url: nil, max_membership: 6
        )

        let studyGroups = APIGroup.GroupCategory(
            id: 43, name: "Study Groups",
            group_limit: 10, allows_multiple_memberships: true
        )

        let group3 = APIGroup(
            id: 103, name: "Exam Prep Study Group",
            description: "Open study group for midterm preparation.",
            concluded: false, members_count: 5, course_id: courseIntID,
            group_category: studyGroups,
            storage_quota_mb: 512, is_public: true,
            users: nil,
            permissions: APIGroup.Permissions(
                create_discussion_topic: true, join: true,
                create_announcement: false
            ),
            join_level: .parentContextAutoJoin, avatar_url: nil, max_membership: 10
        )

        return [group1, group2, group3].map { CanvasGroup(from: $0) }
    }

    private static var course2Groups: [CanvasGroup] {
        let appTeams = APIGroup.GroupCategory(
            id: 142, name: "App Teams",
            group_limit: 4, allows_multiple_memberships: false
        )

        let group1 = APIGroup(
            id: 201, name: "Team Swift",
            description: "Building a productivity app for students.",
            concluded: false, members_count: 3, course_id: courseInt2ID,
            group_category: appTeams,
            storage_quota_mb: 1024, is_public: false,
            users: [UserAPI.sample1, UserAPI.sample2],
            permissions: APIGroup.Permissions(
                create_discussion_topic: true, join: false,
                create_announcement: true
            ),
            join_level: .invitationOnly, avatar_url: nil, max_membership: 4
        )

        let group2 = APIGroup(
            id: 202, name: "Team Kotlin",
            description: "Exploring cross-platform with Kotlin Multiplatform.",
            concluded: false, members_count: 2, course_id: courseInt2ID,
            group_category: appTeams,
            storage_quota_mb: 1024, is_public: false,
            users: [UserAPI.sample1],
            permissions: APIGroup.Permissions(
                create_discussion_topic: true, join: true,
                create_announcement: false
            ),
            join_level: .parentContextAutoJoin, avatar_url: nil, max_membership: 4
        )

        return [group1, group2].map { CanvasGroup(from: $0) }
    }

    static func dummyGroups(forCourseID id: String) -> [CanvasGroup] {
        id == courseID2 ? course2Groups : course1Groups
    }

    static var dummyGroups: [CanvasGroup] {
        course1Groups + course2Groups
    }

    // MARK: - To-Do

    static let dummyToDoCount = 2
}

// MARK: - TabAPI Sandbox Extension

extension TabAPI {
    static func sandboxTabs(forCourseIntID intID: Int) -> [TabAPI] {
        func tab(id: String, label: String, position: Int, path: String? = nil) -> TabAPI {
            let segment = path.map { "/\($0)" } ?? ""
            return TabAPI(
                id: id,
                html_url: URL(string: "https://canvas.instructure.com/courses/\(intID)\(segment)")!,
                full_url: URL(string: "https://canvas.instructure.com/courses/\(intID)\(segment)"),
                position: position,
                visibility: .public,
                label: label,
                type: .internal,
                hidden: false,
                url: URL(string: "/courses/\(intID)\(segment)")
            )
        }
        return [
            tab(id: "home", label: "Home", position: 0),
            tab(id: "announcements", label: "Announcements", position: 1, path: "discussion_topics"),
            tab(id: "assignments", label: "Assignments", position: 2, path: "assignments"),
            tab(id: "files", label: "Files", position: 3, path: "files"),
            tab(id: "people", label: "People", position: 4, path: "users"),
            tab(id: "grades", label: "Grades", position: 5, path: "grades"),
            tab(id: "quizzes", label: "Quizzes", position: 6, path: "quizzes"),
            tab(id: "modules", label: "Modules", position: 7, path: "modules"),
            tab(id: "pages", label: "Pages", position: 8, path: "pages"),
            tab(id: "syllabus", label: "Syllabus", position: 9, path: "assignments/syllabus"),
            tab(id: "groups", label: "Groups", position: 10, path: "groups"),
            tab(id: "calendar", label: "Calendar", position: 11, path: "calendar"),
        ]
    }
}
