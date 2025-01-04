//
//  ModulesListView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/3/25.
//

import SwiftUI

struct ModulesListView: View {
    @State var modulesVM: ModulesViewModel
    @State var isLoadingModules: Bool = false

    init(courseId: String) {
        let modulesVM = ModulesViewModel(courseID: courseId)
        _modulesVM = State(initialValue: modulesVM)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(modulesVM.moduleBlocks) { block in
                    ModuleSection(moduleBlock: block)
                }
            }
            .listStyle(.bordered)
            .task {
                isLoadingModules = true
                await modulesVM.fetchModules()
                isLoadingModules = false
            }
            .statusToolbarItem("Modules", isVisible: isLoadingModules)
        }
    }
}

struct ModuleSection: View {
    @Bindable var module: Module
    var moduleItems: [ModuleItem]

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

            Text("Prerequisites: \(module.prerequisiteModuleIds)")
        }
        .padding([.vertical, .horizontal], 10)
        .font(.title)
        .bold()
    }
}

struct ModuleItemCell: View {
    @Bindable var item: ModuleItem
    var indent: CGFloat {
        CGFloat(item.indent*10)
    }

    var body: some View {
        Text(item.title)
            .padding(.leading, indent)
    }
}
