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
        enrollment?.grades?.current_score?.truncatingTrailingZeros ?? "--"
    }

    var currentGrade: String {
        enrollment?.grades?.current_grade ?? "--"
    }

    var finalScore: String {
        enrollment?.grades?.final_score?.truncatingTrailingZeros ?? "--"
    }

    var finalGrade: String {
        enrollment?.grades?.final_grade ?? "--"
    }

    var canvasURL: URL? {
        if let urlString = enrollment?.grades?.html_url {
            return URL(string: urlString)
        }

        return nil
    }

    let courseId: String

    init(courseId: String) {
        self.courseId = courseId
    }

    func getEnrollments(currentUserID: String?) async {
        guard let currentUserID = currentUserID?.asInt else {
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
                loadingMethod: .all(onNewPage: { enrollmentsBatch in
                    self.findEnrollment(
                        enrollments: enrollmentsBatch,
                        currentUserID: currentUserID
                    )
                })
            )

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
            DispatchQueue.main.async {
                self.enrollment = newEnrollment
            }
        }
    }

}
