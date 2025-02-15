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
    var isCurrentUser: Bool

    var profile: Profile? {
        if user.id == profileManager.currentUser?.id {
            return profileManager.currentProfile
        }

        return nil
    }

    init(
        user: User,
        isCurrentUser: Bool = false
    ) {
        self.user = user
        self.isCurrentUser = isCurrentUser
    }

    var body: some View {
        Form {
            Section {
                header
                    .listRowBackground(Color.clear)
            }

            details

            if isCurrentUser {
                SettingsView()
            } else {
                PeopleCommonView(user: user)
            }
        }
        .formStyle(.grouped)
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
                ProfilePicture(user: user, size: 100)
                    .symbolVariant(.fill)

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
