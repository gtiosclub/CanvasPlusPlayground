//
//  DownloadView.swift
//  CanvasPlusPlayground
//
//  Created by João Pozzobon on 2/17/25.
//

import SwiftData
import SwiftUI

struct DownloadsView: View {
    @Query var downloads: [Download]
    @State private var selectedDownload: Download?

    @State private var searchText: String = ""

    var groupedDownloads: [Date: [Download]] {
        var downloads = self.downloads

        if !searchText.isEmpty {
            downloads = downloads.filter({ download in
                searchText.split(separator: " ").allSatisfy {
                    download.file.filename.localizedCaseInsensitiveContains($0)
                }
            })
        }

        return downloads.reduce(into: [Date: [Download]]()) { accumulator, current in
            let components = Calendar.current.dateComponents([.year, .month, .day], from: current.downloadedDate)
            if let date = Calendar.current.date(from: components) {
                let existing = accumulator[date] ?? []
                accumulator[date] = existing + [current]
            }
        }
    }

    func relativeDate(from date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            return dateFormatter.string(from: date)
        }
    }

    var body: some View {
        List {
            #if os(macOS)
            TextField(text: $searchText, label: {
                Label("Search", systemImage: "magnifyingglass")
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            #endif

            ForEach(Array(groupedDownloads.keys), id: \.self) { key in
                Section(relativeDate(from: key)) {
                    if let downloads = groupedDownloads[key] {
                        ForEach(downloads) { download in
                            if let course = download.course {
                                FileRow(model: .init(file: download.file, course: course))
                                    .onTapGesture {
                                        selectedDownload = download
                                    }
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedDownload) { item in
            FileViewer(download: item)
                .frame(minHeight: 500)
        }
        #if os(iOS)
        .searchable(text: $searchText)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
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
