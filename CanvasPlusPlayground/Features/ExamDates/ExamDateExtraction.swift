//
//  ExamDateExtraction.swift
//  CanvasPlusPlayground
//

import Foundation
import FoundationModels

/// An exam, quiz or milestone date found in a syllabus, waiting for the student to review it.
struct ExamDateCandidate: Identifiable, Codable, Hashable, Sendable {
    enum Kind: String, Codable, Hashable, Sendable, CaseIterable {
        case midterm
        case final
        case quiz
        case project
        case other

        var label: String {
            switch self {
            case .midterm: "Midterm"
            case .final: "Final"
            case .quiz: "Quiz"
            case .project: "Project"
            case .other: "Other"
            }
        }

        var systemImage: String {
            switch self {
            case .midterm, .final: "pencil.and.list.clipboard"
            case .quiz: "questionmark.circle"
            case .project: "hammer"
            case .other: "calendar"
            }
        }

        /// From words in a title, for the no-model path.
        static func infer(from text: String) -> Kind {
            let lowered = text.lowercased()
            if lowered.contains("final") { return .final }
            if lowered.contains("midterm") || lowered.contains("exam") || lowered.contains("test") { return .midterm }
            if lowered.contains("quiz") { return .quiz }
            if lowered.contains("project") || lowered.contains("milestone") || lowered.contains("presentation") { return .project }
            return .other
        }
    }

    var id = UUID()
    var title: String
    var kind: Kind
    /// Start of the day, or the start time when the syllabus gives one.
    var date: Date
    var hasTime: Bool
    var location: String?
    /// The sentence it came from, shown so the student can check it.
    var sourceSnippet: String
}

/// Finds exam dates in syllabus text. The model (Tier 1) reads the text when it's available;
/// otherwise `NSDataDetector` does (Tier 0). Either way Swift picks the year from the course
/// term, keeps a date only if its quote is really in the syllabus, and drops ones the course
/// calendar already has.
enum ExamDateExtractor {
    static let examWords = ["exam", "midterm", "final", "quiz", "test", "project", "milestone", "presentation"]

    // MARK: Model

    @available(iOS 26.0, macOS 26.0, *)
    @Generable
    struct ModelOutput {
        @Guide(description: "Every exam, quiz, test, project deadline or presentation with a specific date. Skip weekly homework.")
        var events: [ModelEvent]
    }

    @available(iOS 26.0, macOS 26.0, *)
    @Generable
    struct ModelEvent {
        @Guide(description: "Short name, e.g. Midterm 1 or Final Exam.")
        var title: String
        @Guide(description: "midterm, final, quiz, project or other.", .anyOf(["midterm", "final", "quiz", "project", "other"]))
        var kind: String
        @Guide(description: "Month number, 1 to 12.", .range(1...12))
        var month: Int
        @Guide(description: "Day of the month, 1 to 31.", .range(1...31))
        var day: Int
        @Guide(description: "Start time as 24-hour HH:mm if the text gives one, otherwise empty.")
        var startTime: String?
        @Guide(description: "Room or building if given, otherwise empty.")
        var location: String?
        @Guide(description: "The exact sentence from the syllabus that gives this date, copied word for word.")
        var quote: String
    }

    @available(iOS 26.0, macOS 26.0, *)
    static func modelCandidates(
        in text: String,
        term: DateInterval?,
        provider: any AgentModelProvider,
        calendar: Calendar = .current
    ) async throws -> [ExamDateCandidate] {
        let prompt = AgentPrompt(
            instructions: "You read course syllabi and list the dates of exams, quizzes and project deadlines. Only list dates that are written in the text. Copy each quote exactly.",
            text: "Syllabus:\n\(text)",
            temperature: 0
        )
        let response = try await provider.respond(to: prompt, tools: [], generating: ModelOutput.self)

        return response.content.events.compactMap { event in
            guard Self.contains(text, quote: event.quote),
                  let day = resolve(month: event.month, day: event.day, within: term, calendar: calendar) else {
                return nil
            }
            let time = event.startTime.flatMap(parseTime)
            let date = time.flatMap { calendar.date(bySettingHour: $0.hour, minute: $0.minute, second: 0, of: day) } ?? day
            let location = event.location?.trimmingCharacters(in: .whitespacesAndNewlines)

            return ExamDateCandidate(
                title: event.title.trimmingCharacters(in: .whitespacesAndNewlines),
                kind: ExamDateCandidate.Kind(rawValue: event.kind) ?? .infer(from: event.title),
                date: date,
                hasTime: time != nil,
                location: location?.isEmpty == false ? location : nil,
                sourceSnippet: event.quote.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }

    // MARK: No model

    /// Sentences that mention an exam word, with the dates `NSDataDetector` finds in them.
    static func detectorCandidates(in text: String, term: DateInterval?, calendar: Calendar = .current) -> [ExamDateCandidate] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return [] }
        var results: [ExamDateCandidate] = []

        for sentence in sentences(in: text) {
            let lowered = sentence.lowercased()
            guard examWords.contains(where: lowered.contains) else { continue }

            let range = NSRange(sentence.startIndex..., in: sentence)
            for match in detector.matches(in: sentence, range: range) {
                guard let detected = match.date, let matched = Range(match.range, in: sentence) else { continue }

                // Re-resolve the year: the detector assumes the current year, the course may not.
                let parts = calendar.dateComponents([.month, .day, .hour, .minute], from: detected)
                guard let month = parts.month, let dayOfMonth = parts.day,
                      let day = resolve(month: month, day: dayOfMonth, within: term, calendar: calendar) else { continue }

                let matchedText = String(sentence[matched])
                let hasTime = matchedText.range(of: #"\d{1,2}(:\d{2})?\s*([ap]\.?m\.?)|\d{1,2}:\d{2}"#, options: [.regularExpression, .caseInsensitive]) != nil
                let date = hasTime
                    ? calendar.date(bySettingHour: parts.hour ?? 0, minute: parts.minute ?? 0, second: 0, of: day) ?? day
                    : day

                results.append(ExamDateCandidate(
                    title: title(from: sentence, removing: matchedText),
                    kind: .infer(from: sentence),
                    date: date,
                    hasTime: hasTime,
                    location: nil,
                    sourceSnippet: sentence
                ))
            }
        }

        return results
    }

    // MARK: Shared checks

    /// The date `month`/`day` falls on within the course term (a couple of weeks of slack either
    /// side, for finals week). Without a term, the next such date within a year of now.
    static func resolve(month: Int, day: Int, within term: DateInterval?, now: Date = .now, calendar: Calendar = .current) -> Date? {
        let anchorYear = calendar.component(.year, from: term?.start ?? now)
        let candidates = (anchorYear - 1...anchorYear + 1).compactMap { year -> Date? in
            let components = DateComponents(year: year, month: month, day: day)
            guard components.isValidDate(in: calendar) else { return nil }
            return calendar.date(from: components)
        }

        if let term {
            let slack: TimeInterval = 21 * 86_400
            let window = DateInterval(start: term.start.addingTimeInterval(-slack), end: term.end.addingTimeInterval(slack))
            return candidates.first(where: window.contains)
        }

        let startOfToday = calendar.startOfDay(for: now)
        return candidates.filter { $0 >= startOfToday.addingTimeInterval(-30 * 86_400) }.min()
    }

    /// Drops candidates already on the course calendar (same day, a shared title word), and
    /// repeats of the same title on the same day.
    static func removingDuplicates(
        _ candidates: [ExamDateCandidate],
        existing: [(title: String, date: Date)],
        calendar: Calendar = .current
    ) -> [ExamDateCandidate] {
        var kept: [ExamDateCandidate] = []

        for candidate in candidates.sorted(by: { $0.date < $1.date }) {
            let words = significantWords(candidate.title)
            let isKnown = existing.contains { event in
                calendar.isDate(event.date, inSameDayAs: candidate.date)
                    && (words.isEmpty || !significantWords(event.title).isDisjoint(with: words))
            }
            let isRepeat = kept.contains {
                calendar.isDate($0.date, inSameDayAs: candidate.date) && significantWords($0.title) == words
            }
            if !isKnown && !isRepeat { kept.append(candidate) }
        }

        return kept
    }

    /// Whether `quote` appears in `text`, ignoring case, spacing and punctuation differences.
    static func contains(_ text: String, quote: String) -> Bool {
        let needle = normalized(quote)
        return needle.count >= 8 && normalized(text).contains(needle)
    }

    /// Plain text from syllabus HTML, cut to the parts that mention exam words or dates so it fits
    /// the on-device context window.
    static func relevantText(fromHTML html: String, maxCharacters: Int = 6_000) -> String {
        let plain = html
            .replacingOccurrences(of: "<(br|p|div|li|tr|h[1-6])[^>]*>", with: "\n", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)

        let paragraphs = plain.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let relevant = paragraphs.filter { paragraph in
            let lowered = paragraph.lowercased()
            return examWords.contains(where: lowered.contains)
        }

        var text = ""
        for paragraph in relevant where text.count + paragraph.count + 1 <= maxCharacters {
            text += paragraph + "\n"
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Helpers

    private static func normalized(_ text: String) -> String {
        text.lowercased().unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init)
            .joined()
    }

    private static func sentences(in text: String) -> [String] {
        var sentences: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { substring, _, _, _ in
            for line in (substring ?? "").components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { sentences.append(trimmed) }
            }
        }
        return sentences
    }

    /// "Midterm 1 is on October 14 in Klaus 1443." → "Midterm 1"
    private static func title(from sentence: String, removing dateText: String) -> String {
        let pattern = #"(?i)\b(midterm|final|exam|quiz|test|project|milestone|presentation)\b(\s+(exam|\d+|[ivx]+|[a-z]))?"#
        if let range = sentence.range(of: pattern, options: .regularExpression) {
            return String(sentence[range]).capitalized
        }
        let stripped = sentence.replacingOccurrences(of: dateText, with: "").trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        return String(stripped.prefix(40))
    }

    private static func significantWords(_ title: String) -> Set<String> {
        let ignored: Set<String> = ["the", "and", "on", "in", "exam", "due", "day"]
        return Set(title.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { !ignored.contains($0) })
    }

    private static func parseTime(_ text: String) -> (hour: Int, minute: Int)? {
        let parts = text.split(separator: ":").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 2, (0...23).contains(parts[0]), (0...59).contains(parts[1]) else { return nil }
        return (parts[0], parts[1])
    }
}
