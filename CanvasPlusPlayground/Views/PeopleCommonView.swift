//
//  PeopleCommonView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 10/2/24.
//

import SwiftUI

struct PeopleCommonView: View {
    @Environment(PeopleManager.self) var peopleManager
    let user: User
    @State var courses: [Course] = []
    
    var body: some View {
        Text("\(courses.count) Common Course\(courses.count == 1 ? "" : "s")")

        List(courses, id: \.id) { course in
            Text(course.name ?? "")
        }
        .task {
            self.courses = await peopleManager.fetchAllClassesWith(userID: user.id!)
        }
        
    }
}

