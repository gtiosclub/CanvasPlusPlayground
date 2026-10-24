//
//  BriefingConflictsView.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/24/26.
//

import SwiftUI

/// Debug screen for the briefing's date check. The real cards come in #588; this shows the raw
/// report: conflicts, dates that agree, and dates that didn't match a record.
@available(iOS 26.0, macOS 26.0, *)
struct BriefingConflictsView: View {
    @Environment(CourseManager.self) private var courseManager
    @Environment(ToDoListManager.self) private var toDoListManager

    private var finder: BriefingConflictFinder { .shared }

    var body: some View {
        List {
            if let report = finder.report {
                Section {
                    LabeledContent("Last run", value: report.generatedAt.formatted(date: .abbreviated, time: .shortened))
                    if let tier = finder.lastTier {
                        LabeledContent("Extracted by", value: tier == .none ? "Data detector (no model)" : "On-device model")
                    }
                }

                Section {
                    if report.conflicts.isEmpty {
                        Text("No announcement disagrees with Canvas.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(report.conflicts) { conflict in
                        ConflictRow(conflict: conflict)
                    }
                } header: {
                    Text("Conflicts (\(report.conflicts.count))")
                } footer: {
                    Text("Canvas dates are never changed. Both sources are shown so the student can check.")
                }

                if !report.confirmations.isEmpty {
                    Section("Matches Canvas (\(report.confirmations.count))") {
                        ForEach(report.confirmations, id: \.self) { confirmation in
                            ClaimRow(
                                systemImage: "checkmark.circle.fill",
                                tint: .green,
                                title: confirmation.record.title,
                                claim: confirmation.claim
                            )
                        }
                    }
                }

                if !report.unmatched.isEmpty {
                    Section("No Matching Record (\(report.unmatched.count))") {
                        ForEach(report.unmatched, id: \.self) { claim in
                            ClaimRow(
                                systemImage: "questionmark.circle",
                                tint: .secondary,
                                title: claim.source.title,
                                claim: claim
                            )
                        }
                    }
                }
            }
        }
        .overlay {
            if finder.report == nil && !finder.isRunning {
                ContentUnavailableView(
                    "No Briefing Yet",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Run the date check to compare announcements with Canvas.")
                )
            } else if finder.isRunning {
                ProgressView("Reading announcements…")
            }
        }
        .navigationTitle("Briefing Dates")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Run Now", systemImage: "arrow.clockwise") {
                    Task {
                        await finder.run(source: source)
                    }
                }
                .disabled(finder.isRunning)
            }
        }
    }

    private var source: CanvasBriefingSource {
        CanvasBriefingSource(
            dataSource: CanvasCacheAgentDataSource(courseManager: courseManager, toDoListManager: toDoListManager)
        )
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct ConflictRow: View {
    let conflict: BriefingConflict

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(conflict.record.title)
                    .font(.headline)
                Spacer()
                if let course = conflict.record.facts.courseName {
                    Text(course)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    Text("Announcement")
                        .foregroundStyle(.secondary)
                    Text(conflict.claim.date.briefingText(hasTime: conflict.claim.hasTime))
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
                GridRow {
                    Text("Canvas")
                        .foregroundStyle(.secondary)
                    Text(conflict.recordDate.briefingText(hasTime: true))
                        .fontWeight(.semibold)
                }
            }
            .font(.subheadline)

            Text("“\(conflict.claim.quote)”")
                .font(.callout)
                .italic()
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                SourceChip(systemImage: "megaphone", text: conflict.claim.source.title)
                SourceChip(systemImage: "doc.text", text: conflict.record.id)
            }
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct ClaimRow: View {
    let systemImage: String
    let tint: Color
    let title: String
    let claim: BriefingDateClaim

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(claim.date.briefingText(hasTime: claim.hasTime))
                    .font(.caption)
                Text("“\(claim.quote)”")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

private struct SourceChip: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: .capsule)
    }
}

private extension Date {
    func briefingText(hasTime: Bool) -> String {
        hasTime
            ? formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
            : formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}
