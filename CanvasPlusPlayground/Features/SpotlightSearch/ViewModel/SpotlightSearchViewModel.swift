//
//  SpotlightSearchViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 3/29/26.
//



import SwiftUI
import SwiftData

/// Drives the Spotlight search overlay: takes user input, queries SwiftData,
/// and produces grouped results.

@Observable
@MainActor
class SpotlightSearchViewModel {
    var searchText = ""
    var results: [SpotlightSearchResult] = []
    var isSearching = false

    var groupedResults: [(category: SearchCategory, items: [SpotlightSearchResult])] {
        Dictionary(grouping: results, by: \.category)
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { (category: $0.key, items: $0.value) }
    }

    /// Main search entry point. Called from `.task(id: searchText)
    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            results = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        let context = ModelContext.shared
        var newResults: [SpotlightSearchResult] = []

        // ── Courses ──────────────────────────────────────────────
        // `displayName` is computed (nickname ?? name), so we search
        // both stored properties separately.
        do {
            let predicate = #Predicate<Course> { course in
                (course.name?.localizedStandardContains(query) == true) ||
                (course.courseCode?.localizedStandardContains(query) == true) ||
                (course.nickname?.localizedStandardContains(query) == true)
            }
            let courses = try context.fetch(FetchDescriptor(predicate: predicate))
            newResults += courses.map { .course($0) }
        } catch {
            LoggerService.main.error("Spotlight search failed for Courses: \(error)")
        }

        // ── Assignments ──────────────────────────────────────────
        // `name` is stored, so this is straightforward.
        do {
            let predicate = #Predicate<Assignment> { assignment in
                assignment.name.localizedStandardContains(query)
            }
            let assignments = try context.fetch(FetchDescriptor(predicate: predicate))
            newResults += assignments.map { .assignment($0) }
        } catch {
            LoggerService.main.error("Spotlight search failed for Assignments: \(error)")
        }

        // ── Announcements (DiscussionTopic) ──────────────────────
        // `title` is stored but Optional. `message` is HTML — searching
        // raw HTML still finds keywords, which is good enough. A future
        // improvement could strip HTML tags before indexing.
        do {
            let predicate = #Predicate<DiscussionTopic> { topic in
                (topic.title?.localizedStandardContains(query) == true) ||
                (topic.message?.localizedStandardContains(query) == true)
            }
            let topics = try context.fetch(FetchDescriptor(predicate: predicate))
            // Only include actual announcements, not general discussion topics
            let announcements = topics.filter { $0.isAnnouncement }
            newResults += announcements.map { .announcement($0) }
        } catch {
            LoggerService.main.error("Spotlight search failed for Announcements: \(error)")
        }

        // ── Quizzes ──────────────────────────────────────────────
        // `title` is stored String (non-optional). `details` is optional HTML.
        do {
            let predicate = #Predicate<Quiz> { quiz in
                quiz.title.localizedStandardContains(query) ||
                (quiz.details?.localizedStandardContains(query) == true)
            }
            let quizzes = try context.fetch(FetchDescriptor(predicate: predicate))
            newResults += quizzes.map { .quiz($0) }
        } catch {
            LoggerService.main.error("Spotlight search failed for Quizzes: \(error)")
        }

        // ── Pages ────────────────────────────────────────────────
        // `displayTitle` is computed (`title ?? "Untitled Page"`), so we
        // search the stored `title` property. `body` is HTML.
        do {
            let predicate = #Predicate<Page> { page in
                (page.title?.localizedStandardContains(query) == true) ||
                (page.body?.localizedStandardContains(query) == true)
            }
            let pages = try context.fetch(FetchDescriptor(predicate: predicate))
            newResults += pages.map { .page($0) }
        } catch {
            LoggerService.main.error("Spotlight search failed for Pages: \(error)")
        }

        // ── Files ────────────────────────────────────────────────
        // File has no `courseId`, so we can't create a full
        // SpotlightSearchResult.file without one. We'll omit
        // the courseID for now (pass empty string) and handle
        // gracefully in navigation. A future improvement could
        // resolve courseID via folder → course mapping.
        do {
            let predicate = #Predicate<File> { file in
                file.displayName.localizedStandardContains(query) ||
                file.filename.localizedStandardContains(query)
            }
            let files = try context.fetch(FetchDescriptor(predicate: predicate))
            newResults += files.map { .file($0, courseID: "") }
        } catch {
            LoggerService.main.error("Spotlight search failed for Files: \(error)")
        }

        // ── Modules ──────────────────────────────────────────────
        // `name` is stored String (non-optional).
        do {
            let predicate = #Predicate<Module> { module in
                module.name.localizedStandardContains(query)
            }
            let modules = try context.fetch(FetchDescriptor(predicate: predicate))
            newResults += modules.map { .module($0) }
        } catch {
            LoggerService.main.error("Spotlight search failed for Modules: \(error)")
        }

        // ── People (User) ────────────────────────────────────────
        // Multiple stored name fields to search across.
        do {
            let predicate = #Predicate<User> { user in
                user.name.localizedStandardContains(query) ||
                user.shortName.localizedStandardContains(query) ||
                (user.email?.localizedStandardContains(query) == true)
            }
            let users = try context.fetch(FetchDescriptor(predicate: predicate))
            newResults += users.map { .person($0) }
        } catch {
            LoggerService.main.error("Spotlight search failed for People: \(error)")
        }

        // ── Groups ───────────────────────────────────────────────
        do {
            let predicate = #Predicate<CanvasGroup> { group in
                group.name.localizedStandardContains(query) ||
                (group.groupDescription?.localizedStandardContains(query) == true)
            }
            let groups = try context.fetch(FetchDescriptor(predicate: predicate))
            newResults += groups.map { .group($0) }
        } catch {
            LoggerService.main.error("Spotlight search failed for Groups: \(error)")
        }

        // ── To-Do Items ─────────────────────────────────────────
        // `title` is computed (`assignmentAPI?.name ?? quizAPI?.title`),
        // so we can't use it in #Predicate. `contextName` is stored,
        // so we search that. For the title, we fetch all and filter
        // in memory — there are typically few to-do items.
        do {
            let allToDos = try context.fetch(FetchDescriptor<ToDoItem>())
            let matched = allToDos.filter { todo in
                todo.title.localizedStandardContains(query) ||
                todo.contextName.localizedStandardContains(query)
            }
            newResults += matched.map { .toDoItem($0) }
        } catch {
            LoggerService.main.error("Spotlight search failed for ToDoItems: \(error)")
        }

        results = newResults
    }
}
