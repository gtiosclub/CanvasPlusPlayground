//
//  IntelligenceServiceProvider+SystemPrompt.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 8/15/25.
//

import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
extension IntelligenceServiceProvider {
    func setup() {
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

        session?.prewarm()
    }
}
