//
//  PickerServiceViewModifier.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/21/25.
//

import SwiftUI

private struct PickerServiceViewModifier<T: PickableItem & Equatable>: ViewModifier {
    @Environment(PickerService.self) private var pickerService: PickerService?

    var item: T?

    func body(content: Content) -> some View {
        content
            .onChange(of: item, initial: true) { _, _ in
                pickerService?.pickedItem = item
            }
    }
}

extension View {
    func pickedItem<T: PickableItem & Equatable>(_ item: T?) -> some View {
        modifier(PickerServiceViewModifier(item: item))
    }
}
