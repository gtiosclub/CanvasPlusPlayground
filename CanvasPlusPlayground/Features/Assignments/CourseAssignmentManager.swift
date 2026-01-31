//
//  CourseAssignmentManager.swift
//  CanvasPlusPlayground
//
//  Created by Sankaet Cheemalamarri on 9/14/24.
//

import SwiftUI

@Observable
class CourseAssignmentManager {
    enum GroupMode: String, CaseIterable {
        case type
        case dueDate

        var rawValue: String {
            switch self {
            case .type:
                "Type"
            case .dueDate:
                "Due Date"
            }
        }
    }

    private let courseID: String
    var assignmentGroups = [AssignmentGroup]()

    var allAssignments: [AssignmentAPI] {
        assignmentGroups.flatMap {
            $0.assignments ?? []
        }
    }

    init(courseID: String) {
        self.courseID = courseID
    }

    func fetchAssignmentGroups() async {
        if AppEnvironment.isSandbox {
            self.assignmentGroups = SandboxData.dummyAssignmentGroups
            return
        }
        let request = CanvasRequest.getAssignmentGroups(courseId: courseID)

        do {
            let groups = try await CanvasService.shared.loadAndSync(
                request,
                onCacheReceive: { cachedGroups in
                    guard let cachedGroups else { return }

                    self.assignmentGroups = cachedGroups.sorted(by: { $0.position < $1.position })
                }
            )

            self.assignmentGroups = groups.sorted(by: { $0.position < $1.position })
        } catch {
            LoggerService.main.error("Failed to fetch assignment groups")
        }
    }
}
