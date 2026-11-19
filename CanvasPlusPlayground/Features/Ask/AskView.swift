//
//  AskView.swift
//  CanvasPlusPlayground
//

import SwiftUI

/// Ask a question about a course (or all courses) and get one answer card with source chips.
/// Follow-ups revise the card; the scrubber steps back through earlier versions.
@available(iOS 26.0, macOS 26.0, *)
struct AskView: View {
    @Environment(\.dismiss) private var dismiss

    let course: Course?
    let initialQuestion: String?

    @State private var session: AskSession
    @State private var draft = ""
    @FocusState private var isFieldFocused: Bool

    init(course: Course? = nil, initialQuestion: String? = nil) {
        self.course = course
        self.initialQuestion = initialQuestion
        _session = State(initialValue: AskSession(
            courseID: course?.id,
            retrieve: AskRetrieval.live(),
            fallbackResolver: nil
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let revision = session.current {
                        AnswerCard(revision: revision, onOpen: open)

                        if session.revisions.count > 1 {
                            RevisionScrubber(count: session.revisions.count, selection: $session.selectedRevision)
                        }

                        if revision.shouldOfferCloud {
                            CloudOffer(isReady: session.isCloudReady) {
                                Task { await session.tryWithCloud() }
                            }
                        }
                    } else if session.state == .idle {
                        intro
                    }

                    if case .failed(let message) = session.state {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: 680, alignment: .leading)
                .frame(maxWidth: .infinity)
            }

            Divider()
            inputBar
        }
        .navigationTitle(course.map { "Ask \($0.displayName)" } ?? "Ask Your Courses")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if !session.revisions.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Question", systemImage: "square.and.pencil") {
                        session.startOver()
                        isFieldFocused = true
                    }
                }
            }
        }
        .task {
            if let initialQuestion, session.revisions.isEmpty {
                await session.ask(initialQuestion)
            } else {
                isFieldFocused = true
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ask about deadlines, policies or anything in your course materials.")
                .font(.headline)
            Text("Answers come from your synced course content and cite where they came from. Everything runs on this device unless you choose to try the cloud.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField(session.revisions.isEmpty ? "Ask a question" : "Ask a follow-up", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($isFieldFocused)
                .onSubmit(submit)
                .disabled(session.state == .thinking)

            if session.state == .thinking {
                ProgressView().controlSize(.small)
            } else {
                Button("Ask", systemImage: "arrow.up.circle.fill", action: submit)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(12)
    }

    private func submit() {
        let question = draft
        draft = ""
        Task { await session.ask(question) }
    }

    /// Opens a cited record through the app's deep-link path, closing this view first.
    private func open(_ evidence: Evidence) {
        guard let link = AskRetrieval.deepLink(for: evidence) else { return }
        dismiss()
        NotificationCenter.default.post(
            name: .openSpotlightDeepLink,
            object: nil,
            userInfo: [SpotlightDeepLinkUserInfoKey.identifier: link]
        )
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct AnswerCard: View {
    let revision: AskRevision
    let onOpen: (Evidence) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(revision.question)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if revision.sentences.isEmpty {
                Text(revision.sources.isEmpty
                     ? "Nothing in your synced course content matches that yet."
                     : "Couldn't find an answer the sources support.")
                    .foregroundStyle(.secondary)
            }

            if revision.isExtractive {
                Text("Here's what your course materials say:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(revision.sentences) { sentence in
                VStack(alignment: .leading, spacing: 6) {
                    Text(revision.isExtractive ? "“\(sentence.text)”" : sentence.text)
                    ChipRow(evidence: sentence.evidence, onOpen: onOpen)
                }
            }

            footer
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: revision.tier == .cloud ? "cloud" : "iphone")
            Text(tierText)
            if revision.droppedCount > 0 {
                Text("· \(revision.droppedCount) unsupported \(revision.droppedCount == 1 ? "sentence" : "sentences") hidden")
            }
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }

    private var tierText: String {
        switch revision.tier {
        case .cloud: "Answered with Gemini"
        case .onDevice: "Answered on this device"
        case .none: "No model on this device"
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct ChipRow: View {
    let evidence: [Evidence]
    let onOpen: (Evidence) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(evidence) { item in
                    Button {
                        onOpen(item)
                    } label: {
                        Label(item.title, systemImage: icon(for: item))
                            .font(.caption)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.tint.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(AskRetrieval.deepLink(for: item) == nil)
                    .accessibilityHint("Opens the source")
                }
            }
        }
    }

    private func icon(for item: Evidence) -> String {
        switch item.ref.kind {
        case .assignment: "doc.text"
        case .announcement: "megaphone"
        case .file: "doc"
        case .calendarEvent: "calendar"
        case .course: "book"
        case .toDo: "checklist"
        case .passage: "text.quote"
        }
    }
}

private struct RevisionScrubber: View {
    let count: Int
    @Binding var selection: Int

    var body: some View {
        HStack {
            Button("Earlier", systemImage: "chevron.left") { selection = max(selection - 1, 0) }
                .disabled(selection == 0)
            Spacer()
            Text("Version \(selection + 1) of \(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Later", systemImage: "chevron.right") { selection = min(selection + 1, count - 1) }
                .disabled(selection == count - 1)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
    }
}

private struct CloudOffer: View {
    let isReady: Bool
    let onTry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Couldn't work this out on-device.")
                .font(.subheadline.weight(.semibold))
            if isReady {
                Button("Try with Cloud?", systemImage: "cloud", action: onTry)
                    .buttonStyle(.borderedProminent)
                Text("Sends this question and its sources to Gemini with your key. Names and emails are removed first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Turn on Cloud Intelligence in Settings to try a cloud model.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}
