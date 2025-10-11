//
//  AnyWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/30/25.
//

import SwiftUI

@MainActor
struct AnyWidget {
    private let _id: String
    private let _mainBody: AnyView
    private let _allowedSizes: [WidgetSize]

    init<W: Widget>(_ widget: W) {
        self._id = widget.id
        self._mainBody = AnyView(widget.mainBody)
        self._allowedSizes = widget.allowedSizes
    }

    var id: String { _id }
    var mainBody: AnyView { _mainBody }
    var allowedSizes: [WidgetSize] { _allowedSizes }
}
