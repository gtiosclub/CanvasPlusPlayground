//
//  DisplayableItemDetails.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 9/9/25.
//


import Foundation

// A protocol that defines common properties for items between quizzes and assignments(for now)
protocol DisplayableItemDetails {
    var displayName: String { get }
    var itemType: String { get } // e.g., "Quiz" or "Assignment"
    var unlockDate: Date? { get }
    var dueDate: Date? { get }
    var lockDate: Date? { get }
    var pointsPossibleDisplay: String { get }
    var descriptionHTML: String? { get }
}

extension CanvasSchemaV1.Quiz: DisplayableItemDetails {


    var displayName: String { self.title }
    var itemType: String { "Quiz" }
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
    var itemType: String { "Assignment" }
    var descriptionHTML: String? { self.assignmentDescription }

    // Your model already has computed properties for Date objects and formatted points,
    // so we can use them directly! This is very clean.
    var pointsPossibleDisplay: String { self.formattedPointsPossible }

    // Note: The protocol requires `unlockDate`, `dueDate`, and `lockDate`.
    // Your `Assignment` model already provides these exact computed properties,
    // so no extra work is needed. The conformance is automatic.
}
