//
//  SpotlightIndexer.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 3/29/26.
//

import CoreSpotlight
import SwiftData

/// The indexer doesn't know anything about individual model types —
/// the protocol conformances handle all the metadata extraction.
@MainActor
class SpotlightIndexer {
    static let shared = SpotlightIndexer()


    private let searchableIndex = CSSearchableIndex(name: "CanvasPlusPlayground")

    private func searchableItems<T: SpotlightSearchable & PersistentModel>(
        for type: T.Type,
        in context: ModelContext
    ) -> [CSSearchableItem] {
        let models = (try? context.fetch(FetchDescriptor<T>())) ?? []
        return models.map { $0.toSearchableItem() }
    }

    /// Index all locally-cached content into CoreSpotlight.

    func indexAllContent() async {
        let context = ModelContext.shared

        var items: [CSSearchableItem] = []

        // MARK: - Add new types if needed
        items += searchableItems(for: Course.self, in: context)
        items += searchableItems(for: Assignment.self, in: context)
        items += searchableItems(for: DiscussionTopic.self, in: context)
        items += searchableItems(for: Quiz.self, in: context)
        items += searchableItems(for: Page.self, in: context)
        items += searchableItems(for: File.self, in: context)
        items += searchableItems(for: Module.self, in: context)
        items += searchableItems(for: User.self, in: context)
        items += searchableItems(for: CanvasGroup.self, in: context)
        items += searchableItems(for: ToDoItem.self, in: context)

        do {
            try await searchableIndex.indexSearchableItems(items)
            LoggerService.main.debug("SpotlightIndexer: Indexed \(items.count) items")
        } catch {
            LoggerService.main.error("SpotlightIndexer: Indexing failed: \(error)")
        }
    }

    /// Re-index a single category (e.g., after fetching new assignments).
    func reindex<T: SpotlightSearchable & PersistentModel>(
        _ type: T.Type,
        in context: ModelContext
    ) async {
        // Delete old items for this domain
        do {
            try await searchableIndex.deleteSearchableItems(
                withDomainIdentifiers: [T.spotlightDomainIdentifier]
            )
        } catch {
            LoggerService.main.error("SpotlightIndexer: Failed to delete domain \(T.spotlightDomainIdentifier): \(error)")
        }

        // Index fresh data
        let items = searchableItems(for: type, in: context)

        do {
            try await searchableIndex.indexSearchableItems(items)
            LoggerService.main.debug("SpotlightIndexer: Re-indexed \(items.count) \(T.spotlightDomainIdentifier)")
        } catch {
            LoggerService.main.error("SpotlightIndexer: Re-indexing \(T.spotlightDomainIdentifier) failed: \(error)")
        }
    }

    /// Remove all indexed items (e.g., on logout or account switch).
    func deleteAllContent() async {
        do {
            try await searchableIndex.deleteAllSearchableItems()
            LoggerService.main.debug("SpotlightIndexer: Deleted all items")
        } catch {
            LoggerService.main.error("SpotlightIndexer: Delete all failed: \(error)")
        }
    }
}
