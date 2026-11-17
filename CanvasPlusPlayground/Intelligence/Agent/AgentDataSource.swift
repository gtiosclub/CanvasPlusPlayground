//
//  AgentDataSource.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/8/26.
//

import Foundation

/// Where the read tools get their records from.
///
/// The app uses `CanvasCacheAgentDataSource`, which reads the local cache first. Tests and
/// previews can swap in a fake.
@MainActor
protocol AgentDataSource: Sendable {
    func courses() async throws -> [Evidence]
    func assignments(courseID: String) async throws -> [Evidence]
    func announcements(courseID: String) async throws -> [Evidence]
    func calendarEvents(courseID: String) async throws -> [Evidence]
    func toDos() async throws -> [Evidence]
    func files(courseID: String) async throws -> [Evidence]
}
