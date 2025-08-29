//
//  AnnouncementSummaryService.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 8/12/25.
//

import FoundationModels
import SwiftUI

@available(iOS 26.0, macOS 26.0, *)
@MainActor
@Observable
final class AnnouncementSummaryService: IntelligenceServiceProvider {
    typealias Input = DiscussionTopic
    typealias Output = String

    enum AnnouncementSummaryServiceError: Error {
        case announcementDetailsMissing
    }

    var session: LanguageModelSession?

    init() {
        setup()
    }

    func performRequest(for announcement: DiscussionTopic) async throws -> String {
        guard let session else {
            throw IntelligenceServiceError.sessionNotAvailable
        }

        guard let title = announcement.title, let message = announcement.message else {
            throw AnnouncementSummaryServiceError.announcementDetailsMissing
        }

        let response = try await session.respond {
            "Summarize the following announcement in a college course."

            """
            Summaries should extract the key details of the announcement, such \
            as locations, timings, to-do tasks, and other time-sensitive information.
            """

            "Avoid saying things like 'this announcement is...', etc."

            "Avoid multiple paragraphs."

            """
            Important: Only provide the summary text as a response and \
            do not say anything else. Keep the summary to under two sentences.
            """

            """
            Do not include any HTML tags along with the summary. Just include \
            the text as is.
            """

            """
            The title of the announcement is \(title).
            The message of the announcement is as follows:

            \(message)
            """
        }

        return response.content
    }
}
