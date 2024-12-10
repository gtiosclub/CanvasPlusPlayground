//
//  ColorPickerWithoutLabel.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 11/16/24.
//

#if os(iOS)

import SwiftUI

@available(iOS 14.0, *)
public struct ColorPickerWithoutLabel: UIViewRepresentable {
    @Binding var selection: Color
    var supportsAlpha: Bool = true
    
    public init(selection: Binding<Color>, supportsAlpha: Bool = true) {
        self._selection = selection
        self.supportsAlpha = supportsAlpha
    }
    
    
    public func makeUIView(context: Context) -> UIColorWell {
        let well = UIColorWell()
        well.supportsAlpha = supportsAlpha
        return well
    }
    
    public func updateUIView(_ uiView: UIColorWell, context: Context) {
        uiView.selectedColor = UIColor(selection)
    }
}

extension View {
    @available(iOS 14.0, *)
    public func colorPickerSheet(isPresented: Binding<Bool>, selection: Binding<Color>, supportsAlpha: Bool = true, title: String? = nil, onDisappear: @escaping (() -> Void) = { }) -> some View {
        self.background(
            ColorPickerSheet(
                isPresented: isPresented,
                selection: selection,
                supportsAlpha: supportsAlpha,
                title: title,
                onDisappear: onDisappear
            )
        )
    }
}

@available(iOS 14.0, *)
private struct ColorPickerSheet: UIViewRepresentable {
    @Binding var isPresented: Bool
    @Binding var selection: Color
    var supportsAlpha: Bool
    var title: String?
    let onDisappear: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            selection: $selection,
            isPresented: $isPresented,
            onDisappear: onDisappear
        )
    }
    
    class Coordinator: NSObject, UIColorPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
        @Binding var selection: Color
        @Binding var isPresented: Bool
        let onDisappear: () -> Void
        var didPresent = false

        init(selection: Binding<Color>, isPresented: Binding<Bool>, onDisappear: @escaping (() -> Void)) {
            self._selection = selection
            self._isPresented = isPresented
            self.onDisappear = onDisappear
        }
        
        func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
            selection = Color(viewController.selectedColor)
        }
        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            isPresented = false
            didPresent = false
            self.onDisappear()
        }
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            isPresented = false
            didPresent = false
        }
    }

    func getTopViewController(from view: UIView) -> UIViewController? {
        guard var top = view.window?.rootViewController else {
            return nil
        }
        while let next = top.presentedViewController {
            top = next
        }
        return top
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isHidden = true
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if isPresented && !context.coordinator.didPresent {
            let modal = UIColorPickerViewController()
            modal.selectedColor = UIColor(selection)
            modal.supportsAlpha = supportsAlpha
            modal.title = title
            modal.delegate = context.coordinator
            modal.presentationController?.delegate = context.coordinator
            let top = getTopViewController(from: uiView)
            top?.present(modal, animated: true)
            context.coordinator.didPresent = true
        }
    }
}

#endif
