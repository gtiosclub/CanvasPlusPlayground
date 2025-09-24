//
//  PickableFileImporterModifier.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/24/25.
// 

import SwiftUI
import UniformTypeIdentifiers

/// A view modifier that wraps fileImporter and updates a PickableItem binding with the file's contents.
private struct PickableFileImporterModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var pickedItem: (any PickableItem)?
    var allowedContentTypes: [UTType] = [.pdf, .plainText, .html]
    
    func body(content: Content) -> some View {
        content.fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result {
                guard let url = urls.first else { return }
                Task {
                    let text = CourseFileService.getContentsOfFile(at: url)
                    await MainActor.run {
                        pickedItem = AnyPickableItem(
                            name: url.lastPathComponent,
                            contents: text
                        )
                    }
                }
            }
        }
    }
}

extension View {
    /// Presents a file importer and updates the given PickableItem binding with the file's contents.
    ///
    /// - Parameters:
    ///   - isPresented: Binding controlling presentation of the file importer.
    ///   - pickedItem: Binding to update with the loaded PickableItem.
    ///   - allowedContentTypes: Allowed UTTypes (default: pdf, plainText, html).
    func pickableFileImporter(
        isPresented: Binding<Bool>,
        pickedItem: Binding<(any PickableItem)?>,
        allowedContentTypes: [UTType] = [.pdf, .plainText, .html]
    ) -> some View {
        modifier(
            PickableFileImporterModifier(
                isPresented: isPresented,
                pickedItem: pickedItem,
                allowedContentTypes: allowedContentTypes
            )
        )
    }
}
