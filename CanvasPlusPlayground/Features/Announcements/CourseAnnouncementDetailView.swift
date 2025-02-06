//
//  CourseAnnouncementDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/13/24.
//

import SwiftUI

struct CourseAnnouncementDetailView: View {
    @EnvironmentObject private var llmEvaluator: LLMEvaluator
    @EnvironmentObject private var intelligenceManager: IntelligenceManager

    @State private var loadingSummary = false

    let announcement: Announcement

    var body: some View {
        Form {
            Section {
                summarySection
            } header: {
                HStack {
                    Label("Summary", systemImage: "wand.and.stars")

                    Spacer()

                    if loadingSummary {
                        ProgressView()
                            .controlSize(.small)
                    } else if announcement.summary != nil {
                        Button("Summarize Again", systemImage: "arrow.clockwise") {
                            Task {
                                await summarize()
                            }
                        }
                        .disabled(loadingSummary)
                        .buttonStyle(.plain)
                        .tint(.accentColor)
                    }
                }
            } footer: {
                Group {
                    if let currentModelName = intelligenceManager.currentModelName {
                        Text("Using \(currentModelName)")
                    } else {
                        Text("Download and select a model to use intelligence features.")
                    }
                }
                .foregroundStyle(.secondary)
            }
            .disabled(intelligenceManager.currentModelName == nil)

            Section("Announcement Details") {
                HStack {
                    Text("Title")
                    Spacer()
                    Text(announcement.title ?? "NULL_TITLE")
                }

                HStack {
                    Text("Created At")
                    Spacer()
                    Text(announcement.createdAt?.formatted() ?? "NULL_DATE")
                }
            }

            Section("Announcement Message") {
                HTMLTextView(htmlText: announcement.message ?? "")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            announcement.isRead = true
        }
        .id(announcement.id)
    }

    private var summarySection: some View {
        Group {
            if let announcementSummary = announcement.summary {
                Text(announcementSummary)
                    .foregroundStyle(loadingSummary ? .secondary : .primary)
            } else {
                HStack {
                    Button("Summarize") {
                        Task {
                            await summarize()
                        }
                    }
                    .disabled(loadingSummary)
                }
            }
        }
    }

    func summarize() async {
        guard let title = announcement.title, let message = announcement.message else { return }

        print("title: \(title)")
        print("message: \(message)")

        let prompt = """
        Summarize the following announcement in a college course. Keep the summary to under three sentences. The title of the announcement is \(title). Only provide the summary text as a response and do not say anything else. Remove all surrouding text other than the summary. Give me only the text without any HTML tags, etc. This is the message:

        \(message)
        """

        if let modelName = intelligenceManager.currentModelName {
            loadingSummary = true
            announcement.summary = await llmEvaluator
                .generate(
                    modelName: modelName,
                    message: prompt,
                    systemPrompt: intelligenceManager.systemPrompt
                )
                .trimmingCharacters(in: .whitespacesAndNewlines)
            loadingSummary = false
        }
    }
}
