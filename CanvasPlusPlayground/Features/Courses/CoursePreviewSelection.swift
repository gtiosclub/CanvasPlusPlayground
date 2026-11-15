import Foundation

enum CoursePreviewSelection {
    /// - Parameter html: Optional course syllabus HTML.
    /// - Returns: At most 280 characters with separated blocks; empty means use a plain row.
    static func syllabusExcerpt(_ html: String?) -> String {
        let blocks = HTMLTextNormalizer().blocks(fromHTML: html ?? "")
        let text = blocks.map(\.text).joined(separator: " ").split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return text.count > 280 ? String(text.prefix(279)) + "…" : text
    }

    /// - Parameter pages: The single fetched page list.
    /// - Returns: One front page first, then the most recently updated others, at most three.
    static func pages(_ pages: [Page]) -> [Page] {
        let recent = pages.sorted {
            let lhs = $0.updatedAt ?? .distantPast
            let rhs = $1.updatedAt ?? .distantPast
            return lhs == rhs ? $0.id < $1.id : lhs > rhs
        }
        guard let front = recent.first(where: \.frontPage) else { return Array(recent.prefix(3)) }
        return [front] + recent.filter { $0.id != front.id }.prefix(2)
    }

    /// - Parameters:
    ///   - score: The shared grade model's current score.
    ///   - grade: The shared grade model's current letter grade.
    /// - Returns: A compact grade label, including a useful missing-grade state.
    static func gradeSummary(score: String, grade: String) -> String {
        let number = Double(score)
        let scoreText = number?.isFinite == true ? "\(score)%" : nil
        let gradeText = grade.isEmpty || grade == "--" ? nil : grade
        let parts = [scoreText, gradeText].compactMap { $0 }
        return parts.isEmpty ? "No grade available" : parts.joined(separator: " · ")
    }

    /// - Parameter pages: Sections currently visible in the overview.
    /// - Returns: Whether the independent grade card should be shown.
    static func showsGradeCard(pages: [NavigationModel.CoursePage]) -> Bool {
        !pages.contains(.grades)
    }

    /// - Parameter blocks: Fetched modules, possibly awaiting their items.
    /// - Returns: Started, next unlocked, next incomplete, or first module in position order.
    static func currentModule(_ blocks: [ModulesViewModel.ModuleBlock]) -> ModulesViewModel.ModuleBlock? {
        let ordered = blocks.sorted {
            $0.module.position == $1.module.position ? $0.module.id < $1.module.id : $0.module.position < $1.module.position
        }
        return ordered.first { $0.module.state == .started }
            ?? ordered.first { $0.module.state != .completed && $0.module.state != .locked }
            ?? ordered.first { $0.module.state != .completed }
            ?? ordered.first
    }

    /// - Parameter block: The selected module and any loaded items.
    /// - Returns: Up to three items in position order; empty lets the view show itemsCount.
    static func moduleItems(_ block: ModulesViewModel.ModuleBlock) -> [ModuleItem] {
        let sorted = block.items.sorted {
            $0.position == $1.position ? $0.id < $1.id : $0.position < $1.position
        }
        return Array(sorted.prefix(3))
    }

    /// - Parameter files: Files from the root folder only.
    /// - Returns: Up to three newest files, using creation date when update date is absent.
    static func files(_ files: [File]) -> [File] {
        let sorted = files.sorted {
            let lhs = $0.updatedAt ?? $0.createdAt ?? .distantPast
            let rhs = $1.updatedAt ?? $1.createdAt ?? .distantPast
            return lhs == rhs ? $0.id < $1.id : lhs > rhs
        }
        return Array(sorted.prefix(3))
    }

    /// - Parameter quizzes: Fetched quizzes, including overdue and undated quizzes.
    /// - Returns: Up to three by earliest due date, undated last, with stable ID ties.
    static func quizzes(_ quizzes: [Quiz]) -> [Quiz] {
        let sorted = quizzes.sorted {
            let lhs = $0.dueAt ?? .distantFuture
            let rhs = $1.dueAt ?? .distantFuture
            return lhs == rhs ? $0.id < $1.id : lhs < rhs
        }
        return Array(sorted.prefix(3))
    }

    /// - Parameter users: People loaded by the preview's own manager.
    /// - Returns: Up to five people, teachers first, then sortable name and ID.
    static func people(_ users: [User]) -> [User] {
        let sorted = users.sorted {
            let lhs = $0.enrollmentRoles.contains(.teacher)
            let rhs = $1.enrollmentRoles.contains(.teacher)
            if lhs != rhs { return lhs }
            return $0.sortableName == $1.sortableName ? $0.id < $1.id : $0.sortableName < $1.sortableName
        }
        return Array(sorted.prefix(5))
    }

    /// - Parameter displayed: The manager's groupsDisplayed list.
    /// - Returns: Up to three groups, preserving displayed order.
    static func groups(_ displayed: [CanvasGroup]) -> [CanvasGroup] {
        Array(displayed.prefix(3))
    }
}
