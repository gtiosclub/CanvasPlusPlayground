//
//  CourseItemPicker.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/21/25.
//

import SwiftUI

struct CourseItemPicker: View {
    @Environment(\.dismiss) private var dismiss

    let course: Course
    @Binding var selectedItem: (any PickableItem)?

    @State private var service = PickerService()
    @State private var navigationModel = NavigationModel()

    @State private var error: PickerService.PickerServiceError?

    private var showErrorAlert: Binding<Bool> {
        Binding<Bool>(
            get: { error != nil },
            set: {
                if !$0 {
                    error = nil
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            mainBody
        }
        .onDisappear {
            LoggerService.main.debug(
                """
                Picked Item: \(String(describing: service.pickedItem))
                Contents: \(String(describing: service.pickedItem?.contents))
                """
            )
        }
        .onChange(of: service.pickedItem?.contents) { _, _ in
            selectedItem = service.pickedItem
        }
        .environment(service)
        .environment(navigationModel)
        .alert(isPresented: showErrorAlert, error: error) { _ in
            Button("OK") { showErrorAlert.wrappedValue = false }
        } message: { _ in
            Text("Cannot select item.")
        }

        #if os(macOS)
        .frame(width: 400, height: 500)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                cancelButton
            }

            ToolbarItem(placement: .confirmationAction) {
                confirmButton
            }
        }
        #else
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()

                HStack {
                    cancelButton
                    Spacer()
                    confirmButton
                }
                .padding()
                .background(.thinMaterial)
                .bold()
            }
        }
        #endif
    }

    private var mainBody: some View {
        CourseView(course: course)
            .defaultNavigationDestination(courseID: course.id)
    }

    private var cancelButton: some View {
        Button("Cancel") { dismiss() }
    }

    private var confirmButton: some View {
        Button("Choose") {
            do {
                try service.validatePickedItem()
                dismiss()
            } catch {
                self.error = error as? PickerService.PickerServiceError
            }
        }
        .disabled(service.pickedItem == nil)
    }
}
