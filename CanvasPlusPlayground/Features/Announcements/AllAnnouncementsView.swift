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
    @State private var selectedAnnouncement: Announcement?
    @State private var isLoadingAnnouncements = false

    var body: some View {
        List(selection: $selectedAnnouncement) {
            ForEach(announcementsManager.announcements) { announcement in
                NavigationLink {
                    CourseAnnouncementDetailView(announcement: announcement)
                } label: {
                    AnnouncementRow(
                        course: announcement.course,
                        announcement: announcement,
                        showCourseName: true
                    )
                }
            }
        }
        .navigationTitle("All Announcements")
        .statusToolbarItem("Announcements", isVisible: isLoadingAnnouncements)
        .task {
            isLoadingAnnouncements = true
            await announcementsManager
                .fetchAnnouncements(courses: courseManager.courses)
            isLoadingAnnouncements = false
        }
    }
}
