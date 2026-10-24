//
//  BriefingConflictFinder.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/24/26.
//

import Foundation

/// What the briefing reads: recent announcements with their full text, and the records
/// (assignments, events) their dates are checked against.
@MainActor
protocol BriefingSource {
    func courseIDs() async throws -> [String]
    func announcements(courseID: String, postedSince: Date) async throws -> [AnnouncementText]
    func records(courseID: String) async throws -> [Evidence]
}

/// The app's `BriefingSource`: records come from the agent data source; announcements are read
/// cache-first (or from `SandboxData`) so the full message is available.
@MainActor
final class CanvasBriefingSource: BriefingSource {
    private let dataSource: any AgentDataSource
    private var courseNames: [String: String] = [:]

    init(dataSource: any AgentDataSource) {
        self.dataSource = dataSource
    }

    func courseIDs() async throws -> [String] {
        let courses = try await dataSource.courses()
        courseNames = Dictionary(courses.map { ($0.ref.recordID, $0.title) }, uniquingKeysWith: { first, _ in first })
        return courses.map(\.ref.recordID)
    }

    func announcements(courseID: String, postedSince: Date) async throws -> [AnnouncementText] {
        let topics: [DiscussionTopic]
        if AppEnvironment.isSandbox {
            topics = SandboxData.dummyAnnouncements(forCourseID: courseID)
        } else {
            let request = CanvasRequest.getDiscussionTopics(courseId: courseID, onlyAnnouncements: true)
            if let cached = try await CanvasService.shared.load(request), !cached.isEmpty {
                topics = cached
            } else {
                topics = try await CanvasService.shared.syncWithAPI(request)
            }
        }

        return topics
            .filter { ($0.postedAt ?? $0.createdAt ?? .distantPast) >= postedSince }
            .map { topic in
                AnnouncementText(
                    evidence: topic.evidence(courseID: courseID, courseName: courseNames[courseID]),
                    body: Evidence.plainText(topic.message ?? "")
                )
            }
    }

    func records(courseID: String) async throws -> [Evidence] {
        let assignments = try await dataSource.assignments(courseID: courseID)
        // Events are a bonus; a broken ICS feed shouldn't stop the assignment check.
        let events = (try? await dataSource.calendarEvents(courseID: courseID)) ?? []
        return assignments + events
    }
}

/// Runs the briefing's date check: extract dates from recent announcements, reconcile them
/// with Canvas records, and keep the latest report (saved, so cards in #588 can show it
/// without re-running).
@available(iOS 26.0, macOS 26.0, *)
@MainActor
@Observable
final class BriefingConflictFinder {
    static let shared = BriefingConflictFinder()

    private(set) var report: BriefingReport?
    private(set) var isRunning = false
    /// Which tier did the extraction in the last run.
    private(set) var lastTier: AgentTier?

    /// Only announcements posted this recently are read.
    var lookback: TimeInterval = 14 * 86_400
    /// `runIfDue` skips the run if the last one was this recent.
    var minimumInterval: TimeInterval = 6 * 3_600

    @ObservationIgnored private let defaults: UserDefaults
    private static let reportKey = "briefing.lastReport"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.reportKey) {
            report = try? JSONDecoder().decode(BriefingReport.self, from: data)
        }
    }

    /// Runs if there's no report yet or the last one is older than `minimumInterval`.
    func runIfDue(source: any BriefingSource, now: Date = .now) async {
        if let report, now.timeIntervalSince(report.generatedAt) < minimumInterval {
            return
        }
        await run(source: source, now: now)
    }

    /// - Parameter provider: defaults to the router's choice (on-device model, else none).
    @discardableResult
    func run(
        source: any BriefingSource,
        provider: (any AgentModelProvider)? = nil,
        now: Date = .now
    ) async -> BriefingReport {
        guard !isRunning else { return report ?? BriefingReport() }
        isRunning = true
        defer { isRunning = false }

        let provider = provider ?? AgentModelRouter().provider()
        let extractor = AnnouncementDateExtractor(provider: provider)
        let reconciler = BriefingReconciler()
        var combined = BriefingReport(generatedAt: now)

        let courseIDs = (try? await source.courseIDs()) ?? []
        for courseID in courseIDs {
            do {
                let announcements = try await source.announcements(
                    courseID: courseID,
                    postedSince: now.addingTimeInterval(-lookback)
                )
                guard !announcements.isEmpty else { continue }

                let records = try await source.records(courseID: courseID)
                var claims: [BriefingDateClaim] = []
                for announcement in announcements {
                    claims += await extractor.claims(in: announcement)
                }

                let report = reconciler.reconcile(claims, against: records)
                combined.conflicts += report.conflicts
                combined.confirmations += report.confirmations
                combined.unmatched += report.unmatched
            } catch {
                // One course failing shouldn't hide conflicts in the others.
                LoggerService.main.error("[Briefing] Skipping course \(courseID): \(error)")
            }
        }

        combined.conflicts.sort { $0.recordDate < $1.recordDate }
        report = combined
        lastTier = provider.tier
        if let data = try? JSONEncoder().encode(combined) {
            defaults.set(data, forKey: Self.reportKey)
        }

        return combined
    }
}
