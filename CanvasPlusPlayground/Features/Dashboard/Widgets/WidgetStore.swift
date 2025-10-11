//
//  WidgetStore.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/9/25.
//

import SwiftUI

/// Configuration for a widget instance, tracking its type, size, and position
struct WidgetConfiguration: Identifiable, Codable, Equatable {
    let id: String
    let widgetID: String
    var size: WidgetSize
    var order: Int

    init(
        id: String = UUID().uuidString,
        widgetID: String,
        size: WidgetSize = .medium,
        order: Int = 0
    ) {
        self.id = id
        self.widgetID = widgetID
        self.size = size
        self.order = order
    }
}

@Observable
@MainActor
class WidgetStore {
    /// Represents a widget instance with its configuration
    struct ConfiguredWidget: Identifiable {
        let configuration: WidgetConfiguration
        let widget: AnyWidget

        var id: String { configuration.id }
    }

    static let shared = WidgetStore()
    private static let widgetConfigurationsKey = "com.canvasPlus.widgetConfigurations"

    // MARK: - Properties

    var widgetConfigurations: [WidgetConfiguration] = [] {
        didSet {
            saveConfigurations()
            updateWidgetCache()
        }
    }

    var widgets: [ConfiguredWidget] {
        widgetConfigurations
            .sorted { $0.order < $1.order }
            .compactMap { config in
                guard let widget = getCachedWidget(for: config) else {
                    return nil
                }

                return ConfiguredWidget(
                    configuration: config,
                    widget: AnyWidget(widget)
                )
            }
    }

    // prevent recreation on size changes
    private var widgetCache: [String: any Widget] = [:]

    // MARK: - Available Widget Types

    /// Metadata about an available widget type
    @MainActor
    struct WidgetTypeInfo: Identifiable, Hashable {
        let id: String
        let displayName: String
        let description: String
        let systemImage: String
        let color: Color
        let allowedSizes: [WidgetSize]

        init(widgetType: any Widget.Type) {
            self.id = widgetType.widgetID
            self.displayName = widgetType.displayName
            self.description = widgetType.description
            self.systemImage = widgetType.systemImage
            self.color = widgetType.color
            self.allowedSizes = widgetType.allowedSizes
        }

        /// Creates a widget instance for this widget type
        func createWidget() -> (any Widget)? {
            WidgetStore.createWidget(for: id)
        }
    }

    private init() {
        loadConfigurations()

        // Initialize with default widgets if none exist
        if widgetConfigurations.isEmpty {
            initializeDefaultWidgets()
        }
    }

    // MARK: - Widget Management

    /// Adds a new widget to the dashboard
    func addWidget(widgetID: String, size: WidgetSize = .medium) {
        let nextOrder = (widgetConfigurations.map(\.order).max() ?? -1) + 1
        let config = WidgetConfiguration(
            widgetID: widgetID,
            size: size,
            order: nextOrder
        )
        widgetConfigurations.append(config)
    }

    /// Removes a widget from the dashboard
    func removeWidget(configurationID: String) {
        widgetConfigurations.removeAll { $0.id == configurationID }
        reorderWidgets()
    }

    /// Reorders widgets based on new positions
    func reorderWidgets(from source: IndexSet, to destination: Int) {
        widgetConfigurations.move(fromOffsets: source, toOffset: destination)
        reorderWidgets()
    }

    /// Gets widget type info for a configuration
    func widgetTypeInfo(for configuration: WidgetConfiguration) -> WidgetTypeInfo? {
        Self.availableWidgetTypes.first(where: { $0.id == configuration.widgetID })
    }

    /// Updates widget order to maintain consistency
    private func reorderWidgets() {
        for (index, _) in widgetConfigurations.enumerated() {
            if widgetConfigurations[index].order != index {
                widgetConfigurations[index].order = index
            }
        }
    }

    // MARK: - Widget Instantiation

    /// Creates a widget instance from a widget ID
    fileprivate static func createWidget(for widgetID: String) -> (any Widget)? {
        switch widgetID {
        case AllAnnouncementsWidget.widgetID:
            return AllAnnouncementsWidget()
        case AllToDosWidget.widgetID:
            return AllToDosWidget()
        default:
            return nil
        }
    }

    /// Creates a widget instance from a configuration
    private func createWidget(from configuration: WidgetConfiguration) -> (any Widget)? {
        Self.createWidget(for: configuration.widgetID)
    }

    /// Gets or creates a cached widget instance
    private func getCachedWidget(
        for configuration: WidgetConfiguration
    ) -> (any Widget)? {
        if let cached = widgetCache[configuration.id] {
            return cached
        }

        guard let widget = createWidget(from: configuration) else { return nil }
        widgetCache[configuration.id] = widget
        return widget
    }

    /// Updates the widget cache when configurations change
    private func updateWidgetCache() {
        let currentIDs = Set(widgetConfigurations.map(\.id))
        let cachedIDs = Set(widgetCache.keys)

        // Remove widgets that are no longer in configurations
        for id in cachedIDs where !currentIDs.contains(id) {
            widgetCache.removeValue(forKey: id)
        }
    }

    // MARK: - Persistence

    private func saveConfigurations() {
        if let data = try? JSONEncoder().encode(widgetConfigurations) {
            UserDefaults.standard.set(
                data,
                forKey: Self.widgetConfigurationsKey
            )
        }
    }

    private func loadConfigurations() {
        guard let data = UserDefaults.standard.data(forKey: Self.widgetConfigurationsKey),
              let configurations = try? JSONDecoder().decode([WidgetConfiguration].self, from: data) else {
            return
        }
        widgetConfigurations = configurations.sorted { $0.order < $1.order }

        // Initialize widget cache
        for config in widgetConfigurations {
            _ = getCachedWidget(for: config)
        }
    }

    private func initializeDefaultWidgets() {
        if !widgetConfigurations.isEmpty {
            clearAllWidgets()
        }

        for config in Self.defaultConfigurations {
            addWidget(widgetID: config.widgetID, size: config.size)
        }
    }

    // MARK: - Settings

    func resetToDefaults() {
        widgetConfigurations.removeAll()
        initializeDefaultWidgets()
    }

    /// Clears all widget configurations
    private func clearAllWidgets() {
        widgetConfigurations.removeAll()
    }
}
