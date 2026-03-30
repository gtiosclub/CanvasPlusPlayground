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

    // MARK: - Courses

    private static let sandboxTerm = CourseTermAPI(
        id: 876,
        name: "Sandbox Term",
        start_at: Date.now.addingTimeInterval(-5184000),
        end_at: Date.now.addingTimeInterval(5184000),
        created_at: nil,
        workflow_state: .active,
        grading_period_group_id: nil
    )

    private static let studentEnrollment = CourseEnrollment(
        type: "student",
        role: "StudentEnrollment",
        roleId: 3,
        userId: 54321,
        enrollmentState: .active,
        limitPrivilegesToCourseSection: false
    )

    private static func buildCourse(from api: CourseAPI, id: String, tabs: [TabAPI]) -> Course {
        let course = Course(api)
        let canvasTabs = tabs.map { CanvasTab(from: $0, tabOrigin: .course(id: id)) }
        for tab in canvasTabs {
            tab.course = course
        }
        course.tabs = canvasTabs
        return course
    }

    static var dummyCourses: [Course] {
        [dummyCourse1, dummyCourse2]
    }

    static var dummyCourse: Course { dummyCourse1 }

    static var dummyCourse1: Course {
        buildCourse(from: CourseAPI(
            id: 12345,
            name: "Example Course",
            course_code: "SANDBOX101",
            original_name: "Sandbox - Introduction to Canvas Plus",
            course_color: "#0077B6",
            workflow_state: .available,
            account_id: 5432,
            created_at: Date.now.addingTimeInterval(-7776000),
            start_at: Date.now.addingTimeInterval(-5184000),
            end_at: Date.now.addingTimeInterval(5184000),
            locale: "en",
            enrollments: [studentEnrollment],
            total_students: 7,
            calendar: CalendarLink(ics: nil),
            default_view: .assignments,
            syllabus_body: "<p>Welcome to the Canvas Plus sandbox! This course contains sample data for exploring the app.</p>",
            term: sandboxTerm,
            course_progress: nil,
            apply_assignment_group_weights: true,
            teachers: [CourseTeacher.sample],
            permissions: CoursePermissions(createAnnouncement: true, createDiscussionTopic: true),
            is_public: false,
            homeroom_course: false,
            public_description: "Sandbox course for development",
            hide_final_grades: false,
            access_restricted_by_date: false,
            blueprint: false,
            banner_image_download_url: nil,
            image_download_url: nil,
            is_favorite: true,
            sections: [CourseSectionRef.sample],
            tabs: TabAPI.sandboxTabs(forCourseId: "12345"),
            settings: nil,
            concluded: false,
            grading_scheme: CourseAPI.sample.grading_scheme
        ), id: courseID, tabs: TabAPI.sandboxTabs(forCourseId: "12345"))
    }

    static var dummyCourse2: Course {
        buildCourse(from: CourseAPI(
            id: 67890,
            name: "Mobile App Development",
            course_code: "CS4261",
            original_name: "Mobile App Development",
            course_color: "#E63946",
            workflow_state: .available,
            account_id: 5432,
            created_at: Date.now.addingTimeInterval(-7776000),
            start_at: Date.now.addingTimeInterval(-5184000),
            end_at: Date.now.addingTimeInterval(5184000),
            locale: "en",
            enrollments: [studentEnrollment],
            total_students: 25,
            calendar: CalendarLink(ics: nil),
            default_view: .modules,
            syllabus_body: "<p>Learn to build iOS apps with Swift and SwiftUI. Covers UI design, networking, and data persistence.</p>",
            term: sandboxTerm,
            course_progress: nil,
            apply_assignment_group_weights: true,
            teachers: [CourseTeacher.sample],
            permissions: CoursePermissions(createAnnouncement: true, createDiscussionTopic: true),
            is_public: false,
            homeroom_course: false,
            public_description: "Build real-world iOS applications",
            hide_final_grades: false,
            access_restricted_by_date: false,
            blueprint: false,
            banner_image_download_url: nil,
            image_download_url: nil,
            is_favorite: true,
            sections: [CourseSectionRef.sample],
            tabs: TabAPI.sandboxTabs(forCourseId: "67890"),
            settings: nil,
            concluded: false,
            grading_scheme: CourseAPI.sample.grading_scheme
        ), id: courseID2, tabs: TabAPI.sandboxTabs(forCourseId: "67890"))
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
        authorName: String,
        authorId: Int,
        title: String,
        message: String,
        postedDaysAgo: Double,
        pinned: Bool = false,
        readState: DiscussionTopic.ReadState = .read
    ) -> DiscussionTopic {
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
            posted_at: Date.now.addingTimeInterval(-86400 * postedDaysAgo),
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
            context_code: "course_\(courseID)",
            is_announcement: true,
            is_section_specific: false,
            anonymous_state: nil,
            assignment: nil,
            position: 0,
            created_at: Date.now.addingTimeInterval(-86400 * postedDaysAgo),
            sections: nil
        ))
        topic.courseId = courseID
        return topic
    }

    static var dummyAnnouncements: [DiscussionTopic] {
        [
            makeAnnouncement(
                id: 1, authorName: "Ivan Li", authorId: 1002,
                title: "Welcome to the Sandbox Course",
                message: "This is a sandbox environment. All data is static for demonstration purposes.",
                postedDaysAgo: 14, pinned: true
            ),
            makeAnnouncement(
                id: 2, authorName: "Ivan Li", authorId: 1002,
                title: "Midterm Review Session",
                message: "We will hold a review session this Friday at 3 PM in Room 205. Bring your notes!",
                postedDaysAgo: 3
            ),
            makeAnnouncement(
                id: 3, authorName: "Ivan Li", authorId: 1002,
                title: "Office Hours Canceled This Week",
                message: "Due to a conference, office hours are canceled this Thursday. Email me if you need help.",
                postedDaysAgo: 1, readState: .unread
            ),
            makeAnnouncement(
                id: 4, authorName: "Jane Smith", authorId: 1003,
                title: "Study Group Forming",
                message: "Looking for people to form a study group for the final project. Reply here if interested!",
                postedDaysAgo: 0.5, readState: .unread
            ),
        ]
    }

    // MARK: - Assignments

    private static func makeAssignment(
        id: Int, name: String, groupID: Int,
        dueDaysFromNow: Double, points: Double,
        submissionTypes: [String] = ["online_upload"]
    ) -> AssignmentAPI {
        var a = AssignmentAPI(id: id, name: name, groupID: groupID)
        a.due_at = ISO8601DateFormatter().string(from: Date.now.addingTimeInterval(86400 * dueDaysFromNow))
        a.points_possible = points
        a.published = true
        a.course_id = 12345
        a.submission_types = submissionTypes
        return a
    }

    static var dummyAssignmentGroups: [AssignmentGroup] {
        let homeworkGroup = AssignmentGroupAPI(
            id: 1,
            name: "Homework",
            position: 0,
            group_weight: 40,
            assignments: [
                makeAssignment(id: 1, name: "Introduction Assignment", groupID: 1, dueDaysFromNow: 7, points: 100),
                makeAssignment(id: 2, name: "Week 1 Reading Response", groupID: 1, dueDaysFromNow: 1, points: 50),
                makeAssignment(id: 3, name: "Data Structures Problem Set", groupID: 1, dueDaysFromNow: 14, points: 75),
                makeAssignment(id: 4, name: "Essay Draft", groupID: 1, dueDaysFromNow: -2, points: 100,
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
                makeAssignment(id: 5, name: "Midterm Exam", groupID: 2, dueDaysFromNow: 21, points: 200),
                makeAssignment(id: 6, name: "Final Exam", groupID: 2, dueDaysFromNow: 60, points: 300),
            ],
            rules: nil
        )

        let participationGroup = AssignmentGroupAPI(
            id: 3,
            name: "Participation",
            position: 2,
            group_weight: 20,
            assignments: [
                makeAssignment(id: 7, name: "Discussion Post Week 1", groupID: 3, dueDaysFromNow: -5, points: 10,
                               submissionTypes: ["discussion_topic"]),
                makeAssignment(id: 8, name: "Discussion Post Week 2", groupID: 3, dueDaysFromNow: 2, points: 10,
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

    // MARK: - Files

    static var dummyRootFolder: Folder {
        Folder(api: FolderAPI(
            id: 1,
            name: "Course Files",
            full_name: "course files/Course Files",
            context_id: 12345,
            context_type: "Course",
            parent_folder_id: nil,
            created_at: "2024-01-01T00:00:00Z",
            updated_at: "2024-01-01T00:00:00Z",
            lock_at: nil,
            unlock_at: nil,
            position: 0,
            locked: false,
            folders_url: nil,
            files_url: nil,
            files_count: 5,
            folders_count: 1,
            hidden: nil,
            locked_for_user: nil,
            hidden_for_user: nil,
            for_submissions: nil,
            can_upload: nil
        ))
    }

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

    static var dummyFiles: [File] {
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

    static var dummySubfolders: [Folder] {
        [Folder(api: FolderAPI(
            id: 2,
            name: "Solutions",
            full_name: "course files/Solutions",
            context_id: 12345,
            context_type: "Course",
            parent_folder_id: 1,
            created_at: "2024-01-05T00:00:00Z",
            updated_at: "2024-01-05T00:00:00Z",
            lock_at: nil,
            unlock_at: nil,
            position: 0,
            locked: false,
            folders_url: nil,
            files_url: nil,
            files_count: 1,
            folders_count: 0,
            hidden: nil,
            locked_for_user: nil,
            hidden_for_user: nil,
            for_submissions: nil,
            can_upload: nil
        ))]
    }

    // MARK: - People

    private static func makeEnrollment(
        id: Int, type: String, roleId: Int, userId: Int
    ) -> EnrollmentAPI {
        EnrollmentAPI(
            id: id, course_id: 12345, course_section_id: nil,
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
            id: id, name: "\(first) \(last)",
            sortable_name: "\(last), \(first)",
            last_name: last, first_name: first, short_name: first,
            sis_user_id: "SB\(id)", sis_import_id: 5000 + id,
            integration_id: "INT-\(id)", login_id: "\(first.lowercased()).\(last.lowercased())",
            avatar_url: nil, avatar_state: "approved",
            enrollments: [enrollment], email: email,
            locale: "en", last_login: nil,
            time_zone: "America/New_York", bio: bio,
            pronouns: pronouns, role: role
        )
    }

    static var dummyUsers: [User] {
        let studentEnrollment1 = makeEnrollment(id: 1, type: "StudentEnrollment", roleId: 3, userId: 1001)
        let studentEnrollment2 = makeEnrollment(id: 3, type: "StudentEnrollment", roleId: 3, userId: 1003)
        let studentEnrollment3 = makeEnrollment(id: 4, type: "StudentEnrollment", roleId: 3, userId: 1004)
        let studentEnrollment4 = makeEnrollment(id: 5, type: "StudentEnrollment", roleId: 3, userId: 1005)
        let studentEnrollment5 = makeEnrollment(id: 6, type: "StudentEnrollment", roleId: 3, userId: 1006)
        let teacherEnrollment = makeEnrollment(id: 2, type: "TeacherEnrollment", roleId: 4, userId: 1002)
        let taEnrollment = makeEnrollment(id: 7, type: "TaEnrollment", roleId: 5, userId: 1007)

        return [
            makeUser(id: 1001, first: "Steven", last: "Liu",
                     enrollment: studentEnrollment1, role: "student",
                     email: "steven.liu@example.edu", bio: "CS major interested in mobile dev.", pronouns: "he/him"),
            makeUser(id: 1002, first: "Ivan", last: "Li",
                     enrollment: teacherEnrollment, role: "teacher",
                     email: "ivan.li@example.edu", bio: "Instructor for this course."),
            makeUser(id: 1003, first: "Jane", last: "Smith",
                     enrollment: studentEnrollment2, role: "student",
                     email: "jane.smith@example.edu", bio: "Math major.", pronouns: "she/her"),
            makeUser(id: 1004, first: "Alex", last: "Chen",
                     enrollment: studentEnrollment3, role: "student",
                     email: "alex.chen@example.edu", bio: "ECE major."),
            makeUser(id: 1005, first: "Maria", last: "Garcia",
                     enrollment: studentEnrollment4, role: "student",
                     email: "maria.garcia@example.edu", bio: "Biology major.", pronouns: "she/her"),
            makeUser(id: 1006, first: "Jordan", last: "Taylor",
                     enrollment: studentEnrollment5, role: "student",
                     email: "jordan.taylor@example.edu", bio: "Physics major.", pronouns: "they/them"),
            makeUser(id: 1007, first: "Sam", last: "Patel",
                     enrollment: taEnrollment, role: "ta",
                     email: "sam.patel@example.edu", bio: "Teaching assistant."),
        ].map { User(from: $0) }
    }

    // MARK: - Grades (Enrollment)

    static var dummyEnrollment: Enrollment {
        Enrollment(from: EnrollmentAPI(
            id: 1,
            course_id: 12345,
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
                html_url: "https://canvas.example.edu/courses/12345/grades",
                current_grade: "B+",
                final_grade: nil,
                current_score: 87,
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

    // MARK: - Quizzes

    private static func makeQuiz(
        id: Int, title: String, description: String,
        questionCount: Int, points: Double, timeLimit: Double?,
        dueDaysFromNow: Double, attempts: Int = 1,
        quizType: QuizType = .assignment
    ) -> Quiz {
        let quizAPI = QuizAPI(
            id: id, access_code: nil, all_dates: nil,
            allowed_attempts: attempts, assignment_id: id,
            cant_go_back: false, description: description,
            due_at: Date.now.addingTimeInterval(86400 * dueDaysFromNow),
            has_access_code: false, hide_correct_answers_at: nil,
            hide_results: nil,
            html_url: URL(string: "https://canvas.example.edu/courses/12345/quizzes/\(id)")!,
            ip_filter: nil, lock_at: nil, lock_explanation: nil,
            locked_for_user: false,
            mobile_url: URL(string: "https://canvas.example.edu/courses/12345/quizzes/\(id)")!,
            one_question_at_a_time: false, points_possible: points,
            published: true, question_count: questionCount,
            question_types: nil, quiz_type: quizType,
            require_lockdown_browser_for_results: false,
            require_lockdown_browser: false, scoring_policy: nil,
            show_correct_answers: true, show_correct_answers_at: nil,
            show_correct_answers_last_attempt: false,
            shuffle_answers: true, time_limit: timeLimit,
            title: title, unlock_at: nil,
            unpublishable: false, anonymous_submissions: false
        )
        var quiz = Quiz(api: quizAPI)
        quiz.courseID = courseID
        return quiz
    }

    static var dummyQuizzes: [Quiz] {
        [
            makeQuiz(id: 1, title: "Syllabus Quiz", description: "Quiz on the course syllabus.",
                     questionCount: 5, points: 10, timeLimit: 15, dueDaysFromNow: 3, attempts: 3,
                     quizType: .practiceQuiz),
            makeQuiz(id: 2, title: "Week 1 Knowledge Check", description: "Covers Lectures 1 and 2.",
                     questionCount: 10, points: 20, timeLimit: 30, dueDaysFromNow: 7),
            makeQuiz(id: 3, title: "Midterm Practice Exam", description: "Ungraded practice for the midterm.",
                     questionCount: 25, points: 50, timeLimit: 60, dueDaysFromNow: 18, attempts: -1,
                     quizType: .practiceQuiz),
        ]
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

    static var dummyModules: [Module] {
        let module1 = APIModule(
            id: 1, workflow_state: .active, position: 0,
            name: "Getting Started", unlock_at: nil,
            require_sequential_progress: false,
            prerequisite_module_ids: [], items_count: 3, items_url: nil,
            items: [
                makeModuleItem(id: 1, moduleId: 1, position: 0, title: "Welcome Page",
                               type: .page, pageUrl: "welcome"),
                makeModuleItem(id: 2, moduleId: 1, position: 1, title: "Syllabus Quiz",
                               type: .quiz, contentId: 1),
                makeModuleItem(id: 3, moduleId: 1, position: 2, title: "Introduction Assignment",
                               type: .assignment, contentId: 1),
            ],
            state: .unlocked, completed_at: nil, published: true
        )

        let module2 = APIModule(
            id: 2, workflow_state: .active, position: 1,
            name: "Week 1: Foundations", unlock_at: nil,
            require_sequential_progress: false,
            prerequisite_module_ids: [1], items_count: 4, items_url: nil,
            items: [
                makeModuleItem(id: 4, moduleId: 2, position: 0, title: "Week 1 Overview",
                               type: .subHeader),
                makeModuleItem(id: 5, moduleId: 2, position: 1, title: "Lecture 1 Slides",
                               type: .file, contentId: 2),
                makeModuleItem(id: 6, moduleId: 2, position: 2, title: "Week 1 Reading Response",
                               type: .assignment, contentId: 2),
                makeModuleItem(id: 7, moduleId: 2, position: 3, title: "Week 1 Knowledge Check",
                               type: .quiz, contentId: 2),
            ],
            state: .unlocked, completed_at: nil, published: true
        )

        let module3 = APIModule(
            id: 3, workflow_state: .active, position: 2,
            name: "Week 2: Going Deeper", unlock_at: nil,
            require_sequential_progress: false,
            prerequisite_module_ids: [2], items_count: 3, items_url: nil,
            items: [
                makeModuleItem(id: 8, moduleId: 3, position: 0, title: "Lecture 2 Slides",
                               type: .file, contentId: 3),
                makeModuleItem(id: 9, moduleId: 3, position: 1, title: "Resources Page",
                               type: .page, pageUrl: "resources"),
                makeModuleItem(id: 10, moduleId: 3, position: 2, title: "Data Structures Problem Set",
                               type: .assignment, contentId: 3),
            ],
            state: .locked, completed_at: nil, published: true
        )

        return [module1, module2, module3].map { api in
            var m = Module(from: api)
            m.courseID = courseID
            return m
        }
    }

    static var dummyModuleItems: [ModuleItem] {
        dummyModules.flatMap { module in
            (module.items ?? []).map { ModuleItem(from: $0) }
        }
    }

    // MARK: - Pages

    static var dummyPages: [Page] {
        let pages: [(Int, String, String, String, Bool, Double)] = [
            (1, "welcome", "Welcome",
             "<h2>Welcome!</h2><p>This is the sandbox course homepage. Use the navigation tabs to explore.</p>",
             true, 14),
            (2, "resources", "Resources",
             "<h2>Helpful Resources</h2><ul><li>Textbook: Intro to CS, 4th Ed.</li><li>Office Hours: Tues/Thurs 2-4 PM</li><li>Tutoring Center: Room 110</li></ul>",
             false, 10),
            (3, "faq", "FAQ",
             "<h2>Frequently Asked Questions</h2><p><strong>Q: How is the grade calculated?</strong></p><p>A: Homework 40%, Exams 40%, Participation 20%.</p><p><strong>Q: Can I submit late?</strong></p><p>A: Late work loses 10% per day.</p>",
             false, 10),
            (4, "schedule", "Course Schedule",
             "<h2>Schedule</h2><p>Week 1: Intro &amp; Setup</p><p>Week 2: Data Structures</p><p>Week 3: Algorithms</p><p>Week 4: Midterm Review</p>",
             false, 8),
        ]

        return pages.map { (id, url, title, body, isFront, daysAgo) in
            let page = Page(pageAPI: PageAPI(
                page_id: id, url: url, title: title,
                created_at: Date.now.addingTimeInterval(-86400 * daysAgo),
                updated_at: Date.now.addingTimeInterval(-86400 * daysAgo),
                body: body, published: true, publish_at: nil, front_page: isFront
            ))
            page.courseID = courseID
            return page
        }
    }

    // MARK: - Groups

    static var dummyGroups: [CanvasGroup] {
        let projectTeams = APIGroup.GroupCategory(
            id: 42, name: "Project Teams",
            group_limit: 6, allows_multiple_memberships: false
        )

        let group1 = APIGroup(
            id: 101, name: "Team Alpha",
            description: "Working on the data visualization project.",
            concluded: false, members_count: 3, course_id: 12345,
            group_category: projectTeams,
            storage_quota_mb: 1024, is_public: false,
            users: [UserAPI.sample1, UserAPI.sample2],
            permissions: APIGroup.Permissions(
                create_discussion_topic: true, join: false,
                create_announcement: true
            ),
            join_level: .invitationOnly, avatar_url: nil, max_membership: 6
        )

        let group2 = APIGroup(
            id: 102, name: "Team Beta",
            description: "Responsible for the testing framework.",
            concluded: false, members_count: 2, course_id: 12345,
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
            concluded: false, members_count: 5, course_id: 12345,
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

    // MARK: - To-Do

    static let dummyToDoCount = 4
}

// MARK: - TabAPI Sandbox Extension

extension TabAPI {
    private static func makeTab(id: String, label: String, position: Int, path: String, courseId: String) -> TabAPI {
        let base = "https://canvas.instructure.com/courses/\(courseId)"
        let suffix = path.isEmpty ? "" : "/\(path)"
        return TabAPI(
            id: id,
            html_url: URL(string: "\(base)\(suffix)")!,
            full_url: URL(string: "\(base)\(suffix)"),
            position: position,
            visibility: .public,
            label: label,
            type: .internal,
            hidden: false,
            url: URL(string: "/courses/\(courseId)\(suffix)")
        )
    }

    static func sandboxTabs(forCourseId courseId: String) -> [TabAPI] {
        [
            makeTab(id: "home", label: "Home", position: 0, path: "", courseId: courseId),
            makeTab(id: "announcements", label: "Announcements", position: 1, path: "discussion_topics", courseId: courseId),
            makeTab(id: "assignments", label: "Assignments", position: 2, path: "assignments", courseId: courseId),
            makeTab(id: "files", label: "Files", position: 3, path: "files", courseId: courseId),
            makeTab(id: "people", label: "People", position: 4, path: "users", courseId: courseId),
            makeTab(id: "grades", label: "Grades", position: 5, path: "grades", courseId: courseId),
            makeTab(id: "quizzes", label: "Quizzes", position: 6, path: "quizzes", courseId: courseId),
            makeTab(id: "modules", label: "Modules", position: 7, path: "modules", courseId: courseId),
            makeTab(id: "pages", label: "Pages", position: 8, path: "pages", courseId: courseId),
            makeTab(id: "syllabus", label: "Syllabus", position: 9, path: "assignments/syllabus", courseId: courseId),
            makeTab(id: "groups", label: "Groups", position: 10, path: "groups", courseId: courseId),
            makeTab(id: "calendar", label: "Calendar", position: 11, path: "calendar", courseId: courseId),
        ]
    }
}
