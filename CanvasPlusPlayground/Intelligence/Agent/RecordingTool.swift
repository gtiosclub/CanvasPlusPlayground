//
//  RecordingTool.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation
import FoundationModels

/// Wraps a read tool so everything it returns is written to the run's log. The model sees
/// the same name, description and schema as the wrapped tool.
@available(iOS 26.0, macOS 26.0, *)
struct RecordingTool<Base: AgentTool>: AgentTool {
    typealias Arguments = Base.Arguments

    let base: Base
    let log: AgentRunLog

    var name: String { base.name }
    var description: String { base.description }
    var parameters: GenerationSchema { base.parameters }

    func evidence(for arguments: Arguments) async throws -> [Evidence] {
        let evidence = try await base.evidence(for: arguments)
        await log.record(evidence)
        return evidence
    }
}
