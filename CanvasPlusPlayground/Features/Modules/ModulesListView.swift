//
//  ModulesListView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/3/25.
//

import SwiftUI

struct ModulesListView: View {
    @Environment(NavigationModel.self) var navigationModel
    @State private var modulesVM: ModulesViewModel
    @State private var isLoadingModules: Bool = false
    @State private var selectedModule: ModuleItem?

    init(courseId: String) {
        let modulesVM = ModulesViewModel(courseID: courseId)
        _modulesVM = State(initialValue: modulesVM)
    }

    var body: some View {
        List(modulesVM.moduleBlocks, selection: $selectedModule) { block in
            ModuleSection(moduleBlock: block)
        }
        #if os(iOS)
        .onAppear {
            selectedModule = nil
        }
        #endif
        .onChange(of: selectedModule) { _, _ in
            Task {
                await handleModuleSelection()
            }
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

    func handleModuleSelection() async {
        if let selectedModule, let urlServiceResult = CanvasURLService.URLServiceResult(
            from: selectedModule.type
        ) {
            await navigationModel
                .handleURLSelection(
                    result: urlServiceResult,
                    courseID: modulesVM.courseID)
        }
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

            Button("Show Prerequisites", systemImage: .infoCircle) {
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
        Label(
            item.title,
            systemImage: urlServiceResult?.systemImageName ?? .squareDashed
        )
        .foregroundStyle(.primary)
        .selectionDisabled(urlServiceResult == nil)
        .padding(.leading, indent)
        .padding(.vertical, 4)
    }
}
