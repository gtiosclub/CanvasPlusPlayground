//
//  NewWindowButton.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/1/25.
//
import SwiftUI

struct NewWindowButton: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.supportsMultipleWindows) var supportsMultipleWindows

    let destination: NavigationModel.Destination

    var body: some View {
        if supportsMultipleWindows {
            Button("Open in New Window", systemImage: .macwindowBadgePlus) {
                openWindow(value: destination.focusWindowInfo)
            }
        } else {
            EmptyView()
        }
    }
}
