//
//  DownloadView.swift
//  CanvasPlusPlayground
//
//  Created by João Pozzobon on 2/17/25.
//

import SwiftUI
import SwiftData

struct DownloadsView: View {
    @Query var downloads: [Download]
    @State var selectedDownload: Download?

    var body: some View {
        List(downloads) { download in
            if let course = download.course {
                FileRow(model: .init(file: download.file, course: course))
                    .onTapGesture {
                        selectedDownload = download
                    }
            }
        }
        .sheet(item: $selectedDownload) { item in
            FileViewer(download: item)
                .frame(minHeight: 500)
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .navigationTitle("Downloads")
    }
}

@Observable
class DownloadItemViewModel {
    var download: Download

    init(download: Download) {
        self.download = download
    }
}

struct DownloadItemView: View {
    var model: DownloadItemViewModel

    var body: some View {
        HStack {
            Text(model.download.file.displayName)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    DownloadsView()
}
