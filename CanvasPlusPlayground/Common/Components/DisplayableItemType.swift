//
//  DisplayableItemType.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 9/13/25.
//


import Foundation

enum DisplayableItemType : String {
    case quiz
    case assignment
    var displayTitle : String {
        switch self {
        case .quiz:
            return "Quiz"
        case .assignment:
            return "Assignment"
        }
    }
}
// A protocol that defines common properties for items between quizzes and assignments(for now)
protocol DisplayableItemDetails {
    var displayName: String { get }
    var itemType: DisplayableItemType { get }

    var unlockDate: Date? { get }
    var dueDate: Date? { get }
    var lockDate: Date? { get }
    var pointsPossibleDisplay: String { get }
    var descriptionHTML: String? { get }
}

extension CanvasSchemaV1.Quiz: DisplayableItemDetails {
    var displayName: String { self.title }
    var itemType: DisplayableItemType { .quiz }
    var descriptionHTML: String? { self.details }

    var unlockDate: Date? { self.unlockAt }
    var dueDate: Date? { self.dueAt }
    var lockDate: Date? { self.lockAt }


    var pointsPossibleDisplay: String {
        guard let points = self.pointsPossible else { return "N/A" }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: points)) ?? "\(points)"
    }
}


extension CanvasSchemaV1.Assignment: DisplayableItemDetails {

    // These properties map directly to existing ones on your model.
    var displayName: String { self.name }
    var itemType: DisplayableItemType { .assignment }
    var descriptionHTML: String? { self.assignmentDescription }

    var pointsPossibleDisplay: String { self.formattedPointsPossible }
}
