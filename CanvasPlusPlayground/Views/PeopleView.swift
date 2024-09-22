//
//  PeopleView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 9/22/24.
//

import SwiftUI

struct PeopleView: View {
    
    let courseID: Int
    @State private var peopleManager: PeopleManager
    
    init(courseID: Int) {
        self.courseID = courseID
        self.peopleManager = PeopleManager(courseID: courseID)
    }
    
    var body: some View {
        List(peopleManager.users, id: \.id) { user in
            if let name = user.name {
                Text(name)
            }
        }
        .task {
            await peopleManager.fetchPeople()
        }
    }
}

#Preview {
    PeopleView(courseID: 416526)
}
