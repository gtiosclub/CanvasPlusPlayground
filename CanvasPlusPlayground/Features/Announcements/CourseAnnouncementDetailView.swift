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
            summarySection
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            #else
            // Workaround to get a clear background in a Form on macOS
            Section { } header: {
                summarySection
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
        .openInCanvasWebToolbarButton(.announcement(announcement.courseId ?? "", announcement.id))
        .id(announcement.id)
    }

    private var summarySection: some View {
        Group {
            if #available(iOS 26.0, macOS 26.0, *) {
                SummarySection(announcement: announcement)
            } else {
                EmptyView()
            }
        }
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

@available(iOS 26.0, macOS 26.0, *)
private struct SummarySection: View {
    @Environment(NavigationModel.self) private var navigationModel

    let announcement: DiscussionTopic

    @State private var loadingSummary = false
    @State private var rippleView = false

    @State private var announcementSummaryService: AnnouncementSummaryService?

    var body: some View {
        VStack {
            IntelligenceContentView(
                condition: rippleView,
                isOutline: announcement.summary != nil
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    mainBody
                }
                .foregroundStyle(
                    announcement.summary == nil ? .white : .primary
                )
                .frame(maxWidth: .infinity)
                .padding(8)
            }

            HStack {
                Spacer()

                if loadingSummary {
                    ProgressView()
                        .controlSize(.small)
                }

                Group {
                    Button("Summarize" + (announcement.summary != nil ? " Again" : "")) {
                        Task {
                            await summarize()
                        }
                    }
                    .disabled(
                        loadingSummary || !IntelligenceSupport.isModelAvailable
                    )
                }
                #if os(macOS)
                // The Button would otherwise be bold since it's in a
                // Section header
                .fontWeight(.regular)
                #endif
            }
        }
        .animation(.default, value: announcement.summary != nil)
        .onChange(of: announcement.summary) { _, _ in
            rippleView.toggle()
        }
        .task {
            announcementSummaryService = AnnouncementSummaryService()
        }
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
            Text(description)
                .font(.caption)
        }
    }

    private var description: String {
        if IntelligenceSupport.isModelAvailable {
            "Summarize this announcement using on-device intelligence."
        } else {
            IntelligenceSupport.modelAvailabilityDescription
        }
    }

    private func summarize() async {
        LoggerService.main.debug("Summarizing announcement...")

        loadingSummary = true
        // FIXME: Show error alert in case of failure.
        announcement.summary = try? await announcementSummaryService?
            .performRequest(for: announcement)
        loadingSummary = false
    }
}
