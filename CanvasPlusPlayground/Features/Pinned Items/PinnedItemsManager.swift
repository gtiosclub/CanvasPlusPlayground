//
//  PinnedItemsManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/8/25.
//

import SwiftUI
import SwiftData
@Observable
class PinnedItemsManager {
    static let pinnedItemsKey: String = "pinnedItems"
	private var repository: CanvasRepository
    private(set) var pinnedItems: [PinnedItem] = [] {
        didSet { savePinnedItems() }
    }

    var pinnedItemsByType: [PinnedItem.PinnedItemType: [PinnedItem]] {
        Dictionary(grouping: pinnedItems) { $0.type }
    }

    init(repository: CanvasRepository) {
		self.repository = repository
        getPinnedItems()
    }

    // MARK: - User Intents

    func togglePinnedItem(
        itemID: String,
        courseID: String?,
        type: PinnedItem.PinnedItemType
    ) {
        guard let courseID else { return }

        if pinnedItems.contains(where: {
            $0.id == itemID && $0.courseID == courseID && $0.type == type
        }) {
            removePinnedItem(itemID: itemID, courseID: courseID, type: type)
        } else {
            addPinnedItem(itemID: itemID, courseID: courseID, type: type)
        }
    }

    func addPinnedItem(
        itemID: String,
        courseID: String,
        type: PinnedItem.PinnedItemType
    ) {
        let item = PinnedItem(id: itemID, courseID: courseID, type: type)
        pinnedItems.append(
            item
        )
    }

    func removePinnedItem(
        itemID: String,
        courseID: String,
        type: PinnedItem.PinnedItemType
    ) {
        let index = pinnedItems.firstIndex {
            $0.id == itemID && $0.courseID == courseID && $0.type == type
        }

        guard let index else { return }

        pinnedItems.remove(at: index)
    }

    // MARK: - Private

    private func savePinnedItems() {
        if let data = try? JSONEncoder().encode(pinnedItems) {
            UserDefaults.standard.set(data, forKey: Self.pinnedItemsKey)
        }
    }
	
	func isItemPinned(itemID: String, courseID: String, type: PinnedItem.PinnedItemType) -> Bool {
			pinnedItems.contains {
				$0.id == itemID && $0.courseID == courseID && $0.type == type
			}
		}

    private func getPinnedItems() {
        var result: [PinnedItem] = []

        if let data = UserDefaults.standard.data(forKey: Self.pinnedItemsKey) {
            result = (try? JSONDecoder().decode([PinnedItem].self, from: data)) ?? []
        }

        pinnedItems = result
    }
	
	@MainActor
	private func pinItem<T: Sendable & PersistentModel>(
			withData data: T,
			itemID: String,
			courseID: String,
			type: PinnedItem.PinnedItemType
		) {
			// Save to model context
			repository.modelContext.insert(data)
			
			do {
				try repository.modelContext.save()
			} catch {
				print("Failed to save model to cache on pinning: \(error)")
			}
			
			let item = PinnedItem(id: itemID, courseID: courseID, type: type)
			pinnedItems.append(item)
		}

    // MARK: - Debug
    #if DEBUG
    func clearAllPinnedItems() {
        pinnedItems.removeAll()
    }
    #endif
}
