//  DefaultNavigationDestination.swift
//  CanvasPlusPlayground
//
//  Created by Assistant on 9/4/25.
//

import SwiftUI

extension View {
    /// Adds the default navigation destination logic for NavigationModel.Destination, including URL handling.
    func defaultNavigationDestination(
        navigationModel: Bindable<NavigationModel>,
        courseID: Course.ID
    ) -> some View {
        self.navigationDestination(for: NavigationModel.Destination.self) { destination in
            destination.destinationView()
                .environment(\.openURL, OpenURLAction { url in
                    guard let urlServiceResult = CanvasURLService.determineNavigationDestination(from: url) else { return .discarded }
                    Task {
                        await navigationModel.wrappedValue.handleURLSelection(
                            result: urlServiceResult,
                            courseID: courseID
                        )
                    }
                    return .handled
                })
        }
    }
}
