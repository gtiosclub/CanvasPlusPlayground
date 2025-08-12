//
//  CanvasIntelligenceService.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 8/12/25.
//

import FoundationModels
import SwiftUI

@available(iOS 26.0, macOS 26.0, *)
@MainActor
@Observable
final class CanvasIntelligenceService {
    enum IntelligenceServiceError: Error {
        case announcementDetailsMissing
    }

    private var session: LanguageModelSession

    init() {
        self.session = LanguageModelSession {
            """
            You are an intelligent assistant in an app called Canvas Plus, \
            an app for students using the Canvas LMS.
            """

            """
            Your role is to help students efficiently access their course materials, \
            summarize content like announcements, and extract important \
            information such as assignment details and grades.
            """

            """
            Always provide clear, concise, and actionable responses tailored to \
            student academic workflows. Avoid extraneous information and prioritize \
            usefulness for course, assignment, and grade-related queries.
            """
        }

        session.prewarm()
    }

    func summarizeAnnouncement(_ announcement: DiscussionTopic) async throws -> String {
        guard let title = announcement.title, let message = announcement.message else {
            throw IntelligenceServiceError.announcementDetailsMissing
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
