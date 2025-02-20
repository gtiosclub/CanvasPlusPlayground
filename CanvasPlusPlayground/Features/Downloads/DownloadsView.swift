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
            DownloadItemView(model: .init(download: download))
                .onTapGesture {
                    selectedDownload = download
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
            ProgressView(value: model.download.progress, total: 1.0)
                .progressViewStyle(GaugeProgressStyle())
                .frame(height: 14)
        }
    }
}

struct GaugeProgressStyle: ProgressViewStyle {
    var strokeColor = Color.accentColor
    var strokeWidth = 2.5

    func makeBody(configuration: Configuration) -> some View {
        let fractionCompleted = configuration.fractionCompleted ?? 0

        return ZStack {
            Circle()
                .trim(from: 0, to: fractionCompleted)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .background {
                    Circle()
                        .stroke(.secondary, style: StrokeStyle(lineWidth: strokeWidth))
                }
                .padding(strokeWidth)
        }
    }
}

#Preview {
    DownloadsView()
}
