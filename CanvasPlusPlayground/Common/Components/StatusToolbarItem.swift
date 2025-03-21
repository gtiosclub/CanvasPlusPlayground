//
//  StatusToolbarItem.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/17/24.
//

import SwiftUI

private struct StatusToolbarItem: ViewModifier {
    let contentName: String
    let isVisible: Bool

    init(_ contentName: String, isVisible: Bool) {
        self.contentName = contentName
        self.isVisible = isVisible
    }

    func body(content: Content) -> some View {
        content
        #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .status) {
                    if isVisible {
                        toolbarContent
                    }
                }
            }
        #else
            .safeAreaInset(edge: .bottom) {
                if isVisible {
                    toolbarContent
                        .padding(6)
                        .background(.thinMaterial, in: .rect(cornerRadius: 8))
                        .padding(.bottom)
                }
            }
        #endif
    }

    private var toolbarContent: some View {
        HStack {
            ProgressView().controlSize(.small)
            Text("Loading \(contentName)...")
                .font(.footnote)
        }
    }
}

extension View {
    func statusToolbarItem(
        _ contentName: String,
        isVisible: Bool
    ) -> some View {
        modifier(
            StatusToolbarItem(
                contentName,
                isVisible: isVisible
            )
        )
    }
}
