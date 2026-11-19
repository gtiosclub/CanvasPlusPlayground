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
    /// A record the semantic index found by meaning, with the passage that matched.
    struct RelatedResult: Identifiable, Hashable {
        let result: SpotlightSearchResult
        let snippet: String

        var id: String { result.id }
    }

    var searchText = ""
    var results: [SpotlightSearchResult] = []
    /// Hybrid (semantic + keyword) matches from the content index that the title search didn't
    /// already find. Needs no language model; empty until the index has content.
    var relatedResults: [RelatedResult] = []
    var isSearching = false

    static let relatedLimit = 5

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
            relatedResults = []
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

        let related = await relatedResults(for: query, excluding: Set(newResults.map(\.id)), in: context)
        // The query changed while the index was searching; a newer search will fill this in.
        guard !Task.isCancelled else { return }
        relatedResults = related
    }

    // MARK: - Related content

    private func relatedResults(
        for query: String,
        excluding shownIDs: Set<String>,
        in context: ModelContext
    ) async -> [RelatedResult] {
        guard let indexer = SemanticIndexer.shared,
              let matches = try? await indexer.hybridSearch(query, limit: Self.relatedLimit * 3) else {
            return []
        }

        var related: [RelatedResult] = []
        var seen = shownIDs

        // Several chunks of one page can match; keep the best one per record.
        for match in matches {
            guard let result = Self.result(forSourceID: match.sourceID, courseID: match.courseID, in: context),
                  seen.insert(result.id).inserted else {
                continue
            }
            related.append(RelatedResult(result: result, snippet: Self.snippet(match.text)))
            if related.count == Self.relatedLimit { break }
        }

        return related
    }

    /// The cached record behind an index `sourceID` such as `page:123` or `syllabus:456`.
    static func result(forSourceID sourceID: String, courseID: String?, in context: ModelContext) -> SpotlightSearchResult? {
        guard let separator = sourceID.firstIndex(of: ":") else { return nil }
        let kind = sourceID[..<separator]
        let id = String(sourceID[sourceID.index(after: separator)...])

        switch kind {
        case "page":
            return first(Page.self, #Predicate { $0.id == id }, in: context).map { .page($0) }
        case "assignment":
            return first(Assignment.self, #Predicate { $0.id == id }, in: context).map { .assignment($0) }
        case "quiz":
            return first(Quiz.self, #Predicate { $0.id == id }, in: context).map { .quiz($0) }
        case "announcement", "discussion":
            return first(DiscussionTopic.self, #Predicate { $0.id == id }, in: context).map { .announcement($0) }
        case "syllabus":
            return first(Course.self, #Predicate { $0.id == id }, in: context).map { .course($0) }
        case "file":
            return first(File.self, #Predicate { $0.id == id }, in: context).map { .file($0, courseID: courseID ?? "") }
        default:
            return nil
        }
    }

    private static func first<T: PersistentModel>(_ type: T.Type, _ predicate: Predicate<T>, in context: ModelContext) -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private static func snippet(_ text: String) -> String {
        let collapsed = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return collapsed.count > 140 ? String(collapsed.prefix(139)) + "…" : collapsed
    }
}
