//
//  ProfilePicture.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/4/25.
//

import SwiftUI

#if os(macOS)
private typealias PlatformImage = NSImage
#else
private typealias PlatformImage = UIImage
#endif

struct ProfilePicture: View {
    let user: User
    var size: CGFloat

    internal init(user: User, size: CGFloat) {
        assert(size > 0, "Size must be greater than 0")

        self.user = user
        self.size = size
    }

    var body: some View {
        Group {
            if user.hasAvatar,
                let imageData = user.avatarImageData,
                let image = PlatformImage(data: imageData) {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .clipShape(.circle)
                #else
                Image(uiImage: image)
                    .resizable()
                    .clipShape(.circle)
                #endif
            } else {
                Image(systemName: "person.circle")
                    .font(.system(size: size))
            }
        }
        .frame(width: size, height: size)
        .overlay {
            if user.hasAvatar {
                Circle()
                    .strokeBorder(Color(white: 0.35), lineWidth: size/40.0)
                    .blendMode(.luminosity)
            }
        }
        .task {
            guard user.hasAvatar, let url = user.avatarURL else { return }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                user.avatarImageData = data
            } catch {
                print("Error loading image: \(error)")
            }
        }
    }
}
