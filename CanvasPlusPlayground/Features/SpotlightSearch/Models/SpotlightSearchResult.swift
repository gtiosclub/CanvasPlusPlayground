//
//  SearchResult.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 3/29/26.
//

import SwiftUI

/// A unified search result that wraps any searchable Canvas model.
 
enum SpotlightSearchResult: Identifiable, Hashable {
    case course(Course)
    case assignment(Assignment)
    case announcement(DiscussionTopic)
    case quiz(Quiz)
    case page(Page)
    case file(File, courseID: Course.ID)
    case module(Module)
    case person(User)
    case group(CanvasGroup)
    case toDoItem(ToDoItem)

    // MARK: - Identifiable
    var id: String {
        switch self {
        case .course(let c):       "course:\(c.id)"
        case .assignment(let a):   "assignment:\(a.id)"
        case .announcement(let a): "announcement:\(a.id)"
        case .quiz(let q):         "quiz:\(q.id)"
        case .page(let p):         "page:\(p.id)"
        case .file(let f, _):      "file:\(f.id)"
        case .module(let m):       "module:\(m.id)"
        case .person(let u):       "person:\(u.id)"
        case .group(let g):        "group:\(g.id)"
        case .toDoItem(let t):     "todo:\(t.id)"
        }
    }

    // MARK: - Display Properties

    /// Primary text shown in the search result row.
    var title: String {
        switch self {
        case .course(let c):       c.displayName
        case .assignment(let a):   a.name
        case .announcement(let a): a.title ?? "Untitled Announcement"
        case .quiz(let q):         q.title
        case .page(let p):         p.displayTitle
        case .file(let f, _):      f.displayName
        case .module(let m):       m.name
        case .person(let u):       u.name
        case .group(let g):        g.name
        case .toDoItem(let t):     t.title
        }
    }

    /// Secondary text — shows context like course name, due date, email, etc.
    /// Returns nil if no meaningful subtitle exists.
    var subtitle: String? {
        switch self {
        case .course(let c):
            return c.courseCode
        case .assignment(let a):
            // Show due date if available, formatted nicely
            if let dueDate = a.dueDate {
                return "Due \(dueDate.formatted(date: .abbreviated, time: .shortened))"
            }
            return a.pointsPossible.map { _ in "\(a.formattedPointsPossible) pts" }
        case .announcement(let a):
            if let date = a.date {
                return date.formatted(date: .abbreviated, time: .shortened)
            }
            return nil
        case .quiz(let q):
            if let dueDate = q.dueAt {
                return "Due \(dueDate.formatted(date: .abbreviated, time: .shortened))"
            }
            return q.pointsPossible.map { "\(Int($0)) pts" }
        case .page:
            return nil
        case .file(let f, _):
            // Show file size if available
            if let size = f.size {
                return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            }
            return f.mimeClass
        case .module:
            return nil
        case .person(let u):
            return u.email ?? u.pronouns
        case .group(let g):
            return g.groupDescription
        case .toDoItem(let t):
            return t.contextName
        }
    }

    /// SF Symbol name — gives each category a distinct icon.
    var systemImage: String {
        switch self {
        case .course:       "book.fill"
        case .assignment:   "circle.inset.filled"     // matches CoursePage.assignments icon
        case .announcement: "bubble.fill"              // matches CoursePage.announcements icon
        case .quiz:         "questionmark.circle.fill" // matches CoursePage.quizzes icon
        case .page:         "doc.text.fill"            // matches CoursePage.pages icon
        case .file:         "folder.fill"              // matches CoursePage.files icon
        case .module:       "book.closed.circle.fill"  // matches CoursePage.modules icon
        case .person:       "person.crop.circle.fill"  // matches CoursePage.people icon
        case .group:        "person.3.sequence.fill"   // matches CoursePage.groups icon
        case .toDoItem:     "checklist"
        }
    }

    /// Section header text for grouped display.
    var category: SearchCategory {
        switch self {
        case .course:       .courses
        case .assignment:   .assignments
        case .announcement: .announcements
        case .quiz:         .quizzes
        case .page:         .pages
        case .file:         .files
        case .module:       .modules
        case .person:       .people
        case .group:        .groups
        case .toDoItem:     .toDos
        }
    }

    // MARK: - Navigation

  
    func destination(
            courseLookup: (Course.ID) -> Course?
        ) -> NavigationModel.Destination? {
            switch self {
            case .course(let c):
                return .course(c)

            case .assignment(let a):
                return .assignment(a)

            case .announcement(let a):
                return .announcement(a)

            case .quiz(let q):
                return .quiz(q)

            case .page(let p):
                return .page(p)

            case .file(let f, let courseID):
                // NavigationModel.Destination.file takes (File, Course.ID)
                return .file(f, courseID)

            case .module(let m):
                // Modules don't have a dedicated detail Destination in NavigationModel,
                // so we navigate to the course's modules page instead.
                guard let courseID = m.courseID,
                      let course = courseLookup(courseID) else {
                    return nil
                }
                return .coursePage(.modules, course)

            case .person(let u):
                // People don't have a standalone Destination yet.
                // Navigate to the course's people page.
                guard let courseID = u.courseId,
                      let course = courseLookup(courseID) else {
                    return nil
                }
                return .coursePage(.people, course)

            case .group(let g):
                // CanvasGroup.courseId is Int?, needs conversion to String for lookup.
                guard let courseId = g.courseId,
                      let course = courseLookup(String(courseId)) else {
                    return nil
                }
                return .coursePage(.groups, course)

            case .toDoItem:
                // Navigate to the full to-do list view.
                // Could be refined later to navigate to the specific assignment/quiz.
                return .allToDos
            }
        }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SpotlightSearchResult, rhs: SpotlightSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}
