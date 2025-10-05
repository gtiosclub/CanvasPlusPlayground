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

enum WidgetSize: Comparable {
    case small
    case medium
    case large
}

extension View {
    func widgetSize(_ value: WidgetSize) -> some View {
        layoutValue(key: WidgetSizeKey.self, value: value)
    }
}
