//
//  PickerService.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/21/25.
//

import SwiftUI

@Observable
class PickerService {
    enum PickerServiceError: LocalizedError {
        case emptySelection
        case invalidSelection

        var errorDescription: String? {
            switch self {
            case .emptySelection:
                return "An item has not been selected."
            case .invalidSelection:
                return "This file type is not supported."
            }
        }
    }

    var pickedItem: (any PickableItem)?

    var supportedPickerViews: [NavigationModel.CoursePage] = [
        .announcements,
        .files,
        .pages,
        .home,
        .syllabus
        // TODO: Add more supported picker pages.
    ]

    func validatePickedItem() throws {
        guard let pickedItem else { throw PickerServiceError.emptySelection }

        if let file = pickedItem as? File, let ext = file.localURL?.pathExtension {
            if !File.supportedPickableTypes.contains(ext) {
                throw PickerServiceError.invalidSelection
            }
        }
    }
}
