//
//  CourseAnnouncementDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/13/24.
//

import SwiftUI

struct CourseAnnouncementDetailView: View {
    let announcement: DiscussionTopic

    var body: some View {
        Form {
            #if os(iOS)
            SummarySection(announcement: announcement)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            #else
            // Workaround to get a clear background in a Form on macOS
            Section { } header: {
                SummarySection(announcement: announcement)
                    .multilineTextAlignment(.leading)
            } footer: {
                Text("")
            }
            #endif

            Section("Announcement Details") {
                HStack {
                    Text("Title")
                    Spacer()
                    Text(announcement.title ?? "NULL_TITLE")
                }

                HStack {
                    Text("Created At")
                    Spacer()
                    Text(announcement.date?.formatted() ?? "NULL_DATE")
                }
            }

            Section("Announcement Message") {
                HTMLTextView(htmlText: announcement.message ?? "")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            // dont use `.task` so that this Task outlives its view upon disappear
            markAsRead()
        }
        .id(announcement.id)
    }

    func markAsRead() {
        Task { @MainActor in
            do {
                try await announcement.markReadStatus(true)
            } catch {
                LoggerService.main.error("Failure marking as read:\n \(error)")
            }
        }
    }
}

private struct SummarySection: View {
    @Namespace private var namespace

    @EnvironmentObject private var llmEvaluator: LLMEvaluator
    @EnvironmentObject private var intelligenceManager: IntelligenceManager

    let announcement: DiscussionTopic

    @State private var loadingSummary = false
    @State private var startTime = Date.now

    private let colors: [Color] = IntelligenceManager.gradientColors

    var body: some View {
        VStack {
            RippleView(condition: announcement.summary != nil) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    mainBody
                }
                .foregroundStyle(
                    announcement.summary == nil ? .white : .primary
                )
                .frame(maxWidth: .infinity)
                .padding(8)
                .background {
                    cardBackground
                }
            }

            HStack {
                Spacer()

                if loadingSummary {
                    ProgressView()
                        .controlSize(.small)
                }

                Button("Summarize" + (announcement.summary != nil ? " Again" : "")) {
                    Task {
                        await summarize()
                    }
                }
                .disabled(loadingSummary)
                #if os(macOS)
                // The Button would otherwise be bold since it's in a
                // Section header
                .fontWeight(.regular)
                #endif
            }
        }
        .disabled(intelligenceManager.currentModelName == nil)
        .animation(.default, value: announcement.summary != nil)
    }

    private var header: some View {
        HStack {
            Label("Summary", systemImage: "wand.and.stars")

            Spacer()
        }
        .bold()
    }

    @ViewBuilder
    private var mainBody: some View {
        if let summary = announcement.summary {
            Text(summary)
                .foregroundStyle(loadingSummary ? .secondary : .primary)
        } else {
            Text("Summarize this announcement using on-device intelligence.")
                .font(.caption)
        }
    }

    private var cardBackground: some View {
        TimelineView(.animation) { _ in
            let elapsedTime = startTime.distance(to: Date.now)

            if announcement.summary == nil {
                RoundedRectangle(cornerRadius: 8.0)
                    .fill(
                        .animatedGradient(
                            time: elapsedTime,
                            colors: colors
                        )
                    )
                    .matchedGeometryEffect(id: "background", in: namespace)
            } else {
                RoundedRectangle(cornerRadius: 8.0)
                    .strokeBorder(
                        .animatedGradient(
                            time: elapsedTime,
                            colors: colors
                        ),
                        lineWidth: 2.0
                    )
                    .matchedGeometryEffect(id: "background", in: namespace)
            }
        }
    }

    private func summarize() async {
        guard let title = announcement.title, let message = announcement.message else { return }

        LoggerService.main.debug("title: \(title)")
        LoggerService.main.debug("message: \(message)")

        let prompt = """
        Summarize the following announcement in a college course. Keep the summary to under three sentences.
        The title of the announcement is \(title). Only provide the summary text as a response and do not say anything else.
        Remove all surrouding text other than the summary. Give me only the text without any HTML tags, etc. This is the message:

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
