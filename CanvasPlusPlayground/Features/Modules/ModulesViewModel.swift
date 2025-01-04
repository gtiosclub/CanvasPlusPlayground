//
//  ModulesViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/3/25.
//

import Foundation

struct ModuleBlock: Identifiable {
    var id: ObjectIdentifier { module.id }
    let module: Module
    let items: [ModuleItem]
}

@Observable
class ModulesViewModel {
    private var _modules = Set<Module>()
    private var _moduleItems = Set<ModuleItem>()

    private let courseID: String

    init(courseID: String) {
        self.courseID = courseID
    }

    var moduleBlocks: [ModuleBlock] {
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
        // TODO: handle unassigned items
    }

    func prerequisites(for module: Module) -> [Module] {
        _modules
            .filter {
                module.prerequisiteModuleIds.map(\.asString).contains($0.id)
            }
    }

    func fetchModules() async {
        do {
            let modules = try await CanvasService.shared
                .loadAndSync(
                    CanvasRequest.getModules(courseId: courseID),
                    onCacheReceive: setModules(_:),
                    onNewBatch: setModules(_:)
                ) as [Module]
        } catch {
            print("Error fetching modules: \(error)")
        }

        await withTaskGroup(of: Void.self) { group in
            for module in self._modules {
                group.addTask {
                    await self.fetchModuleItems(for: module.id)
                }
            }
        }
    }

    @discardableResult
    private func fetchModuleItems(for moduleId: String) async -> [ModuleItem] {
        do {
            let request = CanvasRequest.getModuleItems(courseId: courseID, moduleId: moduleId)

            return try await CanvasService.shared
                .loadAndSync(
                    request,
                    onCacheReceive: setModuleItems(_:),
                    onNewBatch: setModuleItems(_:)
                )
        } catch {
            print("Error fetching module items: \(error)")
        }

        return []
    }

    private func setModules(_ modules: [Module]?) {
        guard let modules else { return }

        let newModules = Set(modules + _modules)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self._modules = newModules
        }
    }

    private func setModuleItems(_ moduleItems: [ModuleItem]?) {
        guard let moduleItems else { return }

        let newItems = Set(moduleItems + _moduleItems)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self._moduleItems = newItems
        }
    }

}
