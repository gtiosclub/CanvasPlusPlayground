//
//  CrunchPlanner.swift
//  CanvasPlusPlayground
//

import Foundation
import FoundationModels

/// One line of the week plan.
struct CrunchSuggestion: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        /// Start this item on a lighter day ahead of the crunch. Can become a reminder.
        case startEarly(on: Date)
        /// Work on it after the crunch; it isn't due until later.
        case canSlip(after: Date)
        /// Nothing to move, but heads up.
        case warning
    }

    let id: String
    let item: WorkloadItem
    let kind: Kind
    let reason: String

    init(item: WorkloadItem, kind: Kind, reason: String) {
        self.item = item
        self.kind = kind
        self.reason = reason
        self.id = "\(item.id)|\(kind)"
    }
}

struct CrunchPlan: Sendable {
    enum Source: Sendable {
        /// Worked out in Swift, no model.
        case baseline
        /// Proposed by the model, checked against the curve.
        case model
    }

    var suggestions: [CrunchSuggestion]
    var source: Source

    /// The reminders the student can approve: one per "start early" suggestion, at
    /// `reminderHour` on the suggested day.
    func proposedActions(reminderHour: Int = 9, now: Date = .now, calendar: Calendar = .current) -> [ProposedAction] {
        suggestions.compactMap { suggestion in
            guard case .startEarly(let day) = suggestion.kind,
                  let evidence = suggestion.item.evidence,
                  var date = calendar.date(bySettingHour: reminderHour, minute: 0, second: 0, of: day) else {
                return nil
            }
            // Today, but 9 AM already passed: an hour from now instead.
            if date <= now, calendar.isDate(day, inSameDayAs: now) {
                date = now.addingTimeInterval(3_600)
            }
            guard date > now else { return nil }
            return ProposedAction(kind: .reminder(at: date), target: evidence)
        }
    }
}

/// Turns the computed workload curve into a plan. Swift finds the peaks; the model (when there
/// is one) only proposes what to move, and anything it proposes that doesn't fit the curve is
/// dropped. Without a model the baseline plan is used as is.
enum CrunchPlanner {
    /// At most this many "start early" suggestions per crunch day, biggest first.
    static let maxPerCrunchDay = 3

    // MARK: Baseline (Tier 0)

    static func baseline(for curve: WorkloadCurve, today: Date = .now, calendar: Calendar = .current) -> CrunchPlan {
        var suggestions: [CrunchSuggestion] = []
        var planned = Set<String>()
        let todayIndex = curve.index(of: today, calendar: calendar) ?? 0

        for crunch in curve.crunchDays {
            guard let crunchIndex = curve.index(of: crunch.date, calendar: calendar) else { continue }
            var startedEarly = 0

            for contribution in crunch.contributions where !planned.contains(contribution.item.id) {
                let item = contribution.item
                guard let dueIndex = curve.index(of: item.date, calendar: calendar) else { continue }

                if dueIndex > crunchIndex + 1 {
                    // Due well after the crunch: its share of the work can wait.
                    planned.insert(item.id)
                    suggestions.append(CrunchSuggestion(
                        item: item,
                        kind: .canSlip(after: crunch.date),
                        reason: "Due \(day(item.date)), after the busy stretch on \(day(crunch.date))."
                    ))
                    continue
                }

                guard startedEarly < maxPerCrunchDay, item.kind != .event else { continue }

                // A lighter, non-crunch day before the crunch, within a few days of the usual lead-up.
                let earliest = max(todayIndex, crunchIndex - item.leadDays - 3)
                let candidates = curve.days[earliest..<crunchIndex].filter { !$0.isCrunch }
                if let lighter = candidates.min(by: { $0.load != $1.load ? $0.load < $1.load : $0.date < $1.date }) {
                    planned.insert(item.id)
                    startedEarly += 1
                    suggestions.append(CrunchSuggestion(
                        item: item,
                        kind: .startEarly(on: lighter.date),
                        reason: "\(day(crunch.date)) is a crunch day. \(day(lighter.date)) is lighter."
                    ))
                }
            }

            if startedEarly == 0, let biggest = crunch.dueItems.first, !planned.contains(biggest.id) {
                planned.insert(biggest.id)
                suggestions.append(CrunchSuggestion(
                    item: biggest,
                    kind: .warning,
                    reason: "\(crunch.dueItems.count) due \(day(crunch.date)), with no lighter day before it."
                ))
            }
        }

        return CrunchPlan(suggestions: suggestions, source: .baseline)
    }

    // MARK: Model (Tier 1)

    @available(iOS 26.0, macOS 26.0, *)
    @Generable
    struct ModelPlan {
        @Guide(description: "Suggestions for the student's busiest days. Only use ids from the list.")
        var items: [ModelSuggestion]
    }

    @available(iOS 26.0, macOS 26.0, *)
    @Generable
    struct ModelSuggestion {
        @Guide(description: "The id of the item, exactly as given, e.g. assignment:123.")
        var id: String
        @Guide(description: "startEarly, canSlip or warning.", .anyOf(["startEarly", "canSlip", "warning"]))
        var kind: String
        @Guide(description: "For startEarly: the day to start, as YYYY-MM-DD. Must be before the item is due. Otherwise empty.")
        var startDay: String?
        @Guide(description: "One short sentence the student will read.")
        var reason: String
    }

    /// Asks the model for a plan. Returns nil when there's no model, it fails, or nothing it
    /// proposed survives the checks, so the caller can fall back to `baseline`.
    @available(iOS 26.0, macOS 26.0, *)
    @MainActor
    static func modelPlan(
        for curve: WorkloadCurve,
        provider: any AgentModelProvider,
        today: Date = .now,
        calendar: Calendar = .current
    ) async -> CrunchPlan? {
        guard provider.tier != .none, provider.isAvailable, !curve.crunchDays.isEmpty else { return nil }

        let prompt = AgentPrompt(
            instructions: """
            You help a student plan a busy few weeks. The workload numbers are already computed; don't change them.
            For items due on or just after a crunch day, suggest starting early on a lighter day (startEarly).
            For work that isn't due until well after a crunch, say it can slip (canSlip).
            Use warning only when nothing can move. Use only the ids listed. Be brief and kind.
            """,
            text: promptText(for: curve, today: today, calendar: calendar),
            temperature: 0.2
        )

        do {
            let response = try await provider.respond(to: prompt, tools: [], generating: ModelPlan.self)
            let suggestions = validated(response.content.items, curve: curve, today: today, calendar: calendar)
            return suggestions.isEmpty ? nil : CrunchPlan(suggestions: suggestions, source: .model)
        } catch {
            LoggerService.main.debug("[Crunch] Model plan failed, using baseline: \(error)")
            return nil
        }
    }

    /// Only suggestions about real items, with start days that are in the window, not in the
    /// past, not crunch days, and before the item is due.
    @available(iOS 26.0, macOS 26.0, *)
    static func validated(
        _ proposals: [ModelSuggestion],
        curve: WorkloadCurve,
        today: Date,
        calendar: Calendar
    ) -> [CrunchSuggestion] {
        let items = Dictionary(curve.days.flatMap(\.contributions).map { ($0.item.id, $0.item) }, uniquingKeysWith: { first, _ in first })
        let firstCrunch = curve.crunchDays.first?.date
        var seen = Set<String>()

        return proposals.compactMap { proposal in
            guard let item = items[proposal.id], seen.insert(item.id).inserted else { return nil }
            let reason = proposal.reason.trimmingCharacters(in: .whitespacesAndNewlines)

            switch proposal.kind {
            case "startEarly":
                guard let text = proposal.startDay, let start = parseDay(text, calendar: calendar),
                      let index = curve.index(of: start, calendar: calendar),
                      !curve.days[index].isCrunch,
                      calendar.startOfDay(for: start) >= calendar.startOfDay(for: today),
                      calendar.startOfDay(for: start) < calendar.startOfDay(for: item.date) else {
                    return nil
                }
                return CrunchSuggestion(item: item, kind: .startEarly(on: curve.days[index].date), reason: reason)
            case "canSlip":
                guard let crunch = firstCrunch, item.date > crunch else { return nil }
                return CrunchSuggestion(item: item, kind: .canSlip(after: crunch), reason: reason)
            case "warning":
                return CrunchSuggestion(item: item, kind: .warning, reason: reason)
            default:
                return nil
            }
        }
    }

    static func promptText(for curve: WorkloadCurve, today: Date, calendar: Calendar) -> String {
        var lines = ["Today is \(isoDay(today, calendar: calendar)).", "", "Days (load, crunch marked *):"]
        for day in curve.days {
            lines.append("\(isoDay(day.date, calendar: calendar)) \(String(format: "%.1f", day.load))\(day.isCrunch ? " *" : "")")
        }

        lines += ["", "Items on crunch days:"]
        var listed = Set<String>()
        for crunch in curve.crunchDays {
            for contribution in crunch.contributions where listed.insert(contribution.item.id).inserted {
                let item = contribution.item
                let course = item.courseName.map { " (\($0))" } ?? ""
                lines.append("[\(item.id)] \(item.title)\(course) | \(item.kind.rawValue) | due \(isoDay(item.date, calendar: calendar)) | effort \(String(format: "%.1f", item.effort))")
            }
        }
        return lines.joined(separator: "\n")
    }

    // MARK: Dates

    private static func day(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    static func isoDay(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func parseDay(_ text: String, calendar: Calendar) -> Date? {
        let parts = text.trimmingCharacters(in: .whitespaces).split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
