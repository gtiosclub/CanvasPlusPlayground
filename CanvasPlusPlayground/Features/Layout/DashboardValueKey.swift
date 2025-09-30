//
//  DashboardValueKey.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/30/25.
//
//  Abstracts: Set up a LayoutValueKey for the Dashboard layout in order for the child views to pass up informaiton about their widget size back up to the container view
//  for the layout to correctly place each Widget

import SwiftUI

private struct WidgetSize: LayoutValueKey {
    static let defaultValue: Size = .large
}

extension LayoutSubview {
    var widgetSize: Size {
        self[WidgetSize.self]
    }
}

enum Size: Comparable {
    case small
    case medium
    case large
}

extension View {
    func widgetSize(_ value: Size) -> some View {
        layoutValue(key: WidgetSize.self, value: value)
    }
}
