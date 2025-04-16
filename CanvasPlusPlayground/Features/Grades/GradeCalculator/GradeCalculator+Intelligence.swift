//
//  GradeCalculator+Intelligence.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/29/25.
//

import SwiftUI

extension GradeCalculator {
    struct IntelligenceResult: Codable {
        let name: String
        let weight: Double
    }

    /// Indicates whether this Course would benefit by using Intelligence.
    /// e.g. if groups are unweighted or there are no assignment groups.
    var canUseIntelligenceAssistance: Bool {
        true
        // !gradeGroups.isEmpty && gradeGroups.reduce(0.0) { $0 + $1.weight } == 0.0
    }

    func extractWeightsUsingFile(
        contents: String,
        intelligenceManager: IntelligenceManager,
        llmEvaluator: LLMEvaluator
    ) async -> [GradeGroup] {
        var query = "Identify the weights and categories of the assignments in this course."

        if gradeGroups.count > 1 {
            // swiftlint:disable:next line_length
            query += "The groups in the course are known to be the following: \(gradeGroups.map(\.name).joined(separator: ", ")). Look carefully for these groups in the text and assign the appropriate weights. The groups may be incorrect or named differently, and there may be additional groups not listed here."
        }

        let rag = RAGSystem()

        contents.split(separator: "\n\n").forEach {
            rag.addDocument(.init(id: UUID().uuidString, content: String($0)))
        }

        let relevantDocs = rag.searchRelevantDocuments(for: query)
        let context = relevantDocs.map { $0.content }.joined(separator: " ")

        let prompt = """
        Context: \(context)

        Query: \(query)

        RETURN the answer ONLY in a JSON format, following EXACTLY
        the format BELOW. INCLUDE THE PARAMETER NAMES AND ENCLOSE EACH OBJECT IN CURLY BRACKETS AND THE ENTIRE ARRAY IN SQUARE BRACKETS.

        ```[{"name": "Group 1", "weight": 45.0},{"name": "Group 2","weight": 15.0},{ "name": "Group 3","weight": 40.0}]```

        Based on the given context, answer the above query to the point and precisely.
        Do not mention anything else other than directly answering the question.
        """

        if let modelName = intelligenceManager.currentModelName {
            let answerText = await llmEvaluator
                .generate(
                    modelName: modelName,
                    message: prompt,
                    systemPrompt: intelligenceManager.systemPrompt
                )
                .trimmingCharacters(in: .whitespacesAndNewlines)

            LoggerService.main.debug("Extracted weights: \(answerText)")

            if let data = answerText.data(using: .utf8) {
                if let results = try? JSONDecoder().decode(
                    [IntelligenceResult].self,
                    from: data
                ) {
                    return results.map {
                        GradeGroup(
                            id: UUID().uuidString,
                            name: $0.name,
                            weight: $0.weight,
                            assignments: []
                        )
                    }
                } else {
                    print("Failed to decode")
                }
            } else {
                print("Failed to make data")
            }
        }

        return []
    }
}
