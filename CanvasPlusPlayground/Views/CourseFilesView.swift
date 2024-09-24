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
        List(fileManager.files, id: \.id) { file in
            NavigationLink(destination: CoursePDFView(url: URL(string: file.url)!)) {
                    Text(file.displayName)
            }
        }
        .task {
            await fileManager.fetchFiles()
        }
        .navigationTitle(course.name ?? "")
    }
}
