//
//  CourseContextMenu.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/1/25.
//
import SwiftUI

private struct CourseContextMenu: ViewModifier {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.supportsMultipleWindows) var supportsMultipleWindows

    let focusWindowInfo: FocusWindowInfo
    

    func body(content: Content) -> some View {
        content
            .contextMenu {
                if supportsMultipleWindows {
                    Button("Open in New Window", systemImage: "macwindow.badge.plus") {
                        openWindow(value: focusWindowInfo)
                    }
                }
            }
    }
}

extension View {
    func contextMenu(for focusWindowInfo: FocusWindowInfo) -> some View {
        modifier(CourseContextMenu(focusWindowInfo: focusWindowInfo))
    }
}
