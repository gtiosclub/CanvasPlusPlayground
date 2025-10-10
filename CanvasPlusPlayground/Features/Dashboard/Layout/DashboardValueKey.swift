//
//  DashboardValueKey.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/30/25.
//
//  Abstracts: Set up a LayoutValueKey for the Dashboard layout in order for the child views to pass up informaiton about their widget size back up to the container view
//  for the layout to correctly place each Widget

import SwiftUI

private struct WidgetSizeKey: LayoutValueKey {
    static let defaultValue: WidgetSize = .large
}

extension LayoutSubview {
    var widgetSize: WidgetSize {
        self[WidgetSizeKey.self]
    }
}

enum WidgetSize: Comparable, Codable {
    case small
    case medium
    case large

    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    var systemImage: String {
        switch self {
        case .small: "widget.small"
        case .medium: "widget.medium"
        case .large: "widget.large"
        }
    }
}

extension View {
    func widgetSize(_ value: WidgetSize) -> some View {
        layoutValue(key: WidgetSizeKey.self, value: value)
            .environment(\.widgetSize, value)
    }
}

// MARK: - Environment Key for Widget Size

private struct WidgetSizeEnvironmentKey: EnvironmentKey {
    static let defaultValue: WidgetSize = .medium
}

extension EnvironmentValues {
    var widgetSize: WidgetSize {
        get { self[WidgetSizeEnvironmentKey.self] }
        set { self[WidgetSizeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Environment Key for Widget Configuration ID

private struct WidgetConfigurationIDKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    var widgetConfigurationID: String? {
        get { self[WidgetConfigurationIDKey.self] }
        set { self[WidgetConfigurationIDKey.self] = newValue }
    }
}
