//
//  GradeCalculatorIntelligenceService.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 8/15/25.
//

import Playgrounds
import FoundationModels
import SwiftUI

@available(iOS 26.0, macOS 26.0, *)
@MainActor
@Observable
final class GradeCalculatorIntelligenceService: IntelligenceServiceProvider {
    typealias Input = PickableItem
    typealias Output = [GradeCalculatorIntelligenceServiceResult]

    var session: LanguageModelSession?
    private let groups: [GradeCalculator.GradeGroup]

    init?(groups: [GradeCalculator.GradeGroup]) {
        self.groups = groups
        setup()
    }

    func performRequest(for input: any Input) async throws -> Output {
        guard let session else {
            throw IntelligenceServiceError.sessionNotAvailable
        }

        let rag = RAGSystem()

        input.contents.split(separator: "\n\n").forEach {
            rag.addDocument(.init(id: UUID().uuidString, content: String($0)))
        }

        let relevantDocs = rag.searchRelevantDocuments(
            for: "What are the assignment groups and their corresponding weights in this course?",
            limit: 2
        )
        let context = relevantDocs.map { $0.content }.joined(separator: " ")

        let response = try await session.respond(to: Prompt {
            """
            You are an expert at analyzing university course syllabi and matching assignment category weights to those found in a Canvas course.
            """

            """
            TASK OVERVIEW:
            1. Examine the provided syllabus excerpts and the list of existing Canvas assignment groups and their weights.
            2. Identify each assignment group or category described in the syllabus and match it to an existing Canvas group if possible (using name, description, or purpose).
            3. For each syllabus group, compare the weight with the corresponding Canvas group. Identify any mismatches in weights or missing groups.
            4. If a syllabus group does not have a clear match, propose a new group with a unique identifier and a suitable name. If an existing Canvas group does not exist in the syllabus, ignore it for this task.
            5. For each group found or created, return its id, name, and correct weight as derived from the syllabus. Use the existing group id if matched, or a new unique id for new groups.
            6. If a split or merge is necessary (syllabus divides or combines groups differently than Canvas), clearly reflect this in group naming and explanation.
            7. The correct group weights you return should add up to 100 and have an extra group for extra credit, if clearly provided in the syllabus.
            """

            """
            Examples of expected inputs and outputs are as follows:
            """
            Example.groupAndSyllabusPairs

            """
            EXISTING CANVAS GROUPS:
            """
            groups

            """
            SYLLABUS EXCERPTS:
            """
            context
        }, generating: Output.self)

        return response.content
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct Example {
    let groups: [GradeCalculator.GradeGroup]
    let syllabusExcerpt: String
    let expectedOutput: [GradeCalculatorIntelligenceServiceResult]

    /// Example input/output triplets for prompt construction and testing.
    /// Each entry contains sample Canvas groups, a syllabus excerpt, and the expected output.
    static let groupAndSyllabusPairs: [Example] = [
        Example(
            groups: [
                .init(id: "1", name: "Homework", weight: 30),
                .init(id: "2", name: "Quizzes", weight: 20),
                .init(id: "3", name: "Midterm Exam", weight: 20),
                .init(id: "4", name: "Final Exam", weight: 30)
            ],
            syllabusExcerpt: """
            Grades in this course are determined as follows:
            - Homework assignments: 30%
            - Quizzes: 20%
            - Midterm Exam: 20%
            - Final Exam: 30%
            """,
            expectedOutput: [
                .init(id: "1", name: "Homework", weight: 30),
                .init(id: "2", name: "Quizzes", weight: 20),
                .init(id: "3", name: "Midterm Exam", weight: 20),
                .init(id: "4", name: "Final Exam", weight: 30)
            ]
        ),
        Example(
            groups: [
                .init(id: "1", name: "Exams", weight: 40),
                .init(id: "2", name: "Homework", weight: 30),
                .init(id: "3", name: "Projects", weight: 30)
            ],
            syllabusExcerpt: """
            Assessment breakdown:
            - Midterm Exam: 20%
            - Final Exam: 20%
            - Homework: 30%
            - Projects: 30%
            """,
            expectedOutput: [
                .init(id: "midterm-new", name: "Midterm Exam", weight: 20),
                .init(id: "final-new", name: "Final Exam", weight: 20),
                .init(id: "2", name: "Homework", weight: 30),
                .init(id: "3", name: "Projects", weight: 30)
            ]
        ),
        // Example: Empty groups array
        Example(
            groups: [],
            syllabusExcerpt: """
            Grades are based on:
            - Homework: 50%
            - Quizzes: 30%
            - Final Exam: 20%
            """,
            expectedOutput: [
                .init(id: "homework-new", name: "Homework", weight: 50),
                .init(id: "quizzes-new", name: "Quizzes", weight: 30),
                .init(id: "finalexam-new", name: "Final Exam", weight: 20)
            ]
        )
    ]
}

@available(iOS 26.0, macOS 26.0, *)
extension Example: PromptRepresentable {
    var promptRepresentation: Prompt {
        "EXAMPLE"

        """
        EXISTING CANVAS GROUPS:
        """
        groups

        "SYLLABUS EXCERPT:"
        syllabusExcerpt

        "EXPECTED OUTPUT:"
        expectedOutput
    }
}

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct GradeCalculatorIntelligenceServiceResult: Identifiable, Codable {
    @Guide(description: "The group id (existing or new unique id)")
    let id: String

    @Guide(description: "Group name")
    let name: String

    @Guide(description: "The correct group weight from the syllabus")
    let weight: Double
}

@available(iOS 26.0, macOS 26.0, *)
extension GradeCalculator.GradeGroup: PromptRepresentable {
    var promptRepresentation: Prompt {
        """
        id: \(id)
        name: \(name)
        weight: \(weight)
        """
    }
}
