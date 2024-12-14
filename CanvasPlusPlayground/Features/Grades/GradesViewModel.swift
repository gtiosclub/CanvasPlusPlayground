//
//  GradesViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/13/24.
//

import Foundation

@Observable
class GradesViewModel {
    var enrollment: Enrollment?
    
    let courseId: String
    
    init(courseId: String) {
        self.courseId = courseId
    }
    
    func getEnrollments() async {
        let request = CanvasRequest.getPeople(courseId: courseId)
        
        do {
            if let enrollments: [Enrollment] = try? await CanvasService.shared.load(request), findEnrollment(enrollments: enrollments) {
                return
            }
            
            if self.enrollment == nil {
                try await CanvasService.shared.syncWithAPI(request, onNewBatch: { (enrollments: [Enrollment]) in
                    findEnrollment(enrollments: enrollments)
                })
            }
            
        } catch {
            print("Failed to fetch enrollments. \(error)")
        }
    }
    
    /// Searches for the users enrollment and sets it if found
    @discardableResult
    func findEnrollment(enrollments: [Enrollment]) -> Bool {
        for enrollment in enrollments {
            if enrollment.courseID?.asString == courseId {
                DispatchQueue.main.sync {
                    self.enrollment = enrollment
                }
                return true
            }
        }
        
        return false
    }

}
