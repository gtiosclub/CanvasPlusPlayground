//
//  DetailsView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 9/9/25.
//

import SwiftUI

// 3. The Reusable Generic View
// This view can display any object that conforms to `DisplayableItemDetails`.
// The `@ViewBuilder` allows us to inject custom sections for specific types.
struct DetailsView<Item: DisplayableItemDetails, AdditionalContent: View>: View {
	let item: Item
	@ViewBuilder let additionalContent: AdditionalContent

	init(item: Item, @ViewBuilder additionalContent: () -> AdditionalContent) {
		self.item = item
		self.additionalContent = additionalContent()
	}
	
	// Convenience initializer for when there's no additional content.
	init(item: Item) where AdditionalContent == EmptyView {
		self.init(item: item) { EmptyView() }
	}

	var body: some View {
		Form {
			Section("Details") {
				LabeledContent("Name", value: item.displayName)

				if let unlockAt = item.unlockDate {
					LabeledContent("Available From") {
						Text(unlockAt, style: .time) + Text(" on ") + Text(unlockAt, style: .date)
					}
				}

				if let dueDate = item.dueDate {
					LabeledContent("Due") {
						Text(dueDate, style: .time) + Text(" on ") + Text(dueDate, style: .date)
					}
				}

				if let lockAt = item.lockDate {
					LabeledContent("Available Until") {
						Text(lockAt, style: .time) + Text(" on ") + Text(lockAt, style: .date)
					}
				}

				LabeledContent("Points Possible", value: item.pointsPossibleDisplay)
			}
			
			// Injecting the custom content here
			additionalContent

			if let description = item.descriptionHTML, !description.isEmpty {
				Section("Description") {
					HTMLTextView(htmlText: description)
				}
			}
		}
		.navigationTitle("\(item.itemType) Details")
		.formStyle(.grouped)
	}
}
