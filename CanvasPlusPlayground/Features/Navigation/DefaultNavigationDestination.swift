//  DefaultNavigationDestination.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/4/25.
//

import SwiftUI

extension View {
    /// Adds the default navigation destination logic for NavigationModel.Destination.
    /// Also keeps the breadcrumb trail in sync with the navigation path.
    func defaultNavigationDestination() -> some View {
        self.modifier(DefaultNavigationDestinationModifier())
    }
}

private struct DefaultNavigationDestinationModifier: ViewModifier {
    @Environment(NavigationModel.self) private var navigationModel

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: NavigationModel.Destination.self) { destination in
                destination.destinationView()
                    .toolbarBackground(.hidden, for: .automatic)
                    .onAppear {
                        navigationModel.recordDestination(destination)
                    }
                    .safeAreaInset(edge: .top, spacing: 0) {
                        BreadcrumbView()
                    }
            }
            .onChange(of: navigationModel.navigationPath.count) { oldCount, newCount in
                if newCount < oldCount {
                    navigationModel.trimBreadcrumbs(to: newCount)
                }
            }
    }
}
