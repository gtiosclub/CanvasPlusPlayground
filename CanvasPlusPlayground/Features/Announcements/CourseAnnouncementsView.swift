//
//  CourseAnnouncementsView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/13/24.
//

import SwiftUI

struct CourseAnnouncementsView: View {
    let course: Course
    @State private var announcementManager: CourseAnnouncementManager
    @State private var selectedAnnouncement: DiscussionTopic?
    @State private var isLoadingAnnouncements: Bool = true

    init(course: Course) {
        self.course = course
        self.announcementManager = CourseAnnouncementManager(course: course)
    }

    var body: some View {
        List(announcementManager.displayedAnnouncements, id: \.id, selection: $selectedAnnouncement) { announcement in
            NavigationLink(value: announcement) {
                AnnouncementRow(course: course, announcement: announcement)
            }
            .tint(course.rgbColors?.color)
        }
        .overlay {
            if announcementManager.announcements.isEmpty {
                ContentUnavailableView("No announcements available", systemImage: "exclamationmark.bubble.fill")
            } else {
                EmptyView()
            }
        }
        .task {
            await loadAnnouncements()
        }
        .refreshable {
            await loadAnnouncements()
        }
        .statusToolbarItem(
            "Announcements",
            isVisible: isLoadingAnnouncements
        )
        .navigationTitle("Announcements")
        .navigationDestination(item: $selectedAnnouncement) { announcement in
            CourseAnnouncementDetailView(announcement: announcement)
        }
        .pickedItem(selectedAnnouncement)
    }

    private func loadAnnouncements() async {
        isLoadingAnnouncements = true
        await announcementManager.fetchAnnouncements()
        isLoadingAnnouncements = false
    }
}
