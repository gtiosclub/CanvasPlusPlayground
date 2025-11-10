//
//  DownloadButton.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/10/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DownloadButton: View {
    
    let url: URL
    let fileName: String

    @State var dataFileDocument: DataFileDocument? = nil
    @State var showFileExporter: Bool = false
    @State var showProgressView: Bool = false
    
    var body: some View {
        Group {
            if showProgressView {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button("Download", systemImage: "arrow.down.circle", action:downloadFile)
                    .labelStyle(.iconOnly)
            }
        }
        .fileExporter(isPresented: $showFileExporter, document: dataFileDocument, defaultFilename: fileName) { result in
            switch result {
            case .success(let url):
                LoggerService.main.info("File saved to \(url)")
            case .failure(let error):
                LoggerService.main.error("Error placing submission attachment: \(error)")
            }
        }
        
    }
    
    func downloadFile() {
        showProgressView = true
        Task {
            guard let data = await url.downloadWebFile() else {
                print("Error downloading file")
                return
            }

            dataFileDocument = DataFileDocument(data: data)
            showFileExporter = true
            showProgressView = false
        }
    }
    
}


// Struct used for file downloads to the user's filesystem.
// This file takes in generic data (the name of the file dictates the type w/ file exporter)
struct DataFileDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.fileURL]
    static var writableContentTypes: [UTType] = [.fileURL]
    var data: Data
    init(data: Data) {
        self.data = data
    }
    
    // For loading from disk (not essential for exporting)
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    
    // For saving to disk
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}
