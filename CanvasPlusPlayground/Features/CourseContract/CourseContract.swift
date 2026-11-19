//
//  CourseContract.swift
//  CanvasPlusPlayground
//

import Foundation
import FoundationModels

/// The course's rules as the syllabus states them, each with the excerpt it came from and
/// whether the app could confirm it against Canvas.
struct CourseContract: Codable, Hashable, Sendable {
    var courseID: String
    var syllabusHash: String
    var extractedAt: Date
    var usedModel: Bool

    var weights: [Field<GradeWeight>]
    var examDates: [Field<ExamDateCandidate>]
    var latePolicy: Field<String>?
    var dropRules: [Field<DropRule>]
    var attendance: Field<String>?
    var officeHours: [Field<String>]
    /// Problems with the contract as a whole, such as weights that don't add up to 100.
    var notes: [Note] = []

    struct Field<Value: Codable & Hashable & Sendable>: Codable, Hashable, Sendable {
        var value: Value
        /// The syllabus text this came from.
        var excerpt: String
        var status: Status
        /// Why it has that status, e.g. "Canvas has Homework at 25%".
        var detail: String?

        init(_ value: Value, excerpt: String, status: Status = .unverified, detail: String? = nil) {
            self.value = value
            self.excerpt = excerpt
            self.status = status
            self.detail = detail
        }
    }

    enum Status: String, Codable, Hashable, Sendable {
        /// Matches what Canvas says.
        case confirmed
        /// Canvas has nothing to compare it with.
        case unverified
        /// Canvas doesn't have it (e.g. an exam not on the calendar).
        case notFound
        /// Canvas says something different.
        case conflict
    }

    struct GradeWeight: Codable, Hashable, Sendable {
        var name: String
        var percent: Double
        /// The Canvas assignment group it matched, if any.
        var groupID: String?
    }

    struct DropRule: Codable, Hashable, Sendable {
        var group: String
        var dropLowest: Int
    }

    struct Note: Codable, Hashable, Sendable {
        var text: String
        var status: Status
    }

    /// Every field's status, for a summary badge.
    var statusCounts: [Status: Int] {
        var counts: [Status: Int] = [:]
        let statuses = weights.map(\.status) + examDates.map(\.status) + dropRules.map(\.status)
            + officeHours.map(\.status) + [latePolicy?.status, attendance?.status].compactMap { $0 }
        for status in statuses { counts[status, default: 0] += 1 }
        return counts
    }
}

// MARK: - Extraction

/// Pulls the contract's fields out of syllabus text. Exam dates reuse `ExamDateExtractor` (#521).
/// The model fills the policy fields when it's available; otherwise patterns do (Tier 0).
/// Every model field needs a quote that's really in the syllabus.
enum CourseContractExtractor {
    @available(iOS 26.0, macOS 26.0, *)
    @Generable
    struct ModelOutput {
        @Guide(description: "Each grade category and its percentage of the final grade, e.g. Homework 20.")
        var weights: [ModelWeight]
        @Guide(description: "The late work policy in one sentence, or empty if the syllabus has none.")
        var latePolicy: ModelText?
        @Guide(description: "Rules that drop the lowest scores in a category.")
        var dropRules: [ModelDrop]
        @Guide(description: "The attendance policy in one sentence, or empty if none.")
        var attendance: ModelText?
        @Guide(description: "Office hours: who, when and where.")
        var officeHours: [ModelText]
    }

    @available(iOS 26.0, macOS 26.0, *)
    @Generable
    struct ModelWeight {
        var name: String
        @Guide(description: "Percent of the final grade, 0 to 100.", .range(0...100))
        var percent: Double
        @Guide(description: "The exact sentence or line that gives this weight.")
        var quote: String
    }

    @available(iOS 26.0, macOS 26.0, *)
    @Generable
    struct ModelDrop {
        var group: String
        @Guide(description: "How many of the lowest scores are dropped.", .range(1...20))
        var dropLowest: Int
        var quote: String
    }

    @available(iOS 26.0, macOS 26.0, *)
    @Generable
    struct ModelText {
        @Guide(description: "A short plain summary.")
        var summary: String
        @Guide(description: "The exact sentence from the syllabus.")
        var quote: String
    }

    struct Extracted: Sendable {
        var weights: [CourseContract.Field<CourseContract.GradeWeight>] = []
        var latePolicy: CourseContract.Field<String>?
        var dropRules: [CourseContract.Field<CourseContract.DropRule>] = []
        var attendance: CourseContract.Field<String>?
        var officeHours: [CourseContract.Field<String>] = []
    }

    @available(iOS 26.0, macOS 26.0, *)
    static func modelFields(in text: String, provider: any AgentModelProvider) async throws -> Extracted {
        let prompt = AgentPrompt(
            instructions: "You read course syllabi and pull out the grading and course policies. Only report what the text says. Copy each quote exactly.",
            text: "Syllabus:\n\(text)",
            temperature: 0
        )
        let output = try await provider.respond(to: prompt, tools: [], generating: ModelOutput.self).content
        let quoted = { (quote: String) in ExamDateExtractor.contains(text, quote: quote) }

        var extracted = Extracted()
        extracted.weights = output.weights.filter { quoted($0.quote) }.map {
            .init(.init(name: $0.name.trimmingCharacters(in: .whitespaces), percent: $0.percent), excerpt: $0.quote)
        }
        extracted.dropRules = output.dropRules.filter { quoted($0.quote) }.map {
            .init(.init(group: $0.group, dropLowest: $0.dropLowest), excerpt: $0.quote)
        }
        extracted.latePolicy = output.latePolicy.flatMap { quoted($0.quote) ? .init($0.summary, excerpt: $0.quote) : nil }
        extracted.attendance = output.attendance.flatMap { quoted($0.quote) ? .init($0.summary, excerpt: $0.quote) : nil }
        extracted.officeHours = output.officeHours.filter { quoted($0.quote) }.map { .init($0.summary, excerpt: $0.quote) }
        return extracted
    }

    /// Pattern-based fields for devices without a model. Finds weight lines ("Homework 20%"),
    /// drop rules ("lowest two quizzes are dropped") and the sentences about late work,
    /// attendance and office hours.
    static func patternFields(in text: String) -> Extracted {
        var extracted = Extracted()
        let lines = text.components(separatedBy: .newlines)

        // Weight lines are read whole: a sentence splitter breaks "Midterms ..... 40%" at the dots.
        for line in lines {
            if let weight = weight(in: line) {
                extracted.weights.append(.init(weight, excerpt: line))
            }
            if let drop = dropRule(in: line) {
                extracted.dropRules.append(.init(drop, excerpt: line))
            }
        }

        for line in lines.flatMap(sentences) {
            let lowered = line.lowercased()

            if extracted.latePolicy == nil, lowered.contains("late"), lowered.contains("submi") || lowered.contains("penalt") || lowered.contains("accepted") {
                extracted.latePolicy = .init(line, excerpt: line)
            }
            if extracted.attendance == nil, lowered.contains("attendance") {
                extracted.attendance = .init(line, excerpt: line)
            }
            if lowered.contains("office hour") {
                extracted.officeHours.append(.init(line, excerpt: line))
            }
        }
        return extracted
    }

    /// "Homework: 20%", "Exams (2 x 25%) 50%", "Final Exam ..... 30 %" → name and percent.
    static func weight(in line: String) -> CourseContract.GradeWeight? {
        let pattern = #"^\s*[-•*]?\s*([A-Za-z][A-Za-z &/'’-]{1,40}?)\s*(?:\([^)]*\))?\s*[:.\-–—]*\s*(\d{1,3}(?:\.\d+)?)\s*%"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let nameRange = Range(match.range(at: 1), in: line),
              let percentRange = Range(match.range(at: 2), in: line),
              let percent = Double(line[percentRange]), percent > 0, percent <= 100 else {
            return nil
        }
        let name = line[nameRange].trimmingCharacters(in: .whitespaces)
        // "Late work loses 10%" is a penalty, not a grade category.
        let lowered = name.lowercased()
        guard !["late", "loses", "penalty", "deduct", "per day", "up to"].contains(where: lowered.contains) else { return nil }
        return .init(name: name, percent: percent)
    }

    /// "The lowest two quiz grades will be dropped" → group "quiz", 2.
    static func dropRule(in line: String) -> CourseContract.DropRule? {
        let lowered = line.lowercased()
        guard lowered.contains("drop"), lowered.contains("lowest") else { return nil }

        let numbers = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "single": 1]
        let count = lowered.split { !$0.isLetter && !$0.isNumber }
            .compactMap { Int($0) ?? numbers[String($0)] }
            .first { $0 > 0 && $0 <= 20 } ?? 1

        let groups = ["homework", "quiz", "lab", "exam", "test", "assignment", "participation", "reading", "project"]
        guard let group = groups.first(where: lowered.contains) else { return nil }
        return .init(group: group, dropLowest: count)
    }

    private static func sentences(_ text: String) -> [String] {
        var result: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { sentence, _, _, _ in
            let trimmed = (sentence ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { result.append(trimmed) }
        }
        return result
    }

    /// Plain text of the whole syllabus (the exam extractor's filter is too narrow for policies).
    static func plainText(fromHTML html: String, maxCharacters: Int = 9_000) -> String {
        let text = html
            .replacingOccurrences(of: "<(br|p|div|li|tr|h[1-6])[^>]*>", with: "\n", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "<t[dh][^>]*>", with: " ", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        return String(text.prefix(maxCharacters))
    }
}

// MARK: - Verification

/// Checks the contract against Canvas in Swift: weights add up to 100, each named category
/// matches an assignment group with the same weight, drop rules match the group's rules, and
/// exam dates are on the course calendar.
enum CourseContractVerifier {
    struct CanvasGroup: Sendable {
        let id: String
        let name: String
        let weight: Double?
        let dropLowest: Int?
    }

    static let tolerance = 0.5

    static func verify(
        _ contract: CourseContract,
        groups: [CanvasGroup],
        calendarEvents: [(title: String, date: Date)],
        calendar: Calendar = .current
    ) -> CourseContract {
        var contract = contract
        contract.notes = []

        // Weights add up.
        if !contract.weights.isEmpty {
            let total = contract.weights.map(\.value.percent).reduce(0, +)
            if abs(total - 100) <= tolerance {
                contract.notes.append(.init(text: "Weights add up to 100%.", status: .confirmed))
            } else {
                contract.notes.append(.init(text: "Weights add up to \(format(total))%, not 100%.", status: .conflict))
            }
        }

        // Each weight against the matching group.
        let weighted = groups.contains { ($0.weight ?? 0) > 0 }
        for index in contract.weights.indices {
            let weight = contract.weights[index].value
            guard let group = bestMatch(for: weight.name, in: groups) else {
                contract.weights[index].status = .notFound
                contract.weights[index].detail = "No Canvas assignment group named like “\(weight.name)”."
                continue
            }
            contract.weights[index].value.groupID = group.id

            guard weighted, let canvasWeight = group.weight else {
                contract.weights[index].status = .unverified
                contract.weights[index].detail = "Canvas has “\(group.name)” but doesn't weight its groups."
                continue
            }
            if abs(canvasWeight - weight.percent) <= tolerance {
                contract.weights[index].status = .confirmed
                contract.weights[index].detail = "Matches “\(group.name)” on Canvas."
            } else {
                contract.weights[index].status = .conflict
                contract.weights[index].detail = "Canvas has “\(group.name)” at \(format(canvasWeight))%."
            }
        }

        // Drop rules against group rules.
        for index in contract.dropRules.indices {
            let rule = contract.dropRules[index].value
            guard let group = bestMatch(for: rule.group, in: groups) else {
                contract.dropRules[index].status = .unverified
                continue
            }
            switch group.dropLowest {
            case rule.dropLowest?:
                contract.dropRules[index].status = .confirmed
                contract.dropRules[index].detail = "Canvas drops the lowest \(rule.dropLowest) in “\(group.name)”."
            case let other?:
                contract.dropRules[index].status = .conflict
                contract.dropRules[index].detail = "Canvas drops the lowest \(other) in “\(group.name)”."
            case nil:
                contract.dropRules[index].status = .notFound
                contract.dropRules[index].detail = "Canvas doesn't drop any scores in “\(group.name)” yet."
            }
        }

        // Exam dates on the calendar.
        for index in contract.examDates.indices {
            let exam = contract.examDates[index].value
            let onCalendar = calendarEvents.contains { calendar.isDate($0.date, inSameDayAs: exam.date) && sharesWord($0.title, exam.title) }
            contract.examDates[index].status = onCalendar ? .confirmed : .notFound
            contract.examDates[index].detail = onCalendar ? "On the course calendar." : "Not on the course calendar. You can add it from Exam Dates."
        }

        return contract
    }

    /// The group whose name shares the most words with `name` (singular/plural folded), if any.
    /// Ties go to the group whose first word matches, so "Final Exam" picks "Final" over "Exams".
    static func bestMatch(for name: String, in groups: [CanvasGroup]) -> CanvasGroup? {
        let target = words(name)
        guard !target.isEmpty else { return nil }
        let firstWord = orderedWords(name).first

        return groups
            .map { group -> (CanvasGroup, Int) in
                let shared = words(group.name).intersection(target).count
                let sameStart = firstWord != nil && orderedWords(group.name).first == firstWord
                return (group, shared * 2 + (sameStart ? 1 : 0))
            }
            .filter { $0.1 >= 2 }
            .max { $0.1 < $1.1 }?
            .0
    }

    private static func orderedWords(_ text: String) -> [String] {
        text.lowercased().split { !$0.isLetter }.map(String.init).map(singular)
    }

    private static func singular(_ word: String) -> String {
        var word = word
        if word.hasSuffix("zes") { word.removeLast(3) }       // quizzes → quiz
        else if word.hasSuffix("s") && word.count > 3 { word.removeLast() }
        return word
    }

    private static func words(_ text: String) -> Set<String> {
        let ignored: Set<String> = ["and", "the", "of", "grade", "grades", "total", "s"]
        return Set(orderedWords(text).filter { !ignored.contains($0) })
    }

    private static func sharesWord(_ a: String, _ b: String) -> Bool {
        !words(a).isDisjoint(with: words(b))
    }

    private static func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
