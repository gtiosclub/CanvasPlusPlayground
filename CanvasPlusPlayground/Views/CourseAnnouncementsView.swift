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
        self.announcementManager = CourseAnnouncementManager(courseId: course.id)
    }
    
    
    var body: some View {
        ZStack {
            List(announcementManager.announcements, id:\.id) { announcment in
                NavigationLink {
                    CourseAnnouncementDetailView(announcement: announcment)
                } label: {
                    Text(announcment.title ?? "")
                }
            }
            if (announcementManager.announcements.count == 0) {
                Text("No announcements available within last 14 days")
                    .font(.subheadline)
            }
        }
        
        .task {
            await announcementManager.fetchAnnouncements()
        }
        .navigationTitle(course.name ?? "")
    }
}

