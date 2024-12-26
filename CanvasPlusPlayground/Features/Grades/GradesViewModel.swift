//
//  GradesViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/13/24.
//

import Foundation

@Observable
class GradesViewModel {
    private var enrollment: Enrollment?

    var currentScore: String {
        enrollment?.grades?.currentScore?.truncatingTrailingZeros ?? "--"
    }

    var currentGrade: String {
        enrollment?.grades?.currentGrade ?? "--"
    }

    var finalScore: String {
        enrollment?.grades?.finalScore?.truncatingTrailingZeros ?? "--"
    }

    var finalGrade: String {
        enrollment?.grades?.finalGrade ?? "--"
    }

    var canvasURL: URL? {
        if let urlString = enrollment?.grades?.htmlURL {
            return URL(string: urlString)
        }

        return nil
    }

    let courseId: String
    
    init(courseId: String) {
        self.courseId = courseId
    }
    
    func getEnrollments(currentUserID: Int?) async {
        guard let currentUserID else {
            print("GradesViewModel: Current UserID is nil.")
            return
        }

        let request = CanvasRequest.getEnrollments(
            courseId: courseId,
            userId: currentUserID
        )

        do {
            let enrollments: [Enrollment]? = try await CanvasService.shared.loadAndSync(request,
                onCacheReceive: { enrollmentsCache in
                    guard let enrollmentsCache else { return }

                    setEnrollment(
                        enrollments: enrollmentsCache,
                        currentUserID: currentUserID
                    )
                },
                onNewBatch: { enrollmentsBatch in
                    setEnrollment(
                        enrollments: enrollmentsBatch,
                        currentUserID: currentUserID
                    )
                })

            if let enrollments {
                setEnrollment(
                    enrollments: enrollments,
                    currentUserID: currentUserID
                )
            }
        } catch {
            print("Failed to fetch enrollments. \(error)")
        }
    }
    
    /// Sets user enrollment if found.
    private func setEnrollment(enrollments: [Enrollment], currentUserID: Int) {
        guard enrollments.count == 1,
                let first = enrollments.first,
                first.userID == currentUserID else {
            return
        }

        DispatchQueue.main.async {
            self.enrollment = first
        }
    }

}
