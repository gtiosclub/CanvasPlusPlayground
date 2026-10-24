//
//  BriefingDateClaim.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/24/26.
//

import Foundation
import FoundationModels

/// An announcement with its full text. `Evidence` snippets are capped for prompts, but
/// extraction needs the whole message.
struct AnnouncementText: Hashable, Sendable {
    let evidence: Evidence
    /// Plain text (HTML stripped).
    let body: String

    var postedAt: Date? {
        evidence.facts.postedAt
    }
}

/// A date an announcement gives for something, e.g. "Project 2 is now due Friday at 11:59 PM".
struct BriefingDateClaim: Hashable, Codable, Sendable {
    /// The announcement it came from.
    let source: Evidence
    /// What the date is for, as the text names it ("Project 2", "the midterm"). Without a model
    /// this is the whole sentence.
    let itemMentioned: String
    let date: Date
    /// `false` when the text only gave a day, so only the day is compared.
    let hasTime: Bool
    /// The sentence the date came from, word for word.
    let quote: String
    /// How it was extracted: `.none` (data detector) or `.onDevice` (model).
    let extractedBy: String
}

// MARK: - Model output

/// What the model fills in for one announcement.
@available(iOS 26.0, macOS 26.0, *)
@Generable
struct ExtractedDateClaims {
    @Guide(description: "Every date the announcement gives for an assignment, quiz, exam, project or event. Empty if there are none.")
    var claims: [ExtractedDateClaim]
}

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct ExtractedDateClaim {
    @Guide(description: "The assignment, quiz, exam, project or event the date is for, named as in the text, e.g. \"Project 2\".")
    var item: String

    @Guide(description: "The date it is due or happens, in ISO 8601 with the UTC offset from the instructions, e.g. 2026-10-30T23:59:00-04:00. Only the date, e.g. 2026-10-30, if no time is given.")
    var date: String

    @Guide(description: "The exact sentence from the announcement that gives the date, copied word for word.")
    var quote: String
}
