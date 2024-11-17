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
        let announcements: [Announcement]? = try? await CanvasService.shared.defaultAndFetch(
            .getAnnouncements(courseId: courseId),
            onCacheReceive: { (cached: [Announcement]?) in
                guard let cached else { return }
                
                self.announcements = cached.sorted(by: { 
                    ($0.createdAt ?? Date()) > ($1.createdAt ?? Date())
                })
            },
            onNewBatch: { batch in                
                for announcement in batch {
                    if !self.announcements.contains(announcement) {
                        self.announcements.insert(announcement, at: 0)
                    }
                }
                
            }
        )
        
        guard let announcements else {
            print("Failed to fetch announcements.")
            return
        }
        
        self.announcements = announcements
        
    }
}
