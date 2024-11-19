//
//  CourseAnnouncementManager.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/12/24.
//

import Foundation

@Observable class CourseAnnouncementManager {
    let course: Course
    var courseId: String { course.id }
    var announcements: [Announcement]
    
    init(course: Course) {
        self.course = course
        self.announcements = []
    }
    
    func fetchAnnouncements() async {
        
        let endDate = Date.now
        let startDate = endDate.addingTimeInterval(-1 * 60 * 60 * 24 * 30 * 5)
        
        let announcements: [Announcement]? = try? await CanvasService.shared.defaultAndFetch(
            .getAnnouncements(courseId: courseId, startDate: startDate, endDate: endDate),
            onCacheReceive: { (cached: [Announcement]?) in
                guard let cached else { return }
                
                self.announcements = cached.sorted(by: { 
                    ($0.createdAt ?? Date()) > ($1.createdAt ?? Date())
                })
            }
        )
        
        guard let announcements else {
            print("Failed to fetch announcements.")
            return
        }
        
        self.announcements = announcements
        
    }
}
