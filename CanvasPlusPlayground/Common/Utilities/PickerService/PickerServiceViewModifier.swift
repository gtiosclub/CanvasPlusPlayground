//
//  PickerServiceViewModifier.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/21/25.
//

import SwiftUI

private struct PickerServiceViewModifier: ViewModifier {
    @Environment(PickerService.self) private var pickerService: PickerService?

    var item: (any PickableItem)?

    func body(content: Content) -> some View {
        content
            .onChange(of: item?.contents) { _, _ in
                pickerService?.pickedItem = item
            }
    }
}

extension View {
    func pickedItem(_ item: (any PickableItem)?) -> some View {
        modifier(PickerServiceViewModifier(item: item))
    }
}
