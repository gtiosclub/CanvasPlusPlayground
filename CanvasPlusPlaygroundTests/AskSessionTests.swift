//
//  AskSessionTests.swift
//  CanvasPlusPlaygroundTests
//

import Foundation
import FoundationModels
import Testing
@testable import CanvasPlusPlayground

private let latePolicy = Evidence(
    ref: .passage(sourceID: "syllabus:1", ordinal: 2, courseID: "1"),
    title: "CS 1331 Syllabus",
    snippet: "Late work loses 10% per day, up to three days.",
    facts: EvidenceFacts(courseName: "CS 1331")
)
private let officeHours = Evidence(
    ref: .passage(sourceID: "page:7", ordinal: 0, courseID: "1"),
    title: "Office Hours",
    snippet: "Office hours are Tuesdays 2-4 PM in CCB 345.",
    facts: EvidenceFacts(courseName: "CS 1331")
)
private let problemSet = Evidence(
    ref: .assignment(id: "55", courseID: "1"),
    title: "Problem Set 5",
    snippet: nil,
    facts: EvidenceFacts(courseName: "CS 1331", dueDate: Date(timeIntervalSince1970: 1_790_000_000))
)

private func answer(_ sentences: [(String, [String])], confidence: String = "high") -> String {
    let items = sentences.map { text, ids in
        #"{"text": "\#(text)", "citedIDs": [\#(ids.map { "\"\($0)\"" }.joined(separator: ","))]}"#
    }
    return #"{"sentences": [\#(items.joined(separator: ","))], "confidence": "\#(confidence)"}"#
}

/// A cloud model that always gives the same JSON.
@available(iOS 26.0, macOS 26.0, *)
private struct FakeCloud: AgentModelProvider {
    let tier = AgentTier.cloud
    let isAvailable = true
    let json: String

    func respond<Output: Generable>(to prompt: AgentPrompt, tools: [any Tool], generating type: Output.Type) async throws -> AgentResponse<Output> {
        AgentResponse(content: try Output(GeneratedContent(json: json)), tier: .cloud, toolCalls: [])
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct Unavailable: AgentModelProvider {
    let tier = AgentTier.onDevice
    let isAvailable = false

    func respond<Output: Generable>(to prompt: AgentPrompt, tools: [any Tool], generating type: Output.Type) async throws -> AgentResponse<Output> {
        throw AgentModelError.unavailable("test")
    }
}

@MainActor
struct AskSessionTests {
    let sources = [latePolicy, officeHours, problemSet]

    @available(iOS 26.0, macOS 26.0, *)
    private func session(
        onDevice: any AgentModelProvider,
        cloud: (any AgentModelProvider)? = nil,
        sources: [Evidence]? = nil
    ) -> AskSession {
        let sources = sources ?? self.sources
        return AskSession(
            courseID: "1",
            retrieve: { _, _ in sources },
            router: AgentModelRouter(onDevice: onDevice, cloud: cloud, noModel: NoModelProvider())
        )
    }

    @Test func showsOnlySentencesWithRealCitations() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let model = ScriptedModelProvider(steps: [.respond(json: answer([
            ("Late work loses 10% per day for up to three days.", [latePolicy.id]),
            ("You can also email the TA for an extension.", ["page:999#0"]),
        ]))])
        let ask = session(onDevice: model)

        await ask.ask("What's the late policy?")

        let revision = try #require(ask.current)
        #expect(revision.sentences.map(\.text) == ["Late work loses 10% per day for up to three days."])
        #expect(revision.sentences.first?.evidence.map(\.id) == [latePolicy.id])
        #expect(revision.droppedCount == 1)
        #expect(revision.tier == .onDevice)
        #expect(!revision.shouldOfferCloud)
        #expect(ask.state == .answered)
    }

    @Test func offersCloudWhenTheGateRejectsTheAnswerButNeverSwitchesOnItsOwn() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let model = ScriptedModelProvider(steps: [.respond(json: answer([("Made up.", ["page:404#1"])]))])
        let cloud = FakeCloud(json: answer([("Office hours are Tuesdays 2-4 PM.", [officeHours.id])]))
        let ask = session(onDevice: model, cloud: cloud)

        await ask.ask("When are office hours?")

        let rejected = try #require(ask.current)
        #expect(rejected.sentences.isEmpty)
        #expect(rejected.shouldOfferCloud)
        #expect(rejected.tier == .onDevice)
        #expect(ask.isCloudReady)

        await ask.tryWithCloud()

        let cloudAnswer = try #require(ask.current)
        #expect(cloudAnswer.tier == .cloud)
        #expect(cloudAnswer.sentences.count == 1)
        #expect(!cloudAnswer.shouldOfferCloud)
        #expect(ask.revisions.count == 2)
    }

    @Test func lowConfidenceAlsoOffersCloud() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let model = ScriptedModelProvider(steps: [.respond(json: answer([("Office hours are on Tuesdays.", [officeHours.id])], confidence: "low"))])
        let ask = session(onDevice: model)

        await ask.ask("Are office hours ever on Fridays?")

        #expect(ask.current?.shouldOfferCloud == true)
        #expect(!ask.isCloudReady)
    }

    @Test func followUpsReviseTheCardAndTheScrubberGoesBack() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let model = ScriptedModelProvider(steps: [
            .respond(json: answer([("Problem Set 5 is due soon.", [problemSet.id])])),
            .respond(json: answer([("Problem Set 5 is due soon; late work loses 10% per day.", [problemSet.id, latePolicy.id])])),
        ])
        let ask = session(onDevice: model)

        await ask.ask("When is PS5 due?")
        await ask.ask("What if I'm late?")

        #expect(ask.revisions.count == 2)
        #expect(ask.selectedRevision == 1)
        #expect(ask.current?.questions == ["When is PS5 due?", "What if I'm late?"])
        #expect(ask.current?.sentences.first?.evidence.count == 2)

        let prompts = await model.receivedPrompts
        #expect(prompts.count == 2)
        #expect(prompts[1].text.contains("Follow-up"))
        #expect(prompts[1].text.contains("Problem Set 5 is due soon."))
        #expect(prompts[0].courseIDs == ["1"])

        ask.selectedRevision = 0
        #expect(ask.current?.questions == ["When is PS5 due?"])
    }

    @Test func withoutAModelItQuotesTheSources() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let ask = session(onDevice: Unavailable())

        await ask.ask("late policy")

        let revision = try #require(ask.current)
        #expect(revision.isExtractive)
        #expect(revision.tier == .none)
        #expect(revision.sentences.count == 3)
        #expect(revision.sentences.allSatisfy { $0.evidence.count == 1 })
    }

    @Test func nothingRetrievedMeansNoAnswerAndNoModelCall() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let model = ScriptedModelProvider(steps: [])
        let ask = session(onDevice: model, sources: [])

        await ask.ask("What's the capital of France?")

        #expect(ask.current?.sentences.isEmpty == true)
        #expect(ask.current?.shouldOfferCloud == false)
        #expect(await model.receivedPrompts.isEmpty)
    }

    @Test func startOverClearsTheCard() async {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let ask = session(onDevice: Unavailable())
        await ask.ask("late")
        ask.startOver()
        #expect(ask.revisions.isEmpty)
        #expect(ask.state == .idle)
    }
}

struct AskRetrievalTests {
    @Test(arguments: [
        ("page:7", "page:7"),
        ("discussion:3", "announcement:3"),
        ("announcement:3", "announcement:3"),
        ("syllabus:1", "course:1"),
        ("quiz:9", "quiz:9"),
    ])
    func passagesOpenTheirSource(_ sourceID: String, expected: String) {
        let passage = Evidence(ref: .passage(sourceID: sourceID, ordinal: 0, courseID: nil), title: "t", snippet: nil)
        #expect(AskRetrieval.deepLink(for: passage) == expected)
    }

    @Test func recordsOpenThemselves() {
        #expect(AskRetrieval.deepLink(for: problemSet) == "assignment:55")
        #expect(AskRetrieval.deepLink(for: Evidence(ref: .calendarEvent(uid: "x", courseID: "1"), title: "t", snippet: nil)) == nil)
    }

    @Test func passageIdsIncludeTheChunk() {
        #expect(latePolicy.id == "passage:syllabus:1#2")
        #expect(latePolicy.ref.courseID == "1")
        #expect(latePolicy.ref.kind == .passage)
    }

    @Test func passageEvidenceUsesTheOutermostHeadingAsTitle() {
        let match = SemanticIndexer.Match(sourceID: "page:7", courseID: "1", ordinal: 3, headingPath: ["Office Hours", "Spring"], text: "Tuesdays 2-4", score: 1)
        let evidence = AskRetrieval.passageEvidence(match, courseName: "CS 1331")
        #expect(evidence.title == "Office Hours")
        #expect(evidence.id == "passage:page:7#3")
        #expect(evidence.facts.courseName == "CS 1331")
    }

    @Test @MainActor func spokenAnswerListsSources() {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let revision = AskRevision(
            questions: ["q"],
            sentences: [.init(text: "Late work loses 10% per day.", evidence: [latePolicy])],
            sources: [latePolicy],
            tier: .onDevice,
            droppedCount: 0,
            isExtractive: false,
            shouldOfferCloud: false
        )
        #expect(AskCanvasPlusIntent.spokenAnswer(for: revision) == "Late work loses 10% per day. Sources: CS 1331 Syllabus.")
        #expect(AskCanvasPlusIntent.spokenAnswer(for: nil).hasPrefix("I couldn't find"))
    }
}
