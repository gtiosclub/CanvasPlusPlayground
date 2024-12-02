//
//  CourseFilesView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/7/24.
//

import SwiftUI

struct CourseFilesView: View {
    let course: Course
    @State private var fileManager: CourseFileManager

    init(course: Course) {
        self.course = course
        _fileManager = .init(initialValue: CourseFileManager(courseID: course.id))
    }

    var body: some View {
        NavigationStack {
            List(fileManager.files, id: \.id) { file in
                if let url = file.url, let url = URL(string: url)  {
                    NavigationLink(destination: CoursePDFView(url: url)) {
                        Text(file.displayName ?? "Couldn't find file name.")
                    }
                } else {
                    Text("File not available")
                }
            }
            .task {
                await fileManager.fetchFiles()
            }
            .navigationTitle("Files")
        }
    }
}
