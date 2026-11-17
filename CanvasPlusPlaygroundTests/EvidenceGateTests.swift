//
//  EvidenceGateTests.swift
//  CanvasPlusPlaygroundTests
//

import Foundation
import Testing
@testable import CanvasPlusPlayground

// MARK: - Fixtures

private let eastern = TimeZone(identifier: "America/New_York")!

private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, in timeZone: TimeZone = eastern) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

private func makeCalendar(in timeZone: TimeZone) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar
}

private func assignment(
    _ id: String,
    course: String = "100",
    due: Date? = nil,
    points: Double? = nil,
    score: Double? = nil,
    weight: Double? = nil
) -> Evidence {
    var facts = EvidenceFacts(courseName: "CS \(course)", dueDate: due, pointsPossible: points, score: score)
    facts.weight = weight
    return Evidence(ref: .assignment(id: id, courseID: course), title: "Assignment \(id)", snippet: nil, facts: facts)
}

/// Returns whatever is in `records`, keyed by evidence id, and counts reads.
@MainActor
private final class FakeResolver: EvidenceResolver {
    var records: [String: Evidence]
    private(set) var reads: [String] = []

    init(_ records: [Evidence]) {
        self.records = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
    }

    func resolve(_ ref: EvidenceRef) async -> Evidence? {
        reads.append(ref.id)
        return records[ref.id]
    }
}

@MainActor
private func makeGate(
    returned: [Evidence],
    current: [Evidence]? = nil,
    calendar: Calendar = makeCalendar(in: eastern)
) -> (EvidenceGate, FakeResolver) {
    let resolver = FakeResolver(current ?? returned)
    return (EvidenceGate(evidence: returned, resolver: resolver, calendar: calendar), resolver)
}

private func claim(_ citations: [String], _ checks: [ClaimCheck] = []) -> AgentClaim {
    AgentClaim(text: "claim", citations: citations, checks: checks)
}

// MARK: - Citations

@MainActor
struct EvidenceGateCitationTests {
    let a1 = assignment("1", due: date(2026, 10, 8, 23, 59), points: 10)

    @Test func claimWithoutCitationsIsDropped() async {
        let (gate, _) = makeGate(returned: [a1])
        let result = await gate.evaluate([claim([])])
        #expect(result.dropped.map(\.reason) == [.noCitations])
    }

    @Test func citationNotReturnedByAToolIsIgnored() async {
        let (gate, resolver) = makeGate(returned: [a1], current: [a1, assignment("99")])
        let result = await gate.evaluate([claim(["assignment:99"])])
        #expect(result.dropped.map(\.reason) == [.unresolvableCitations(["assignment:99"])])
        // Never even looked up: it wasn't in this run's evidence.
        #expect(resolver.reads.isEmpty)
    }

    @Test(arguments: ["", "assignment", "assignment:", "1", "nonsense:1"])
    func malformedCitationIsDropped(_ citation: String) async {
        let (gate, _) = makeGate(returned: [a1])
        let result = await gate.evaluate([claim([citation])])
        #expect(result.verified.isEmpty)
        #expect(result.dropped.count == 1)
    }

    @Test func deletedRecordIsDropped() async {
        let (gate, _) = makeGate(returned: [a1], current: [])
        let result = await gate.evaluate([claim(["assignment:1"])])
        #expect(result.dropped.map(\.reason) == [.unresolvableCitations(["assignment:1"])])
    }

    @Test func duplicateCitationsResolveOnce() async {
        let (gate, resolver) = makeGate(returned: [a1])
        let result = await gate.evaluate([claim(["assignment:1", "assignment:1"])])
        #expect(resolver.reads == ["assignment:1"])
        #expect(result.verified.first?.evidence.map(\.id) == ["assignment:1"])
    }

    @Test func validCitationWithoutChecksIsVerified() async {
        let (gate, _) = makeGate(returned: [a1])
        let result = await gate.evaluate([claim(["assignment:1"])])
        #expect(result.verified.count == 1)
        #expect(result.conflicts.isEmpty && result.dropped.isEmpty)
    }

    @Test func oneGoodCitationIsEnoughWhenChecksUseIt() async {
        let (gate, _) = makeGate(returned: [a1])
        let result = await gate.evaluate([
            claim(["assignment:404", "assignment:1"], [.pointsPossible(10, of: "assignment:1")])
        ])
        #expect(result.verified.first?.evidence.map(\.id) == ["assignment:1"])
    }
}

// MARK: - Checks are tied to one record

@MainActor
struct EvidenceGatePerRecordTests {
    let a1 = assignment("1", due: date(2026, 10, 8, 23, 59), points: 10, score: 9)
    let a2 = assignment("2", due: date(2026, 10, 10, 23, 59), points: 20, score: 15)

    /// The case from review: citing two assignments and claiming one is due on the other's date.
    @Test func dateMatchingADifferentCitedRecordIsAConflict() async throws {
        let (gate, _) = makeGate(returned: [a1, a2])
        let result = await gate.evaluate([
            claim(["assignment:1", "assignment:2"], [.date(.due, date(2026, 10, 8, 23, 59), of: "assignment:2")])
        ])

        let conflict = try #require(result.conflicts.first)
        #expect(result.verified.isEmpty)
        #expect(conflict.mismatches.map(\.evidenceID) == ["assignment:2"])
        #expect(conflict.mismatches.first?.sourceValue == .date(date(2026, 10, 10, 23, 59)))
    }

    @Test func scoreMatchingADifferentCitedRecordIsAConflict() async {
        let (gate, _) = makeGate(returned: [a1, a2])
        let result = await gate.evaluate([claim(["assignment:1", "assignment:2"], [.score(9, of: "assignment:2")])])
        #expect(result.conflicts.first?.mismatches.first?.sourceValue == .number(15))
    }

    @Test func eachCheckIsComparedWithItsOwnRecord() async throws {
        let (gate, _) = makeGate(returned: [a1, a2])
        let result = await gate.evaluate([
            claim(
                ["assignment:1", "assignment:2"],
                [.score(9, of: "assignment:1"), .score(16, of: "assignment:2"), .pointsPossible(20, of: "assignment:2")]
            )
        ])

        let conflict = try #require(result.conflicts.first)
        #expect(conflict.mismatches.count == 1)
        #expect(conflict.mismatches.first?.check == .score(16, of: "assignment:2"))
    }

    @Test func comparisonAcrossTwoRecordsIsVerified() async {
        let (gate, _) = makeGate(returned: [a1, a2])
        let result = await gate.evaluate([
            claim(
                ["assignment:1", "assignment:2"],
                [.date(.due, a1.facts.dueDate!, of: "assignment:1"), .date(.due, a2.facts.dueDate!, of: "assignment:2")]
            )
        ])
        #expect(result.verified.count == 1)
    }

    @Test func checkAboutAnUncitedRecordIsDropped() async {
        // assignment:2 came back from a tool, but this claim doesn't cite it.
        let (gate, _) = makeGate(returned: [a1, a2])
        let check = ClaimCheck.score(15, of: "assignment:2")
        let result = await gate.evaluate([claim(["assignment:1"], [check])])
        #expect(result.dropped.map(\.reason) == [.uncitedCheck(check)])
    }

    @Test func checkAboutACitedButDeletedRecordIsDropped() async {
        let (gate, _) = makeGate(returned: [a1, a2], current: [a1])
        let check = ClaimCheck.score(15, of: "assignment:2")
        let result = await gate.evaluate([claim(["assignment:1", "assignment:2"], [check])])
        #expect(result.dropped.map(\.reason) == [.uncitedCheck(check)])
    }
}

// MARK: - Values

@MainActor
struct EvidenceGateValueTests {
    /// 11:59 PM Eastern on Oct 22 is 03:59 UTC on Oct 23.
    let lateNight = assignment("1", due: date(2026, 10, 22, 23, 59), points: 10, score: 8.5, weight: 25)

    @Test func minutePrecisionMatchesSameMinute() async {
        let (gate, _) = makeGate(returned: [lateNight])
        let result = await gate.evaluate([claim(["assignment:1"], [.date(.due, date(2026, 10, 22, 23, 59), of: "assignment:1")])])
        #expect(result.verified.count == 1)
    }

    @Test func minutePrecisionCatchesWrongTime() async {
        let (gate, _) = makeGate(returned: [lateNight])
        let result = await gate.evaluate([claim(["assignment:1"], [.date(.due, date(2026, 10, 22, 23, 0), of: "assignment:1")])])
        #expect(result.conflicts.first?.mismatches.first?.sourceValue == .date(date(2026, 10, 22, 23, 59)))
    }

    @Test func dayPrecisionUsesTheStudentsCalendar() async {
        let check = ClaimCheck.date(.due, date(2026, 10, 22, 12), precision: .day, of: "assignment:1")

        let (local, _) = makeGate(returned: [lateNight], calendar: makeCalendar(in: eastern))
        #expect(await local.evaluate([claim(["assignment:1"], [check])]).verified.count == 1)

        // In UTC the deadline falls on the 23rd, which is exactly the bug the local calendar avoids.
        let (utc, _) = makeGate(returned: [lateNight], calendar: makeCalendar(in: TimeZone(identifier: "UTC")!))
        #expect(await utc.evaluate([claim(["assignment:1"], [check])]).conflicts.count == 1)
    }

    @Test func dayPrecisionCatchesWrongDay() async {
        let (gate, _) = makeGate(returned: [lateNight])
        let check = ClaimCheck.date(.due, date(2026, 10, 23, 9), precision: .day, of: "assignment:1")
        #expect(await gate.evaluate([claim(["assignment:1"], [check])]).conflicts.count == 1)
    }

    @Test(arguments: [(10.0, true), (10.005, true), (9.995, true), (9.9, false), (11, false)])
    func pointsUseTolerance(claimed: Double, matches: Bool) async {
        let (gate, _) = makeGate(returned: [lateNight])
        let result = await gate.evaluate([claim(["assignment:1"], [.pointsPossible(claimed, of: "assignment:1")])])
        #expect(result.verified.count == (matches ? 1 : 0))
        #expect(result.conflicts.count == (matches ? 0 : 1))
    }

    @Test func scoreAndWeightAreChecked() async {
        let (gate, _) = makeGate(returned: [lateNight])
        let result = await gate.evaluate([
            claim(["assignment:1"], [.score(8.5, of: "assignment:1"), .weight(25, of: "assignment:1")]),
            claim(["assignment:1"], [.weight(30, of: "assignment:1")])
        ])
        #expect(result.verified.count == 1)
        #expect(result.conflicts.first?.mismatches.first?.sourceValue == .number(25))
    }

    @Test func valueTheRecordDoesNotHaveIsUnsupported() async {
        let ungraded = assignment("2", due: nil, points: 10)
        let (gate, _) = makeGate(returned: [ungraded])
        let check = ClaimCheck.score(10, of: "assignment:2")
        let dateCheck = ClaimCheck.date(.due, .now, of: "assignment:2")
        let result = await gate.evaluate([claim(["assignment:2"], [check]), claim(["assignment:2"], [dateCheck])])
        #expect(result.dropped.map(\.reason) == [.unsupportedCheck(check), .unsupportedCheck(dateCheck)])
    }

    @Test func unsupportedWinsOverAnEarlierMismatch() async {
        let (gate, _) = makeGate(returned: [lateNight])
        let unsupported = ClaimCheck.date(.start, .now, of: "assignment:1")
        let result = await gate.evaluate([claim(["assignment:1"], [.score(1, of: "assignment:1"), unsupported])])
        #expect(result.dropped.map(\.reason) == [.unsupportedCheck(unsupported)])
    }

    @Test func checksRunAgainstTheReReadRecordNotStaleToolOutput() async {
        let stale = assignment("1", due: date(2026, 10, 8, 23, 59))
        let moved = assignment("1", due: date(2026, 10, 9, 23, 59))
        let (gate, _) = makeGate(returned: [stale], current: [moved])

        let result = await gate.evaluate([claim(["assignment:1"], [.date(.due, date(2026, 10, 8, 23, 59), of: "assignment:1")])])
        #expect(result.conflicts.first?.mismatches.first?.sourceValue == .date(date(2026, 10, 9, 23, 59)))
        #expect(result.conflicts.first?.evidence.first?.facts.dueDate == date(2026, 10, 9, 23, 59))
    }
}

// MARK: - Batches

@MainActor
struct EvidenceGateBatchTests {
    let a1 = assignment("1", points: 10)
    let a2 = assignment("2", points: 20)

    var claims: [AgentClaim] {
        [
            AgentClaim(text: "a", citations: ["assignment:1"], checks: [.pointsPossible(10, of: "assignment:1")]),
            AgentClaim(text: "b", citations: []),
            AgentClaim(text: "c", citations: ["assignment:2"], checks: [.pointsPossible(5, of: "assignment:2")]),
            AgentClaim(text: "d", citations: ["assignment:2"]),
            AgentClaim(text: "e", citations: ["assignment:9"])
        ]
    }

    @Test func keepsInputOrderWithinEachBucket() async {
        let (gate, _) = makeGate(returned: [a1, a2])
        let result = await gate.evaluate(claims)
        #expect(result.verified.map(\.claim.text) == ["a", "d"])
        #expect(result.conflicts.map(\.claim.text) == ["c"])
        #expect(result.dropped.map(\.claim.text) == ["b", "e"])
    }

    @Test func isDeterministic() async {
        let batch = claims
        let (first, _) = makeGate(returned: [a1, a2])
        let (second, _) = makeGate(returned: [a1, a2])
        let one = await first.evaluate(batch)
        let two = await second.evaluate(batch)
        #expect(one.verified.map(\.claim) == two.verified.map(\.claim))
        #expect(one.conflicts.map(\.mismatches) == two.conflicts.map(\.mismatches))
        #expect(one.dropped.map(\.reason) == two.dropped.map(\.reason))
    }
}

// MARK: - DataSourceEvidenceResolver

@MainActor
private final class FakeDataSource: AgentDataSource {
    var assignmentsByCourse: [String: [Evidence]] = [:]
    var failingCourses: Set<String> = []
    private(set) var assignmentReads: [String] = []

    struct Failure: Error {}

    func courses() async throws -> [Evidence] { [] }
    func announcements(courseID: String) async throws -> [Evidence] { [] }
    func calendarEvents(courseID: String) async throws -> [Evidence] { [] }
    func toDos() async throws -> [Evidence] { [] }
    func files(courseID: String) async throws -> [Evidence] { [] }

    func assignments(courseID: String) async throws -> [Evidence] {
        assignmentReads.append(courseID)
        if failingCourses.contains(courseID) { throw Failure() }
        return assignmentsByCourse[courseID] ?? []
    }
}

@MainActor
struct DataSourceEvidenceResolverTests {
    @Test func readsEachCourseOncePerPass() async {
        let source = FakeDataSource()
        let a1 = assignment("1", course: "100", points: 10)
        let a2 = assignment("2", course: "100", points: 20)
        let b1 = assignment("3", course: "200", points: 5)
        source.assignmentsByCourse = ["100": [a1, a2], "200": [b1]]

        let gate = EvidenceGate(evidence: [a1, a2, b1], resolver: DataSourceEvidenceResolver(dataSource: source))
        let result = await gate.evaluate([
            claim(["assignment:1"]), claim(["assignment:2"]), claim(["assignment:3"]), claim(["assignment:1", "assignment:3"])
        ])

        #expect(result.verified.count == 4)
        #expect(source.assignmentReads == ["100", "200"])
    }

    @Test func sourceFailureDropsTheClaim() async {
        let source = FakeDataSource()
        source.failingCourses = ["100"]
        let a1 = assignment("1", course: "100", points: 10)

        let gate = EvidenceGate(evidence: [a1], resolver: DataSourceEvidenceResolver(dataSource: source))
        let result = await gate.evaluate([claim(["assignment:1"], [.pointsPossible(10, of: "assignment:1")])])
        #expect(result.dropped.map(\.reason) == [.unresolvableCitations(["assignment:1"])])
    }
}

// MARK: - Codable

struct AgentClaimCodableTests {
    @Test func roundTrips() throws {
        let original = AgentClaim(
            text: "Problem Set 5 is due Thursday and is worth 10 points.",
            citations: ["assignment:1", "event:abc"],
            checks: [
                .date(.due, date(2026, 10, 8, 23, 59), precision: .day, of: "assignment:1"),
                .date(.start, date(2026, 10, 9, 9), of: "event:abc"),
                .pointsPossible(10, of: "assignment:1"),
                .score(9.5, of: "assignment:1"),
                .weight(20, of: "assignment:1")
            ]
        )

        let decoded = try JSONDecoder().decode(AgentClaim.self, from: JSONEncoder().encode(original))
        #expect(decoded == original)
    }
}
