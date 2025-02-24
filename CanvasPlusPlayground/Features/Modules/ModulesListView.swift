//
//  ModulesListView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/3/25.
//

import SwiftUI

private struct ModuleSection: View {
    typealias ModuleBlock = ModulesViewModel.ModuleBlock

    @Bindable var module: Module
    var moduleItems: [ModuleItem]

    @Environment(ModulesViewModel.self) private var modulesVM

    init(moduleBlock: ModuleBlock) {
        self.module = moduleBlock.module
        self.moduleItems = moduleBlock.items
    }

    var body: some View {
        DisclosureGroup(
            isExpanded: $module.isExpanded,
            content: {
                ForEach(moduleItems) { item in
                    ModuleItemCell(item: item)
                }
            },
            label: {
                title
            }
        )
    }

    var title: some View {
        HStack {
            Text(module.name)

            Spacer()

            Text("Prerequisites: \(prerequisites)")
        }
        .font(.title3)
        .bold()
    }

    var prerequisites: String {
        modulesVM.prerequisites(for: module).map(\.name).joined(separator: ", ")
    }
}

private struct ModuleItemCell: View {
    @Bindable var item: ModuleItem
    var indent: CGFloat {
        CGFloat(item.indent * 10)
    }

    var body: some View {
        Text(item.title)
            .padding(.leading, indent)
    }
}

struct ModulesListView: View {
    @State private var modulesVM: ModulesViewModel
    @State private var isLoadingModules: Bool = false

    init(courseId: String) {
        let modulesVM = ModulesViewModel(courseID: courseId)
        _modulesVM = State(initialValue: modulesVM)
    }

    var body: some View {
        NavigationStack {
            List(modulesVM.moduleBlocks) {block in
                ModuleSection(moduleBlock: block)
            }
            .task {
                isLoadingModules = true
                await modulesVM.fetchModules()
                isLoadingModules = false
            }
            .statusToolbarItem("Modules", isVisible: isLoadingModules)
        }
        .environment(modulesVM)
    }
}
