//
//  HomeViewTile.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/28/24.
//

import SwiftUI

struct SidebarTile: View {
    @Environment(NavigationModel.self) private var navigationModel

    let title: String
    let systemIcon: String
    let color: Color
    let page: NavigationModel.NavigationPage
    let action: () -> Void

    init(
        _ title: String,
        systemIcon: String,
        color: Color,
        page: NavigationModel.NavigationPage,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemIcon = systemIcon
        self.color = color
        self.page = page
        self.action = action
    }

    var isSelected: Bool {
        navigationModel.selectedNavigationPage == page
    }

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.plain)
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemIcon)
                    .font(.title)
                    .tint(isSelected ? .white : color)
                    .foregroundStyle(.tint)

                Spacer()
            }
            Text(title)
                .foregroundStyle(isSelected ? .white : .primary)
                .bold()
                .lineLimit(1)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
            #if os(iOS)
                .fill(isSelected ? color : Color(uiColor: .tertiarySystemBackground))
            #else
                .fill(isSelected ? color : .gray.opacity(0.2))
            #endif
        )
        #if os(iOS)
        .padding(2)
        .frame(minWidth: 140)
        #else
        .frame(minWidth: 90)
        #endif
        .tint(color)
    }
}
