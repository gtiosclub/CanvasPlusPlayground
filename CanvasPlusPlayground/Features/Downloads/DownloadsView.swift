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

    var body: some View {
        List(downloads) { download in
            DownloadItemView(model: .init(download: download))
        }
        .listStyle(.grouped)
        .navigationTitle("Downloads")
        .onAppear {
            print(downloads)
        }
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
            ProgressView(value: model.download.progress, total: 1.0)
        }
    }
}

#Preview {
    DownloadsView()
}
