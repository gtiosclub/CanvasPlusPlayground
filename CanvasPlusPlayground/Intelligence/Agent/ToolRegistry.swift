//
//  ToolRegistry.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation
import FoundationModels

/// Builds the tool set for one agent run.
///
/// Every tool's schema is sent to the model and costs context, so each task asks only for the
/// tools it needs (`Scope`). Read tools are wrapped so everything they return lands in the run's
/// log, and write tools only queue `ProposedAction`s in that same log.
@available(iOS 26.0, macOS 26.0, *)
struct ToolRegistry: Sendable {
    enum ToolName: String, CaseIterable, Sendable {
        case listCourses
        case listAssignments
        case listAnnouncements
        case listCalendarEvents
        case listToDos
        case listFiles
        case proposeReminder
        case proposePin
        case proposeToDoDone

        var isWrite: Bool {
            switch self {
            case .proposeReminder, .proposePin, .proposeToDoDone:
                true
            default:
                false
            }
        }
    }

    /// The tools a task may use.
    struct Scope: Hashable, Sendable, ExpressibleByArrayLiteral {
        let tools: Set<ToolName>

        init(_ tools: Set<ToolName>) {
            self.tools = tools
        }

        init(arrayLiteral elements: ToolName...) {
            self.tools = Set(elements)
        }

        /// Briefing (#586, #588): what changed and what's coming up. Read-only.
        static let briefing: Scope = [.listCourses, .listAnnouncements, .listAssignments, .listCalendarEvents]
        /// Crunch / plan my week (#591): workload plus reminders to start early.
        static let planWeek: Scope = [.listCourses, .listAssignments, .listToDos, .listCalendarEvents, .proposeReminder]
        /// Ask your course (#600): read-only answers.
        static let ask: Scope = [.listCourses, .listAssignments, .listAnnouncements, .listCalendarEvents, .listFiles]
        static let all = Scope(Set(ToolName.allCases))
    }

    let dataSource: any AgentDataSource
    var now: @Sendable () -> Date = { .now }

    /// A fresh tool set and log for one run. Tools come back in `ToolName` order so the
    /// prompt is the same every time for the same scope.
    func makeRun(scope: Scope) -> AgentToolRun {
        let log = AgentRunLog()
        let tools = ToolName.allCases
            .filter { scope.tools.contains($0) }
            .map { makeTool($0, log: log) }

        return AgentToolRun(tools: tools, log: log)
    }

    private func makeTool(_ name: ToolName, log: AgentRunLog) -> any Tool {
        switch name {
        case .listCourses:
            RecordingTool(base: ListCoursesTool(dataSource: dataSource), log: log)
        case .listAssignments:
            RecordingTool(base: ListAssignmentsTool(dataSource: dataSource, now: now), log: log)
        case .listAnnouncements:
            RecordingTool(base: ListAnnouncementsTool(dataSource: dataSource, now: now), log: log)
        case .listCalendarEvents:
            RecordingTool(base: ListCalendarEventsTool(dataSource: dataSource, now: now), log: log)
        case .listToDos:
            RecordingTool(base: ListToDosTool(dataSource: dataSource, now: now), log: log)
        case .listFiles:
            RecordingTool(base: ListFilesTool(dataSource: dataSource), log: log)
        case .proposeReminder:
            ProposeReminderTool(log: log, now: now)
        case .proposePin:
            ProposePinTool(log: log)
        case .proposeToDoDone:
            ProposeToDoDoneTool(log: log)
        }
    }
}

/// The tools and log for one agent run. Pass `tools` to the model provider, then read
/// `log.evidence` for the EvidenceGate and `log.proposedActions` for the approval UI.
@available(iOS 26.0, macOS 26.0, *)
struct AgentToolRun: Sendable {
    let tools: [any Tool]
    let log: AgentRunLog

    var toolNames: [String] { tools.map(\.name) }
}
