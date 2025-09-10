//
//  CanvasURLService+Modifier.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/25.
//

import SwiftUI

private struct CanvasURLServiceModifier: ViewModifier {
    @Environment(NavigationModel.self) private var navigationModel

    let courseID: Course.ID

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                guard let urlServiceResult = CanvasURLService.determineNavigationDestination(from: url) else { return .systemAction }

                Task {
                    await navigationModel.handleURLSelection(
                        result: urlServiceResult,
                        courseID: courseID
                    )
                }
                
                return .handled
            })
    }
}

extension View {
    func handleDeepLinks(for courseID: Course.ID) -> some View {
        modifier(CanvasURLServiceModifier(courseID: courseID))
    }
}
