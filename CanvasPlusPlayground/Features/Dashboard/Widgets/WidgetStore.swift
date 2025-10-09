//
//  WidgetStore.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/9/25.
//

import SwiftUI

// MARK: - Widget Configuration

/// Configuration for a widget instance, tracking its type, size, and position
struct WidgetConfiguration: Identifiable, Codable, Equatable {
    let id: String
    let widgetID: String
    var size: WidgetSize
    var order: Int

    init(id: String = UUID().uuidString, widgetID: String, size: WidgetSize = .medium, order: Int = 0) {
        self.id = id
        self.widgetID = widgetID
        self.size = size
        self.order = order
    }
}

// MARK: - Widget Store

@Observable
@MainActor
class WidgetStore {
    static let shared = WidgetStore()
    private static let widgetConfigurationsKey = "com.canvasPlus.widgetConfigurations"

    // MARK: - Properties

    private(set) var widgetConfigurations: [WidgetConfiguration] = [] {
        didSet { saveConfigurations() }
    }

    // MARK: - Available Widget Types

    static let availableWidgetTypes: [String: String] = [
        AllAnnouncementsWidget.widgetID: "Announcements",
        AllToDosWidget.widgetID: "To-Do"
    ]

    // MARK: - Initialization

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
        let config = WidgetConfiguration(widgetID: widgetID, size: size, order: nextOrder)
        widgetConfigurations.append(config)
    }

    /// Removes a widget from the dashboard
    func removeWidget(configurationID: String) {
        widgetConfigurations.removeAll { $0.id == configurationID }
        reorderWidgets()
    }

    /// Updates the size of a specific widget
    func updateWidgetSize(configurationID: String, newSize: WidgetSize) {
        guard let index = widgetConfigurations.firstIndex(where: { $0.id == configurationID }) else {
            return
        }
        widgetConfigurations[index].size = newSize
    }

    /// Reorders widgets based on new positions
    func reorderWidgets(from source: IndexSet, to destination: Int) {
        widgetConfigurations.move(fromOffsets: source, toOffset: destination)
        reorderWidgets()
    }

    /// Updates widget order to maintain consistency
    private func reorderWidgets() {
        for (index, config) in widgetConfigurations.enumerated() {
            if widgetConfigurations[index].order != index {
                widgetConfigurations[index].order = index
            }
        }
    }

    // MARK: - Widget Instantiation

    /// Creates a widget instance from a configuration
    func createWidget(from configuration: WidgetConfiguration) -> (any Widget)? {
        switch configuration.widgetID {
        case AllAnnouncementsWidget.widgetID:
            return AllAnnouncementsWidget()
        case AllToDosWidget.widgetID:
            return AllToDosWidget()
        default:
            return nil
        }
    }

    /// Gets all widgets sorted by order
    var widgets: [(configuration: WidgetConfiguration, widget: AnyWidget)] {
        widgetConfigurations
            .sorted { $0.order < $1.order }
            .compactMap { config in
                guard let widget = createWidget(from: config) else { return nil }
                return (config, AnyWidget(widget))
            }
    }

    // MARK: - Persistence

    private func saveConfigurations() {
        if let data = try? JSONEncoder().encode(widgetConfigurations) {
            UserDefaults.standard.set(data, forKey: Self.widgetConfigurationsKey)
        }
    }

    private func loadConfigurations() {
        guard let data = UserDefaults.standard.data(forKey: Self.widgetConfigurationsKey),
              let configurations = try? JSONDecoder().decode([WidgetConfiguration].self, from: data) else {
            return
        }
        widgetConfigurations = configurations.sorted { $0.order < $1.order }
    }

    private func initializeDefaultWidgets() {
        addWidget(widgetID: AllAnnouncementsWidget.widgetID, size: .medium)
        addWidget(widgetID: AllToDosWidget.widgetID, size: .medium)
    }

    // MARK: - Debug

    #if DEBUG
    /// Resets all widget configurations to defaults
    func resetToDefaults() {
        widgetConfigurations.removeAll()
        initializeDefaultWidgets()
    }

    /// Clears all widget configurations
    func clearAllWidgets() {
        widgetConfigurations.removeAll()
    }
    #endif
}
