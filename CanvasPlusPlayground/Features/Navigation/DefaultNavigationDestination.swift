//  DefaultNavigationDestination.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/4/25.
//

import SwiftUI

extension View {
    /// Adds the default navigation destination logic for NavigationModel.Destination, including URL handling.
    func defaultNavigationDestination(
        courseID: Course.ID
    ) -> some View {
        self.navigationDestination(for: NavigationModel.Destination.self) { destination in
            destination.destinationView()
                .handleDeepLinks(for: courseID)
        }
    }
}
