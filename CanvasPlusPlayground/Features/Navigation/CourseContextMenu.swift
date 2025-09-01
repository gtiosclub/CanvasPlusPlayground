//
//  CourseContextMenu.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/1/25.
//
import SwiftUI

struct CourseContextMenu: ViewModifier {
    @Environment(\.openWindow) private var openWindow
    
    let focusWindowInfo: FocusWindowInfo
    
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button("Open in New Window") {
                    openWindow(value: focusWindowInfo)
                }
            }
    }
}

extension View {
    func contextMenu(for focusWindowInfo: FocusWindowInfo) -> some View {
        modifier(CourseContextMenu(focusWindowInfo: focusWindowInfo))
    }
}
