//
//  WorkloadCurve.swift
//  CanvasPlusPlayground
//

import Foundation

/// Something that takes work before a date: an assignment, quiz, exam or other event.
struct WorkloadItem: Identifiable, Hashable, Sendable {
    enum Kind: String, Hashable, Sendable, CaseIterable {
        case assignment
        case quiz
        case exam
        case event
    }

    /// The evidence id, e.g. `assignment:123`, so plan items can cite it.
    let id: String
    let title: String
    let courseName: String?
    let kind: Kind
    /// When it's due (or when the event starts).
    let date: Date
    let pointsPossible: Double?
    /// The assignment group's share of the final grade, in percent, when known.
    let groupWeight: Double?
    /// Total points in that assignment group, so `pointsPossible` can be turned into a share of the grade.
    let groupPoints: Double?
    let evidence: Evidence?

    init(
        id: String,
        title: String,
        courseName: String? = nil,
        kind: Kind,
        date: Date,
        pointsPossible: Double? = nil,
        groupWeight: Double? = nil,
        groupPoints: Double? = nil,
        evidence: Evidence? = nil
    ) {
        self.id = id
        self.title = title
        self.courseName = courseName
        self.kind = kind
        self.date = date
        self.pointsPossible = pointsPossible
        self.groupWeight = groupWeight
        self.groupPoints = groupPoints
        self.evidence = evidence
    }

    /// How much work it is, on a rough scale where an ordinary assignment is about 1.
    var effort: Double {
        let base: Double = switch kind {
        case .assignment: 1.0
        case .quiz: 1.5
        case .exam: 3.0
        case .event: 0.25
        }

        // Share of the final grade beats raw points when both are known: 10% of the grade is a lot
        // of work whatever the points scale.
        if let share = gradeShare {
            return base * (0.6 + min(share, 30) / 10)
        }
        if let points = pointsPossible, points > 0 {
            return base * (0.6 + min(points, 100) / 50)
        }
        return base
    }

    /// Percent of the final grade, when the group weight and points are known.
    var gradeShare: Double? {
        guard let groupWeight, groupWeight > 0 else { return nil }
        guard let points = pointsPossible, let groupPoints, groupPoints > 0 else { return nil }
        return groupWeight * points / groupPoints
    }

    /// How many days before the date the work usually happens.
    var leadDays: Int {
        switch kind {
        case .assignment: 3
        case .quiz: 2
        case .exam: 5
        case .event: 0
        }
    }

    /// Titles like "Midterm 1" or "Final Exam" are exams even when Canvas lists them as assignments or events.
    static func kind(forTitle title: String, default fallback: Kind) -> Kind {
        let lowered = title.lowercased()
        let examWords = ["exam", "midterm", "final"]
        if examWords.contains(where: lowered.contains) { return .exam }
        if lowered.contains("quiz") && fallback != .exam { return .quiz }
        return fallback
    }
}

/// Load per day over the next few weeks, worked out in Swift from due dates and weights.
/// No model is involved; the plan (`CrunchPlanner`) only reads this.
struct WorkloadCurve: Sendable {
    struct Day: Identifiable, Hashable, Sendable {
        let date: Date
        var load: Double
        /// Items whose work lands on this day, with how much of each.
        var contributions: [Contribution]
        var isCrunch = false

        var id: Date { date }

        /// What's actually due that day, as opposed to work spread from later deadlines.
        var dueItems: [WorkloadItem] {
            contributions.filter(\.isDueThatDay).map(\.item)
        }
    }

    struct Contribution: Hashable, Sendable {
        let item: WorkloadItem
        let load: Double
        let isDueThatDay: Bool
    }

    static let defaultDays = 21
    /// A day needs at least this much load to count as a crunch, so a quiet week with one
    /// assignment doesn't light up.
    static let crunchFloor = 3.0
    /// …and this many times the median of the busy days.
    static let crunchRatio = 1.5

    let days: [Day]

    var crunchDays: [Day] { days.filter(\.isCrunch) }

    /// A day needs at least this much load to count as one of the busiest days.
    static let busiestFloor = 1.0

    /// The days a plan should work around: the crunch days, or when there are none, the two
    /// busiest days (if they're busy at all). In date order.
    var focusDays: [Day] {
        let crunch = crunchDays
        if !crunch.isEmpty { return crunch }
        return days
            .filter { $0.load >= Self.busiestFloor }
            .sorted { $0.load > $1.load }
            .prefix(2)
            .sorted { $0.date < $1.date }
    }

    var hasCrunch: Bool { days.contains(where: \.isCrunch) }
    var peakLoad: Double { days.map(\.load).max() ?? 0 }

    /// - Parameters:
    ///   - items: Upcoming work. Items outside the window still count if their lead-up overlaps it.
    ///   - start: Any time on the first day.
    ///   - dayCount: How many days to cover.
    init(items: [WorkloadItem], from start: Date, days dayCount: Int = defaultDays, calendar: Calendar = .current) {
        let firstDay = calendar.startOfDay(for: start)
        var days = (0..<dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: firstDay).map { Day(date: $0, load: 0, contributions: []) }
        }
        let index = { (date: Date) -> Int? in
            calendar.dateComponents([.day], from: firstDay, to: calendar.startOfDay(for: date)).day
        }

        for item in items {
            guard let dueIndex = index(item.date), dueIndex >= 0 else { continue }

            // Spread the effort over the lead-up, more of it closer to the date: weights 1, 2, …, lead+1.
            let lead = item.leadDays
            let weights = (0...lead).map { Double($0 + 1) }
            let total = weights.reduce(0, +)

            for (step, weight) in weights.enumerated() {
                let dayIndex = dueIndex - lead + step
                guard days.indices.contains(dayIndex) else { continue }
                let share = item.effort * weight / total
                days[dayIndex].load += share
                days[dayIndex].contributions.append(Contribution(item: item, load: share, isDueThatDay: dayIndex == dueIndex))
            }
        }

        let busy = days.map(\.load).filter { $0 > 0 }.sorted()
        let median = busy.isEmpty ? 0 : busy[busy.count / 2]
        let threshold = max(Self.crunchFloor, median * Self.crunchRatio)
        for index in days.indices {
            days[index].isCrunch = days[index].load >= threshold
            days[index].contributions.sort { $0.load > $1.load }
        }

        self.days = days
    }

    /// The least-loaded day in `range` (by index into `days`), earliest on ties.
    func lightestDay(in range: Range<Int>) -> Day? {
        let clamped = range.clamped(to: days.indices)
        return days[clamped].min { $0.load != $1.load ? $0.load < $1.load : $0.date < $1.date }
    }

    func index(of date: Date, calendar: Calendar = .current) -> Int? {
        days.firstIndex { calendar.isDate($0.date, inSameDayAs: date) }
    }
}
