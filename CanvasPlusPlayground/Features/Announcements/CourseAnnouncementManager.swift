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
        let announcements: [Announcement]? = try? await CanvasService.shared.loadAndSync(
            CanvasRequest.getAnnouncements(courseId: courseId),
            onCacheReceive: { (cached: [Announcement]?) in
                guard let cached else { return }
                
                setAnnouncements(cached)
            }
        )
        
        guard let announcements else {
            print("Failed to fetch announcements.")
            return
        }
        
        setAnnouncements(announcements.reversed()) 
    }
    
    func setAnnouncements(_ announcements: [Announcement]) {
        self.announcements = announcements
    }
    
}
