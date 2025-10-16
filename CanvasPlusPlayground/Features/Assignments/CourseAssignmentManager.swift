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
        let request = CanvasRequest.getAssignmentGroups(courseId: courseID)

        do {
            let groups = try await CanvasService.shared.loadAndSync(
                request,
                onCacheReceive: { cachedGroups in
                    guard let cachedGroups else { return }

                    self.assignmentGroups = cachedGroups.sorted(by: { $0.position < $1.position })
                    Task { @MainActor in
                        WidgetContext.shared.requestToRefreshWidgets(in: .assignments)
                    }
                }
            )

            let sortedGroups = groups.sorted(by: { $0.position < $1.position })

            if sortedGroups != self.assignmentGroups {
                self.assignmentGroups = sortedGroups
                await MainActor.run {
                    WidgetContext.shared.requestToRefreshWidgets(in: .assignments)
                }
            }
        } catch {
            LoggerService.main.error("Failed to fetch assignment groups")
        }
    }
}
