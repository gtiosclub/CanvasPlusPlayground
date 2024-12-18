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
    
    func getEnrollments(currentUserID: Int?) async {
        guard let currentUserID else {
            print("GradesViewModel: Current UserID is nil.")
            return
        }

        let request = CanvasRequest.getEnrollments(courseId: courseId)
        
        do {
            let enrollments: [Enrollment]? = try await CanvasService.shared.loadAndSync(request,
                onCacheReceive: { enrollmentsCache in
                    guard let enrollmentsCache else { return }

                    findEnrollment(
                        enrollments: enrollmentsCache,
                        currentUserID: currentUserID
                    )
                },
                onNewBatch: { enrollmentsBatch in
                    findEnrollment(
                        enrollments: enrollmentsBatch,
                        currentUserID: currentUserID
                    )
                })

            if let enrollments {
                findEnrollment(
                    enrollments: enrollments,
                    currentUserID: currentUserID
                )
            }
        } catch {
            print("Failed to fetch enrollments. \(error)")
        }
    }
    
    /// Searches for the users enrollment and sets it if found
    func findEnrollment(enrollments: [Enrollment], currentUserID: Int) {
        let newEnrollment = enrollments
            .first { $0.userID == currentUserID }

        if newEnrollment != nil {
            self.enrollment = newEnrollment
        }
    }

}
