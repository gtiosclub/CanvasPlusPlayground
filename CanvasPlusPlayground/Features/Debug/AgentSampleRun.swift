//
//  AgentSampleRun.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/24/26.
//

import Foundation
import FoundationModels

/// A small "what's due this week" agent for exercising the runtime and the trace screen.
///
/// It uses the real read tools and data source. When the on-device model isn't available
/// (simulator, no Apple Intelligence) the model steps are played by `ScriptedModelProvider`,
/// whose answer cites the real records the tools found.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
enum AgentSampleRun {
    static let graphName = "sample.dueThisWeek"

    @Generable
    struct Plan {
        @Guide(description: "The steps you'll take, in order, a few words each.")
        var steps: [String]
    }

    @Generable
    struct Brief {
        @Guide(description: "Two or three sentences on what's due this week, most urgent first.")
        var summary: String

        @Guide(description: "The ids (like assignment:123) of every record the summary mentions.")
        var citedIDs: [String]
    }

    static let evidenceKey = AgentStateKey<[Evidence]>("evidence")
    static let contextKey = AgentStateKey<String>("context")
    static let briefKey = AgentStateKey<String>("brief")
    /// Set to make the answer node stop as if the app had been suspended there.
    static let interruptKey = AgentStateKey<Bool>("interruptBeforeAnswer")

    static func graph(dataSource: any AgentDataSource) -> AgentGraph {
        AgentGraph(name: graphName, start: "plan", nodes: [
            AgentStep("plan") { context in
                let tools: [any Tool] = [
                    ListCoursesTool(dataSource: dataSource),
                    ListAssignmentsTool(dataSource: dataSource)
                ]
                let plan = try await context.respond(
                    to: AgentPrompt(
                        instructions: "You plan how to answer a student's question using the tools.",
                        text: "What's due this week across my courses?"
                    ),
                    tools: tools,
                    generating: Plan.self
                )
                context.note("Plan: \(plan.content.steps.joined(separator: " → "))")
                return .next("gather")
            },
            AgentStep("gather") { context in
                let evidence = try await dueSoon(in: dataSource)
                try context.set(evidence, for: evidenceKey)
                context.note("Found \(evidence.count) assignments due in the next 7 days or overdue")
                return .next("budget")
            },
            AgentStep("budget") { context in
                let evidence = context.value(evidenceKey) ?? []
                // Deliberately tight so the trace shows summarizing.
                let fitted = ContextBudgeter().fit(
                    evidence,
                    objective: "what's due this week",
                    tokenBudget: min(context.promptTokenAllowance, 260)
                )
                try context.set(fitted.text, for: contextKey)
                context.note(
                    "Kept \(fitted.fullEvidence.count) in full, \(fitted.summarizedEvidence.count) as one-line summaries, "
                        + "dropped \(fitted.omittedCount) (~\(fitted.estimatedTokens) tokens)"
                )
                return .next("answer")
            },
            AgentStep("answer") { context in
                if context.value(interruptKey) == true {
                    try context.set(false, for: interruptKey)
                    context.note("Stopping here as if the app was suspended. Resume picks up at this node.")
                    throw CancellationError()
                }

                let brief = try await context.respond(
                    to: AgentPrompt(
                        instructions: "Answer using only these records and cite their ids.",
                        text: context.value(contextKey) ?? ""
                    ),
                    generating: Brief.self
                )
                try context.set(brief.content.summary, for: briefKey)
                context.note("Cited \(brief.content.citedIDs.joined(separator: ", "))")
                return .finish
            }
        ])
    }

    /// The on-device model when it can run, otherwise a script that answers from the real records.
    /// - Parameter resumingAt: the node a resumed run starts at, so the script skips steps already done.
    static func provider(
        dataSource: any AgentDataSource,
        resumingAt nodeID: String? = nil
    ) async throws -> any AgentModelProvider {
        let onDevice = OnDeviceModelProvider()
        if onDevice.isAvailable {
            return onDevice
        }

        let evidence = try await dueSoon(in: dataSource)
        let cited = Array(evidence.prefix(3))
        let summary = cited.isEmpty
            ? "Nothing is due in the next week."
            : cited.map { "\($0.title) (\($0.facts.courseName ?? "course"))" }.joined(separator: ", ")
                + (cited.count == 1 ? " is" : " are") + " coming up first."

        let plan = ScriptedModelProvider.Step.respond(
            json: json(["steps": ["list courses", "list assignments due in 7 days", "fit to the window", "answer with citations"]]),
            toolCalls: [
                .init("listCourses"),
                .init("listAssignments", arguments: #"{"daysAhead": 7}"#)
            ]
        )
        let answer = ScriptedModelProvider.Step.respond(
            json: json(["summary": summary, "citedIDs": cited.map(\.id)])
        )

        let steps = nodeID == nil || nodeID == "plan" ? [plan, answer] : [answer]
        return AgentModelRouter(fallbackFake: ScriptedModelProvider(steps: steps)).provider()
    }

    private static func dueSoon(in dataSource: any AgentDataSource) async throws -> [Evidence] {
        let arguments = try ListAssignmentsTool.Arguments(
            GeneratedContent(json: #"{"daysAhead": 7, "includePastDue": true}"#)
        )
        return try await ListAssignmentsTool(dataSource: dataSource).evidence(for: arguments)
    }

    private static func json(_ object: [String: Any]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{}".utf8)
        return String(decoding: data, as: UTF8.self)
    }
}
