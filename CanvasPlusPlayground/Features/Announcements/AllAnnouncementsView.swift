//
//  AllAnnouncementsView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/19/25.
//

import SwiftUI

struct AllAnnouncementsView: View {
    @Environment(CourseManager.self) private var courseManager

    @State private var announcementsManager = AllAnnouncementsManager()
    @State private var selectedAnnouncement: AllAnnouncementsManager.CourseAnnouncement?
    @State private var isLoadingAnnouncements = false

    var body: some View {
        List(selection: $selectedAnnouncement) {
            ForEach(announcementsManager.displayedAnnouncements, id: \.id) { courseAnnouncement in
                NavigationLink(value: courseAnnouncement) {
                    AnnouncementRow(
                        course: courseAnnouncement.course,
                        announcement: courseAnnouncement.announcement,
                        showCourseName: true
                    )
                }
            }
        }
        .navigationTitle("All Announcements")
        .navigationDestination(item: $selectedAnnouncement) { courseAnnouncement in
            CourseAnnouncementDetailView(announcement: courseAnnouncement.announcement)
        }
        .statusToolbarItem("Announcements", isVisible: isLoadingAnnouncements)
        .task {
            await loadAnnouncements()
        }
        .refreshable {
            await loadAnnouncements()
        }
        .onChange(of: courseManager.allCourses) { _, _ in
            Task {
                await loadAnnouncements()
            }
        }
    }

    private func loadAnnouncements() async {
        isLoadingAnnouncements = true
        await announcementsManager
            .fetchAnnouncements(courses: courseManager.userCourses)
        isLoadingAnnouncements = false
    }
}
