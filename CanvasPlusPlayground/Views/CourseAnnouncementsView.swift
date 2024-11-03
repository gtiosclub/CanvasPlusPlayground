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
        self.announcementManager = CourseAnnouncementManager(courseId: course.id.asInt)
    }
    
    
    var body: some View {
        NavigationStack {
            List(announcementManager.announcements, id:\.id) { announcment in
                NavigationLink {
                    CourseAnnouncementDetailView(announcement: announcment)
                } label: {
                    Text(announcment.title ?? "")
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

