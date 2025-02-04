//
//  ProfileView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/4/25.
//

import SwiftUI

struct ProfileView: View {
    @Environment(ProfileManager.self) private var profileManager
    @Environment(\.dismiss) private var dismiss

    let user: User
    var showCommonCourses: Bool = true

    @State private var profile: Profile? // needed to get email for curr user

    var body: some View {
        Form {
            Section {
                header
                    .listRowBackground(Color.clear)
            }

            details

            if showCommonCourses {
                PeopleCommonView(user: user)
            }
        }
        .formStyle(.grouped)
        .task {
            profile = await profileManager.getProfile(for: user.id)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .animation(.default, value: profile)
        #if os(macOS)
        .frame(height: 500)
        #endif
    }

    private var header: some View {
        HStack {
            Spacer()
            VStack {
                ProfilePicture(user: user)
                    .frame(width: 100, height: 100)

                VStack(alignment: .center) {
                    Text(user.name)
                        .font(.title)
                        .bold()
                        .padding(.top, 5)
                        .multilineTextAlignment(.center)

                    if let pronouns = user.pronouns {
                        Text(pronouns)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var details: some View {
        if let bio = profile?.bio {
            LabeledContent("Bio", value: bio)
        }

        if let pronunciation = profile?.pronunciation {
            LabeledContent("Pronunciation", value: pronunciation)
        }

        if let email = profile?.primaryEmail {
            LabeledContent("Primary Email", value: email)
        }

        LabeledContent("Short Name", value: user.shortName)

        if !user.enrollmentRoles.isEmpty {
            LabeledContent(
                "Roles",
                value: user.enrollmentRoles.map(\.displayName).joined(separator: ", ")
            )
        }
    }
}

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
