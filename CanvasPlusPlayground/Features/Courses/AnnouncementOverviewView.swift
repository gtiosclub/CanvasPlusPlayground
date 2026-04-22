//
//  AnnouncementOverviewView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 4/20/26.
//


import SwiftUI

struct AnnouncementOverviewView: View {
    @Environment(NavigationModel.self) private var navigationModel

    let course: Course

    @State private var announcementManager: CourseAnnouncementManager

    init(course: Course) {
        self.course = course
        self._announcementManager = State(initialValue: CourseAnnouncementManager(course: course))
    }

    // MARK: - Data

    private var recentAnnouncements: [DiscussionTopic] {
        Array(announcementManager.displayedAnnouncements.prefix(3))
    }

    /// Groups the top-3 announcements by calendar month, preserving newest-first order within each group.
    private var groupedByMonth: [(label: String, announcements: [DiscussionTopic])] {
        var seen: [String: [DiscussionTopic]] = [:]
        var order: [String] = []

        for announcement in recentAnnouncements {
            let label = sectionLabel(for: announcement.date)
            if seen[label] == nil {
                seen[label] = []
                order.append(label)
            }
            seen[label]!.append(announcement)
        }

        return order.map { label in (label: label, announcements: seen[label]!) }
    }

    private func sectionLabel(for date: Date?) -> String {
        guard let date else { return "Recent" }
        if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month) {
            return "This Month"
        }
        return date.formatted(.dateTime.month(.wide))
    }

    // MARK: - Body

    var body: some View {
        Group {
            if recentAnnouncements.isEmpty {
                Text("No announcements")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)
                    .padding(.leading, 4)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(groupedByMonth, id: \.label) { group in
                        announcementSection(label: group.label, announcements: group.announcements)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .task {
            await announcementManager.fetchAnnouncements()
        }
        .onChange(of: course.id) {
            announcementManager = CourseAnnouncementManager(course: course)
            Task { await announcementManager.fetchAnnouncements() }
        }
    }

    // MARK: - Section

    @ViewBuilder
    private func announcementSection(label: String, announcements: [DiscussionTopic]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 22, weight: .semibold))

            VStack(spacing: 8) {
                ForEach(announcements) { announcement in
                    announcementCard(announcement)
                }
            }
        }
    }

    // MARK: - Card

    @ViewBuilder
    private func announcementCard(_ announcement: DiscussionTopic) -> some View {
        Button {
            navigationModel.push(.announcement(announcement))
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Left: title + body preview
                VStack(alignment: .leading, spacing: 4) {
                    Text(announcement.title ?? "")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(
                        announcement.message?
                            .stripHTML()
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        ?? ""
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: date + author circle
                VStack(alignment: .trailing, spacing: 8) {
                    if let date = announcement.date {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    authorCircle(for: announcement)
                }
                .frame(width: 44)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(height: 88)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .clipped()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Author Circle

    @ViewBuilder
    private func authorCircle(for announcement: DiscussionTopic) -> some View {
        let name = announcement.author?.display_name ?? announcement.userName ?? "?"
        let initial = String(name.first.map(String.init) ?? "?").uppercased()

        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 32, height: 32)

            Text(initial)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }
}
