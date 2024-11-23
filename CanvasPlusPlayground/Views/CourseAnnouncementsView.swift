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
    
    init(course: Course) {
        self.course = course
        self.announcementManager = CourseAnnouncementManager(course: course)
    }
    
    var body: some View {
        NavigationStack {
            List(announcementManager.announcements, id:\.id) { announcement in
                NavigationLink {
                    CourseAnnouncementDetailView(announcement: announcement)
                        .task {
                            await announcement.update(keypath: \.isRead, value: true)
                        }
                } label: {
                    HStack {
                        Text(announcement.title ?? "")
                        Spacer()
                        if !(announcement.isRead ?? false) {
                            Circle()
                                .fill(.tint)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
            }
            .overlay {
                if (announcementManager.announcements.count == 0) {
                    ContentUnavailableView("No announcements available within last 14 days", systemImage: "exclamationmark.bubble.fill")
                } else {
                    EmptyView()
                }

            }
            .task {
                await announcementManager.fetchAnnouncements()
            }
            .navigationTitle("Announcements")
        }
    }
}

