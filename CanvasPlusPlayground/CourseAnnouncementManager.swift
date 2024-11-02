//
//  CourseAnnouncementManager.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/12/24.
//

import Foundation

@Observable class CourseAnnouncementManager {
    let courseId: Int?
    var announcements: [Announcement]
    
    init(courseId: Int?) {
        self.courseId = courseId
        self.announcements = []
    }
    
    func fetchAnnouncements() async {
        guard let courseId, let (data, _) = try? await CanvasService.shared.fetchResponse(.getAnnouncements(courseId: courseId)) else {
            print("Failed to fetch announcements.")
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        
        if let announcements = try? decoder.decode([Announcement].self, from: data) {
            self.announcements = announcements
        } else {
            print("Failed to decode file data.")
        }
    }
}
