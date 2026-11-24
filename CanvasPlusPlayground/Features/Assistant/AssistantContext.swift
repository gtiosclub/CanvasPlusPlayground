//
//  AssistantContext.swift
//  CanvasPlusPlayground
//

import Foundation
import FoundationModels

/// Which screen the student is on, so the assistant can suggest questions for it and scope its
/// answers (a question asked on a course page is about that course).
struct AssistantPageContext: Codable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case dashboard
        case course
        case announcements
        case toDos
        case assignments
        case assignment
        case quiz
        case grades
        case calendar
        case other
    }

    var kind: Kind
    var courseID: String?
    var courseName: String?
    /// The item on screen (an assignment's or quiz's name).
    var itemTitle: String?

    static let dashboard = AssistantPageContext(kind: .dashboard)

    /// A stable key for caching generated questions.
    var cacheKey: String { "\(kind.rawValue)|\(courseID ?? "")|\(itemTitle ?? "")" }

    init(kind: Kind, courseID: String? = nil, courseName: String? = nil, itemTitle: String? = nil) {
        self.kind = kind
        self.courseID = courseID
        self.courseName = courseName
        self.itemTitle = itemTitle
    }

    /// The context for what's on screen: the top of the current navigation stack, else the tab.
    @MainActor
    init(navigation: NavigationModel, courseName: (String) -> String?) {
        if let top = navigation.breadcrumbs.last {
            self.init(destination: top, courseName: courseName)
            return
        }

        switch navigation.selectedTab {
        case .dashboard, .allCourses, .search:
            self.init(kind: .dashboard)
        case .course(let id):
            self.init(kind: .course, courseID: id, courseName: courseName(id))
        case let .coursePage(id, page):
            self.init(kind: Self.pageKind(for: page), courseID: id, courseName: courseName(id))
        }
    }

    @MainActor
    init(destination: NavigationModel.Destination, courseName: (String) -> String?) {
        switch destination {
        case .assignment(let assignment):
            let id = assignment.courseId?.asString
            self.init(kind: .assignment, courseID: id, courseName: id.flatMap(courseName), itemTitle: assignment.name)
        case .quiz(let quiz):
            self.init(kind: .quiz, courseID: quiz.courseID, courseName: courseName(quiz.courseID), itemTitle: quiz.title)
        case .course(let course):
            self.init(kind: .course, courseID: course.id, courseName: course.displayName)
        case let .coursePage(page, course):
            self.init(kind: Self.pageKind(for: page), courseID: course.id, courseName: course.displayName)
        case .announcement(let topic):
            self.init(kind: .announcements, courseID: topic.courseId, courseName: topic.courseId.flatMap(courseName))
        case .allAnnouncements:
            self.init(kind: .announcements)
        case .allToDos, .today:
            self.init(kind: .toDos)
        case .allCalendar, .calendarEvent:
            self.init(kind: .calendar)
        default:
            self.init(kind: .other, courseID: destination.associatedCourseID)
        }
    }

    private static func pageKind(for page: NavigationModel.CoursePage) -> Kind {
        switch page {
        case .assignments, .quizzes: .assignments
        case .announcements: .announcements
        case .grades: .grades
        case .calendar: .calendar
        default: .course
        }
    }
}

/// A question the orb offers, with the icon it's drawn with.
struct AssistantSuggestion: Identifiable, Hashable, Sendable {
    let text: String
    let systemImage: String
    /// Made for this page (by the model or a template) rather than a fixed FAQ.
    var isGenerated = false

    var id: String { text }
}

/// Fixed questions per screen (from the design's notes) plus a few generated for what's on screen.
enum AssistantSuggestions {
    static func faq(for context: AssistantPageContext) -> [AssistantSuggestion] {
        let course = context.courseName.map { " in \($0)" } ?? ""
        switch context.kind {
        case .dashboard, .other:
            return [
                .init(text: "What assignments have been graded?", systemImage: "square.stack.3d.up.fill"),
                .init(text: "Did anything change in my courses?", systemImage: "questionmark"),
                .init(text: "Any new announcements?", systemImage: "megaphone.fill"),
            ]
        case .course:
            return [
                .init(text: "What's due\(course) next week?", systemImage: "calendar"),
                .init(text: "What's my grade\(course)?", systemImage: "chart.bar.fill"),
                .init(text: "When is the next exam\(course)?", systemImage: "pencil.and.list.clipboard"),
            ]
        case .announcements:
            return [
                .init(text: "Any new announcements?", systemImage: "megaphone.fill"),
                .init(text: "Did anything change in my courses?", systemImage: "questionmark"),
            ]
        case .toDos:
            return [
                .init(text: "What should I do first?", systemImage: "flag.fill"),
                .init(text: "Am I missing any work?", systemImage: "exclamationmark.circle.fill"),
            ]
        case .assignments, .assignment, .quiz:
            return [
                .init(text: "Am I missing any work?", systemImage: "exclamationmark.circle.fill"),
                .init(text: "What assignments have been graded?", systemImage: "square.stack.3d.up.fill"),
            ]
        case .grades:
            return [
                .init(text: "What's my grade\(course)?", systemImage: "chart.bar.fill"),
                .init(text: "What assignments have been graded?", systemImage: "square.stack.3d.up.fill"),
            ]
        case .calendar:
            return [
                .init(text: "What does my next week look like?", systemImage: "calendar"),
                .init(text: "When is my next exam?", systemImage: "pencil.and.list.clipboard"),
            ]
        }
    }

    /// Questions about the specific thing on screen, without a model.
    static func templates(for context: AssistantPageContext) -> [AssistantSuggestion] {
        if let title = context.itemTitle {
            return [
                .init(text: "When is \(title) due?", systemImage: "clock", isGenerated: true),
                .init(text: "How much is \(title) worth?", systemImage: "number", isGenerated: true),
            ]
        }
        if let course = context.courseName, context.kind == .course {
            return [.init(text: "What changed in \(course) this week?", systemImage: "sparkles", isGenerated: true)]
        }
        return []
    }

    /// Follow-ups offered under an answer ("Any other questions?").
    static func followUps(after intent: AssistantIntent) -> [String] {
        switch intent {
        case .graded: ["What's my grade overall?", "Am I missing any work?"]
        case .grade: ["What assignments have been graded?", "What's due next week?"]
        case .today: ["What does my next week look like?", "What should I do first?"]
        case .week: ["What should I do first?", "Am I missing any work?"]
        case .changes: ["What does my next week look like?", "Any new announcements?"]
        case .announcements: ["Did anything change in my courses?", "What's due next week?"]
        case .urgent: ["What does my next week look like?", "Am I missing any work?"]
        case .missing: ["What should I do first?", "What assignments have been graded?"]
        case .general: ["What does my next week look like?", "What assignments have been graded?"]
        }
    }

    @available(iOS 26.0, macOS 26.0, *)
    @Generable
    struct GeneratedQuestions {
        @Guide(description: "Two short questions a student on this screen would ask the course assistant, under 8 words each.")
        var questions: [String]
    }

    /// Two questions for this screen from the on-device model, or templates when there's no model.
    @available(iOS 26.0, macOS 26.0, *)
    @MainActor
    static func generate(for context: AssistantPageContext, router: AgentModelRouter = AgentModelRouter()) async -> [AssistantSuggestion] {
        let fallback = templates(for: context)
        let provider = router.provider()
        guard provider.tier == .onDevice, provider.isAvailable else { return fallback }

        var screen = "Screen: \(context.kind.rawValue)"
        if let course = context.courseName { screen += ". Course: \(course)" }
        if let item = context.itemTitle { screen += ". Item: \(item)" }

        let prompt = AgentPrompt(
            instructions: "You suggest questions a student could ask an assistant that answers from their Canvas courses: deadlines, grades, announcements, schedules. Only suggest questions about the screen described.",
            text: screen,
            temperature: 0.5
        )
        do {
            let response = try await provider.respond(to: prompt, tools: [], generating: GeneratedQuestions.self)
            let questions = response.content.questions
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0.count <= 60 }
                .prefix(2)
            let generated = questions.map { AssistantSuggestion(text: $0.hasSuffix("?") ? $0 : $0 + "?", systemImage: "sparkles", isGenerated: true) }
            return generated.isEmpty ? fallback : generated
        } catch {
            return fallback
        }
    }
}
