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

    // MARK: - Course

    static var dummyCourse: Course {
        let courseAPI = CourseAPI(
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
            syllabus_body: "<p>Welcome to the Canvas Plus sandbox! This course contains sample data for exploring the app.</p>",
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
            public_description: "Sandbox course for development",
            hide_final_grades: false,
            access_restricted_by_date: false,
            blueprint: false,
            banner_image_download_url: nil,
            image_download_url: nil,
            is_favorite: true,
            sections: [CourseSectionRef.sample],
            tabs: TabAPI.sandboxTabs,
            settings: nil,
            concluded: false,
            grading_scheme: CourseAPI.sample.grading_scheme
        )
        let course = Course(courseAPI)
        let tabs = TabAPI.sandboxTabs.map { CanvasTab(from: $0, tabOrigin: .course(id: courseID)) }
        for tab in tabs {
            tab.course = course
        }
        course.tabs = tabs
        return course
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

    static var dummyAnnouncements: [DiscussionTopic] {
        let topic = DiscussionTopic(from: DiscussionTopicAPI(
            id: 1,
            author: DiscussionParticipantAPI(
                id: 54322,
                display_name: "Jane Smith",
                avatar_image_url: nil,
                html_url: nil,
                pronouns: "she/her"
            ),
            title: "Welcome to the Sandbox Course",
            message: "<p>This is a sandbox environment. All data is static for demonstration purposes.</p>",
            html_url: nil,
            posted_at: Date.now.addingTimeInterval(-86400),
            last_reply_at: nil,
            require_initial_post: false,
            user_can_see_posts: true,
            discussion_subentry_count: 0,
            read_state: .read,
            unread_count: 0,
            subscribed: false,
            subscription_hold: nil,
            assignment_id: nil,
            delayed_post_at: nil,
            published: true,
            lock_at: nil,
            locked: false,
            pinned: true,
            locked_for_user: false,
            user_name: "Jane Smith",
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
            context_code: "course_12345",
            is_announcement: true,
            is_section_specific: false,
            anonymous_state: nil,
            assignment: nil,
            position: 0,
            created_at: Date.now.addingTimeInterval(-86400),
            sections: nil
        ))
        topic.courseId = courseID
        return [topic]
    }

    // MARK: - Assignments

    static var dummyAssignmentGroups: [AssignmentGroup] {
        var assignment1 = AssignmentAPI(id: 1, name: "Introduction Assignment", groupID: 1)
        assignment1.due_at = ISO8601DateFormatter().string(from: Date.now.addingTimeInterval(604800))
        assignment1.points_possible = 100
        assignment1.published = true
        assignment1.course_id = 12345

        var assignment2 = AssignmentAPI(id: 2, name: "Week 1 Reading", groupID: 1)
        assignment2.due_at = ISO8601DateFormatter().string(from: Date.now.addingTimeInterval(86400))
        assignment2.points_possible = 50
        assignment2.published = true
        assignment2.course_id = 12345

        let groupAPI = AssignmentGroupAPI(
            id: 1,
            name: "Assignments",
            position: 0,
            group_weight: 100,
            assignments: [assignment1, assignment2],
            rules: nil
        )
        return [AssignmentGroup(from: groupAPI)]
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
            files_count: 1,
            folders_count: 0,
            hidden: nil,
            locked_for_user: nil,
            hidden_for_user: nil,
            for_submissions: nil,
            can_upload: nil
        ))
    }

    static var dummyFiles: [File] {
        [File(api: FileAPI(
            id: 1,
            uuid: "sandbox-uuid-1",
            folder_id: 1,
            display_name: "Syllabus.pdf",
            filename: "Syllabus.pdf",
            content_type: "application/pdf",
            url: nil,
            size: 102400,
            created_at: Date.now.addingTimeInterval(-86400),
            updated_at: Date.now.addingTimeInterval(-86400),
            unlock_at: nil,
            locked: false,
            hidden: false,
            lock_at: nil,
            hidden_for_user: false,
            thumbnail_url: nil,
            modified_at: Date.now.addingTimeInterval(-86400),
            mime_class: "pdf",
            media_entry_id: nil,
            locked_for_user: false,
            lock_explanation: nil,
            preview_url: nil,
            avatar: nil,
            usage_rights: nil,
            visibility_level: "course"
        ))]
    }

    // MARK: - People

    private static let sandboxStudentEnrollment = EnrollmentAPI(
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
        grades: nil,
        user: nil,
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
    )

    private static let sandboxTeacherEnrollment = EnrollmentAPI(
        id: 2,
        course_id: 12345,
        course_section_id: nil,
        enrollment_state: .active,
        type: "TeacherEnrollment",
        user_id: 1002,
        associated_user_id: nil,
        role: "TeacherEnrollment",
        role_id: 4,
        start_at: nil,
        end_at: nil,
        last_activity_at: nil,
        grades: nil,
        user: nil,
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
    )

    static var dummyUsers: [User] {
        let studentUserAPI = UserAPI(
            id: 1001,
            name: "Steven Liu",
            sortable_name: "Liu, Steven",
            last_name: "Liu",
            first_name: "Steven",
            short_name: "Steven",
            sis_user_id: "AC1001",
            sis_import_id: 5001,
            integration_id: "INT-1001",
            login_id: "sliu",
            avatar_url: URL(string: "https://canvas.example.edu/users/1001/avatar.png"),
            avatar_state: "approved",
            enrollments: [sandboxStudentEnrollment],
            email: "steven.liu@example.edu",
            locale: "en",
            last_login: "2025-03-20T14:30:45Z",
            time_zone: "America/Los_Angeles",
            bio: "Computer Science major with an interest in mobile app development.",
            pronouns: "he/him",
            role: "student"
        )
        let teacherUserAPI = UserAPI(
            id: 1002,
            name: "Ivan Li",
            sortable_name: "Li, Ivan",
            last_name: "Li",
            first_name: "Ivan",
            short_name: "Ivan",
            sis_user_id: "JS1002",
            sis_import_id: 5002,
            integration_id: "INT-1002",
            login_id: "iLi",
            avatar_url: URL(string: "https://canvas.example.edu/users/1002/avatar.png"),
            avatar_state: "approved",
            enrollments: [sandboxTeacherEnrollment],
            email: "ivan.li@example.edu",
            locale: "en",
            last_login: "2025-03-23T09:15:22Z",
            time_zone: "America/Chicago",
            bio: "Design student focusing on UI/UX for mobile applications.",
            pronouns: "they/them",
            role: "teacher"
        )
        return [
            User(from: studentUserAPI),
            User(from: teacherUserAPI)
        ]
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

    static var dummyQuizzes: [Quiz] {
        let quizAPI = QuizAPI(
            id: 1,
            access_code: nil,
            all_dates: nil,
            allowed_attempts: 3,
            assignment_id: 1,
            cant_go_back: false,
            description: "Sample quiz for sandbox",
            due_at: Date.now.addingTimeInterval(604800),
            has_access_code: false,
            hide_correct_answers_at: nil,
            hide_results: nil,
            html_url: URL(string: "https://canvas.example.edu/courses/12345/quizzes/1")!,
            ip_filter: nil,
            lock_at: nil,
            lock_explanation: nil,
            locked_for_user: false,
            mobile_url: URL(string: "https://canvas.example.edu/courses/12345/quizzes/1")!,
            one_question_at_a_time: false,
            points_possible: 10,
            published: true,
            question_count: 5,
            question_types: nil,
            quiz_type: .assignment,
            require_lockdown_browser_for_results: false,
            require_lockdown_browser: false,
            scoring_policy: nil,
            show_correct_answers: true,
            show_correct_answers_at: nil,
            show_correct_answers_last_attempt: false,
            shuffle_answers: true,
            time_limit: 30,
            title: "Sample Quiz",
            unlock_at: nil,
            unpublishable: false,
            anonymous_submissions: false
        )
        var quiz = Quiz(api: quizAPI)
        quiz.courseID = courseID
        return [quiz]
    }

    // MARK: - Modules

    static var dummyModules: [Module] {
        let moduleAPI = APIModule(
            id: 1,
            workflow_state: .active,
            position: 0,
            name: "Getting Started",
            unlock_at: nil,
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
        var module = Module(from: moduleAPI)
        module.courseID = courseID
        return [module]
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

    static var dummyPages: [Page] {
        let page = Page(pageAPI: PageAPI(
            page_id: 1,
            url: "welcome",
            title: "Welcome",
            created_at: Date.now.addingTimeInterval(-86400),
            updated_at: Date.now.addingTimeInterval(-86400),
            body: "<p>Welcome to the sandbox course!</p>",
            published: true,
            publish_at: nil,
            front_page: true
        ))
        page.courseID = courseID
        return [page]
    }

    // MARK: - Groups

    static var dummyGroups: [CanvasGroup] {
        let sandboxGroup = APIGroup(
            id: 12345,
            name: "Sandbox Project Group",
            description: "A sample group for sandbox exploration",
            concluded: false,
            members_count: 2,
            course_id: 12345,
            group_category: APIGroup.GroupCategory(
                id: 42,
                name: "Project Teams",
                group_limit: 8,
                allows_multiple_memberships: false
            ),
            storage_quota_mb: 1024,
            is_public: false,
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
        return [CanvasGroup(from: sandboxGroup)]
    }

    // MARK: - To-Do

    static let dummyToDoCount = 2
}

// MARK: - TabAPI Sandbox Extension

extension TabAPI {
    static let sandboxTabs: [TabAPI] = [
        TabAPI(
            id: "home",
            html_url: URL(string: "https://canvas.instructure.com/courses/12345")!,
            full_url: URL(string: "https://canvas.instructure.com/courses/12345"),
            position: 0,
            visibility: .public,
            label: "Home",
            type: .internal,
            hidden: false,
            url: URL(string: "/courses/12345")
        ),
        TabAPI(
            id: "announcements",
            html_url: URL(string: "https://canvas.instructure.com/courses/12345/discussion_topics")!,
            full_url: URL(string: "https://canvas.instructure.com/courses/12345/discussion_topics"),
            position: 1,
            visibility: .public,
            label: "Announcements",
            type: .internal,
            hidden: false,
            url: URL(string: "/courses/12345/discussion_topics")
        ),
        TabAPI(
            id: "assignments",
            html_url: URL(string: "https://canvas.instructure.com/courses/12345/assignments")!,
            full_url: URL(string: "https://canvas.instructure.com/courses/12345/assignments"),
            position: 2,
            visibility: .public,
            label: "Assignments",
            type: .internal,
            hidden: false,
            url: URL(string: "/courses/12345/assignments")
        ),
        TabAPI(
            id: "files",
            html_url: URL(string: "https://canvas.instructure.com/courses/12345/files")!,
            full_url: URL(string: "https://canvas.instructure.com/courses/12345/files"),
            position: 3,
            visibility: .public,
            label: "Files",
            type: .internal,
            hidden: false,
            url: URL(string: "/courses/12345/files")
        ),
        TabAPI(
            id: "people",
            html_url: URL(string: "https://canvas.instructure.com/courses/12345/users")!,
            full_url: URL(string: "https://canvas.instructure.com/courses/12345/users"),
            position: 4,
            visibility: .public,
            label: "People",
            type: .internal,
            hidden: false,
            url: URL(string: "/courses/12345/users")
        ),
        TabAPI(
            id: "grades",
            html_url: URL(string: "https://canvas.instructure.com/courses/12345/grades")!,
            full_url: URL(string: "https://canvas.instructure.com/courses/12345/grades"),
            position: 5,
            visibility: .public,
            label: "Grades",
            type: .internal,
            hidden: false,
            url: URL(string: "/courses/12345/grades")
        ),
        TabAPI(
            id: "quizzes",
            html_url: URL(string: "https://canvas.instructure.com/courses/12345/quizzes")!,
            full_url: URL(string: "https://canvas.instructure.com/courses/12345/quizzes"),
            position: 6,
            visibility: .public,
            label: "Quizzes",
            type: .internal,
            hidden: false,
            url: URL(string: "/courses/12345/quizzes")
        ),
        TabAPI(
            id: "modules",
            html_url: URL(string: "https://canvas.instructure.com/courses/12345/modules")!,
            full_url: URL(string: "https://canvas.instructure.com/courses/12345/modules"),
            position: 7,
            visibility: .public,
            label: "Modules",
            type: .internal,
            hidden: false,
            url: URL(string: "/courses/12345/modules")
        ),
        TabAPI(
            id: "pages",
            html_url: URL(string: "https://canvas.instructure.com/courses/12345/pages")!,
            full_url: URL(string: "https://canvas.instructure.com/courses/12345/pages"),
            position: 8,
            visibility: .public,
            label: "Pages",
            type: .internal,
            hidden: false,
            url: URL(string: "/courses/12345/pages")
        ),
        TabAPI(
            id: "syllabus",
            html_url: URL(string: "https://canvas.instructure.com/courses/12345/assignments/syllabus")!,
            full_url: URL(string: "https://canvas.instructure.com/courses/12345/assignments/syllabus"),
            position: 9,
            visibility: .public,
            label: "Syllabus",
            type: .internal,
            hidden: false,
            url: URL(string: "/courses/12345/assignments/syllabus")
        ),
        TabAPI(
            id: "groups",
            html_url: URL(string: "https://canvas.instructure.com/courses/12345/groups")!,
            full_url: URL(string: "https://canvas.instructure.com/courses/12345/groups"),
            position: 10,
            visibility: .public,
            label: "Groups",
            type: .internal,
            hidden: false,
            url: URL(string: "/courses/12345/groups")
        ),
        TabAPI(
            id: "calendar",
            html_url: URL(string: "https://canvas.instructure.com/courses/12345/calendar")!,
            full_url: URL(string: "https://canvas.instructure.com/courses/12345/calendar"),
            position: 11,
            visibility: .public,
            label: "Calendar",
            type: .internal,
            hidden: false,
            url: URL(string: "/courses/12345/calendar")
        )
    ]
}
