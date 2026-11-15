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
}
