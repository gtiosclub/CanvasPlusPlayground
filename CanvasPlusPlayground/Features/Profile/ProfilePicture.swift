//
//  ProfilePicture.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/4/25.
//

import SwiftUI

struct ProfilePicture: View {
    let user: User

    var body: some View {
        AsyncImage(url: user.avatarURL) { image in
            image
                .resizable()
                .clipShape(.circle)
        } placeholder: {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundColor(.gray)
        }
        .overlay {
            Circle()
                .stroke(lineWidth: 1)
                .fill(.separator)
        }
    }
}
