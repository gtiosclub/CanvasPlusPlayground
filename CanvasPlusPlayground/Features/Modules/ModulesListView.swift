//
//  ModulesListView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/3/25.
//

import SwiftUI

struct ModulesListView: View {
    @State private var modulesVM: ModulesViewModel
    @State private var isLoadingModules: Bool = false

    init(courseId: String) {
        let modulesVM = ModulesViewModel(courseID: courseId)
        _modulesVM = State(initialValue: modulesVM)
    }

    var body: some View {
        List(modulesVM.moduleBlocks) { block in
            ModuleSection(moduleBlock: block)
        }
        .task {
            isLoadingModules = true
            await modulesVM.fetchModules()
            isLoadingModules = false
        }
        .statusToolbarItem("Modules", isVisible: isLoadingModules)
        .environment(modulesVM)
        .navigationTitle("Modules")
    }
}

private struct ModuleSection: View {
    typealias ModuleBlock = ModulesViewModel.ModuleBlock

    @Bindable var module: Module
    var moduleItems: [ModuleItem]

    @Environment(ModulesViewModel.self) private var modulesVM
    @State private var showPrerequisites = false

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
                        .tag(item)
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
                .font(.title3)
                .bold()

            Spacer()

            Button("Show Prerequisites", systemImage: "info.circle") {
                showPrerequisites.toggle()
            }
            .popover(isPresented: $showPrerequisites) {
                prerequisitesView
                    .presentationCompactAdaptation(.popover)
            }
            .buttonStyle(.plain)
            .labelStyle(.iconOnly)
        }
    }

    var prerequisitesView: some View {
        VStack(alignment: .leading) {
            if prerequisites.isEmpty {
                Text("No Prerequisites").bold()
            } else {
                Text("Prerequisites").bold()
                ForEach(prerequisites) { prereq in
                    Text(prereq.name)
                        .fontWeight(.light)
                }
            }
        }
        .padding()
    }

    var prerequisites: [Module] {
        modulesVM.prerequisites(for: module)
    }
}

private struct ModuleItemCell: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(ModulesViewModel.self) private var modulesVM

    @Bindable var item: ModuleItem

    var indent: CGFloat {
        CGFloat(item.indent * 10)
    }

    var urlServiceResult: CanvasURLService.URLServiceResult? {
        .init(from: item.type)
    }

    var body: some View {
        Button(
            item.title,
            systemImage: urlServiceResult?.systemImageName ?? "square.dashed"
        ) {
            if let urlServiceResult {
                Task {
                    await navigationModel
                        .handleURLSelection(
                            result: urlServiceResult,
                            courseID: modulesVM.courseID)
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .disabled(urlServiceResult == nil)
        .padding(.leading, indent)
        .padding(.vertical, 4)
    }
}
