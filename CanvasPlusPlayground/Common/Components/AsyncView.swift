//
//  AsyncView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/8/25.
//

import SwiftUI

struct AsyncView<T, Content: View, Placeholder: View>: View {
    enum LoadingState: Equatable {
        case loading
        case loaded(T)
        case failed

        static func == (lhs: AsyncView<T, Content, Placeholder>.LoadingState, rhs: AsyncView<T, Content, Placeholder>.LoadingState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.loaded, .loaded), (.failed, .failed):
                return true
            default:
                return false
            }
        }
    }

    let asyncFunction: () async -> T?
    @ViewBuilder let content: (T) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var viewState: LoadingState = .loading

    var body: some View {
        Group {
            if viewState == .loading {
                placeholder()
            } else if case .loaded(let data) = viewState {
                content(data)
            } else {
                EmptyView()
            }
        }
        .task {
            if let result = await asyncFunction() {
                viewState = .loaded(result)
            } else {
                viewState = .failed
            }
        }
    }
}
