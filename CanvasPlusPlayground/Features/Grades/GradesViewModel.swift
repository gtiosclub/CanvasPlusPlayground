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
            LoggerService.main.error("GradesViewModel: Current UserID is nil.")
            return
        }

        if AppEnvironment.isSandbox {
            verifyAndSetEnrollment(SandboxData.dummyEnrollment, currentUserID: currentUserID)
            return
        }

        let request = CanvasRequest.getEnrollments(
            courseId: courseId,
            userId: currentUserID.asString
        )

        do {
            let enrollments: [Enrollment]? = try await CanvasService.shared.loadAndSync(
                request,
                onCacheReceive: { enrollmentsCache in
                    guard let enrollmentsCache else { return }

                    verifyAndSetEnrollment(
                        enrollmentsCache.first,
                        currentUserID: currentUserID
                    )
                },
                loadingMethod: .all(onNewPage: { enrollmentsBatch in
                    self.verifyAndSetEnrollment(
                        enrollmentsBatch.first,
                        currentUserID: currentUserID
                    )
                })
            )

            verifyAndSetEnrollment(
                enrollments?.first,
                currentUserID: currentUserID
            )
        } catch {
            LoggerService.main.error("Failed to fetch enrollments. \(error)")
        }
    }

    /// Searches for the users enrollment and sets it if found
    func verifyAndSetEnrollment(_ enrollment: Enrollment?, currentUserID: Int) {
        guard let enrollment, enrollment.userID == currentUserID else {
            LoggerService.main.error("GradesVM: Enrollment did not match.")
            return
        }

        self.enrollment = enrollment
    }
}
