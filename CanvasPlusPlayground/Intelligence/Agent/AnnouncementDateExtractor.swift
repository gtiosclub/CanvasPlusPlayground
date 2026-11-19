//
//  AnnouncementDateExtractor.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/24/26.
//

import Foundation
import FoundationModels
import NaturalLanguage

/// Pulls the dates an announcement gives out of its text.
///
/// Tier 1 asks the on-device model for {item, date, quote}. Its answer is only trusted where the
/// quote really appears in the announcement and the date parses. With no model (or if the call
/// fails) `DataDetectorDateExtractor` does it in plain Swift.
@available(iOS 26.0, macOS 26.0, *)
struct AnnouncementDateExtractor: Sendable {
    let provider: any AgentModelProvider
    var timeZone: TimeZone = .current
    /// Bodies are cut to this many characters so a call fits the on-device context window.
    var maxBodyLength = 2_400

    func claims(in announcement: AnnouncementText) async -> [BriefingDateClaim] {
        let fallback = DataDetectorDateExtractor(timeZone: timeZone)

        guard provider.tier != .none, provider.isAvailable else {
            return fallback.claims(in: announcement)
        }

        do {
            return try await modelClaims(in: announcement)
        } catch {
            LoggerService.main.error("[Briefing] Model extraction failed, using the data detector: \(error)")
            return fallback.claims(in: announcement)
        }
    }

    private func modelClaims(in announcement: AnnouncementText) async throws -> [BriefingDateClaim] {
        let posted = announcement.postedAt.map { Self.localISO($0, timeZone: timeZone) } ?? "unknown"
        let prompt = AgentPrompt(
            instructions: """
            You read course announcements and list every date they give for an assignment, quiz, exam, \
            project or event. Only include dates the text actually states. Resolve words like "Friday" \
            or "tomorrow" against the posted date. Times are in \(timeZone.identifier) \
            (UTC offset \(Self.offset(timeZone))).
            """,
            text: """
            Posted: \(posted)
            Title: \(announcement.evidence.title)

            \(announcement.body.prefix(maxBodyLength))
            """,
            temperature: 0
        )

        let response = try await provider.respond(to: prompt, tools: [], generating: ExtractedDateClaims.self)

        return response.content.claims.compactMap { claim in
            // Deterministic check on the model: the quote must be in the text and the date must parse.
            guard Self.normalized(announcement.body).contains(Self.normalized(claim.quote)),
                  !claim.quote.trimmingCharacters(in: .whitespaces).isEmpty,
                  let (date, hasTime) = Self.parseModelDate(claim.date, timeZone: timeZone) else {
                return nil
            }

            return BriefingDateClaim(
                source: announcement.evidence,
                itemMentioned: claim.item,
                date: date,
                hasTime: hasTime,
                quote: claim.quote,
                extractedBy: "\(response.tier)"
            )
        }
    }

    // MARK: Helpers

    /// `2026-10-30T23:59:00-04:00` (has a time) or `2026-10-30` (day only, stored as local midnight).
    static func parseModelDate(_ text: String, timeZone: TimeZone) -> (Date, Bool)? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)

        let withTime = ISO8601DateFormatter()
        withTime.formatOptions = [.withInternetDateTime]
        if let date = withTime.date(from: trimmed) {
            return (date, true)
        }

        let dayOnly = ISO8601DateFormatter()
        dayOnly.formatOptions = [.withFullDate]
        dayOnly.timeZone = timeZone
        if let date = dayOnly.date(from: trimmed) {
            return (date, false)
        }

        return nil
    }

    static func localISO(_ date: Date, timeZone: TimeZone) -> String {
        date.formatted(Date.ISO8601FormatStyle(timeZoneSeparator: .colon, timeZone: timeZone))
    }

    static func offset(_ timeZone: TimeZone) -> String {
        let seconds = timeZone.secondsFromGMT()
        let sign = seconds < 0 ? "-" : "+"
        return String(format: "%@%02d:%02d", sign, abs(seconds) / 3600, abs(seconds) % 3600 / 60)
    }

    /// Lowercased with whitespace and curly quotes flattened, for the quote check.
    static func normalized(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Tier 0 date extraction with `NSDataDetector`, sentence by sentence.
///
/// The detector resolves "Friday" or "tomorrow" against today, so those are re-resolved against
/// the announcement's posted date. The item is the whole sentence; the reconciler matches it
/// against record titles.
struct DataDetectorDateExtractor: Sendable {
    var timeZone: TimeZone = .current

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    func claims(in announcement: AnnouncementText) -> [BriefingDateClaim] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return []
        }

        var claims: [BriefingDateClaim] = []

        for sentence in Self.sentences(in: announcement.body) {
            let range = NSRange(sentence.startIndex..., in: sentence)

            for match in detector.matches(in: sentence, range: range) {
                guard let start = match.date,
                      let matchRange = Range(match.range, in: sentence) else {
                    continue
                }

                let matchedText = String(sentence[matchRange])
                // "due Friday at 11:59 PM" comes back as a range from now until Friday 11:59 PM,
                // so for deadline phrasing the date that matters is the end of the range.
                let detected = Self.isDeadline(matchedText) && match.duration > 0
                    ? start.addingTimeInterval(match.duration)
                    : start
                // "next week" or "this month" don't name a day, so there's nothing exact to compare.
                guard Self.namesDay(matchedText, calendar: calendar) else { continue }

                let hasTime = Self.mentionsTime(matchedText)
                let date = resolve(
                    detected,
                    matchedText: matchedText,
                    hasTime: hasTime,
                    postedAt: announcement.postedAt
                )

                claims.append(
                    BriefingDateClaim(
                        source: announcement.evidence,
                        itemMentioned: sentence,
                        date: date,
                        hasTime: hasTime,
                        quote: sentence,
                        extractedBy: "none"
                    )
                )
            }
        }

        return claims
    }

    /// Relative words ("Friday", "tomorrow") are moved to be relative to `postedAt`; explicit
    /// dates are kept. Day-only dates become local midnight.
    private func resolve(_ detected: Date, matchedText: String, hasTime: Bool, postedAt: Date?) -> Date {
        var date = detected

        if let postedAt, let relativeDay = relativeDay(in: matchedText, postedAt: postedAt) {
            let time = calendar.dateComponents([.hour, .minute], from: detected)
            date = calendar.date(
                bySettingHour: hasTime ? time.hour ?? 0 : 0,
                minute: hasTime ? time.minute ?? 0 : 0,
                second: 0,
                of: relativeDay
            ) ?? relativeDay
        }

        return hasTime ? date : calendar.startOfDay(for: date)
    }

    private func relativeDay(in text: String, postedAt: Date) -> Date? {
        let lowered = text.lowercased()
        // An explicit date ("Oct 30", "10/30") isn't relative.
        let hasDigitsOutsideTime = Self.strippingTimes(lowered).contains { $0.isNumber }
        guard !hasDigitsOutsideTime else { return nil }

        let postedDay = calendar.startOfDay(for: postedAt)

        if lowered.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: postedDay)
        }
        if lowered.contains("today") || lowered.contains("tonight") {
            return postedDay
        }

        let weekdays = calendar.weekdaySymbols.map { $0.lowercased() }
        guard let index = weekdays.firstIndex(where: { lowered.contains($0) }) else { return nil }

        let target = index + 1 // Calendar weekdays are 1-based, Sunday = 1.
        let postedWeekday = calendar.component(.weekday, from: postedDay)
        var days = (target - postedWeekday + 7) % 7
        if lowered.contains("next") && days == 0 { days = 7 }

        return calendar.date(byAdding: .day, value: days, to: postedDay)
    }

    static func isDeadline(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return ["due", "by ", "until", "till", "before"].contains { lowered.hasPrefix($0) }
    }

    /// Has a date number, a weekday, or today/tomorrow/tonight.
    static func namesDay(_ text: String, calendar: Calendar) -> Bool {
        let lowered = text.lowercased()

        return strippingTimes(lowered).contains { $0.isNumber }
            || ["today", "tonight", "tomorrow"].contains { lowered.contains($0) }
            || calendar.weekdaySymbols.contains { lowered.contains($0.lowercased()) }
    }

    /// `text` with times of day ("11:59", "3 pm") removed, so the digits left belong to a date.
    static func strippingTimes(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\d{1,2}(:\\d{2})?\\s*(am|pm|a\\.m\\.|p\\.m\\.)", with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "\\d{1,2}:\\d{2}", with: "", options: .regularExpression)
    }

    static func mentionsTime(_ text: String) -> Bool {
        text.range(of: "\\d{1,2}:\\d{2}|\\d\\s*(am|pm|a\\.m\\.|p\\.m\\.)|\\bnoon\\b|\\bmidnight\\b", options: [.regularExpression, .caseInsensitive]) != nil
    }

    static func sentences(in text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        return tokenizer.tokens(for: text.startIndex..<text.endIndex)
            .map { text[$0].trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
