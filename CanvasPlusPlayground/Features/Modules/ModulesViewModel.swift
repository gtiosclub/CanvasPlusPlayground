//
//  ModulesViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/3/25.
//

import Foundation

@Observable
class ModulesViewModel {
    private var _modules = [Module]()
    private var _moduleItems = [ModuleItem]()

    private let courseID: String

    init(_courseID: String) {
        self.courseID = _courseID
    }

    var modules: [ModuleBlock] {
        _modules
            .sorted { $0.position < $1.position }
            .map { module in
                let items = _moduleItems
                    .sorted { $0.position < $1.position }
                    .filter {
                        String($0.moduleID) == module.id
                    }
                return ModuleBlock(module: module, items: items)
            }
    }

    struct ModuleBlock {
        let module: Module
        let items: [ModuleItem]
    }

    func fetchModules() async {
        do {
            self._modules = try await CanvasService.shared
                .loadAndSync(
                    CanvasRequest.getModules(courseId: courseID),
                    onCacheReceive: setModules(_:),
                    onNewBatch: setModules(_:)
                ) as [Module]

            await withTaskGroup(of: Void.self) { group in
                for module in self._modules {
                    group.addTask {
                        await self.fetchModuleItems(for: module.id)
                    }
                }
            }

        } catch {
            print("Error fetching modules: \(error)")
        }

    }

    func fetchModuleItems(for moduleId: String) async {
        do {
            let request = CanvasRequest.getModuleItems(courseId: courseID, moduleId: moduleId)
            try await CanvasService.shared
                .loadAndSync(
                    request,
                    onCacheReceive: setModuleItems(_:),
                    onNewBatch: setModuleItems(_:)
                )

        } catch {
            print("Error fetching module items: \(error)")
        }
    }

    private func setModules(_ modules: [Module]?) {
        guard let modules else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self._modules = Array(Set(modules + _modules))
        }
    }

    private func setModuleItems(_ moduleItems: [ModuleItem]?) {
        guard let moduleItems else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self._moduleItems = Array(Set(moduleItems + _moduleItems))
        }
    }

}
