//
//  ModulesViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/3/25.
//

import Foundation

@Observable
class ModulesViewModel {
    private var _modules = Set<Module>()
    private var _moduleItems = Set<ModuleItem>()

    let courseID: String

    init(courseID: String) {
        self.courseID = courseID
    }

    struct ModuleBlock: Identifiable {
        var id: ObjectIdentifier { module.id }
        let module: Module
        let items: [ModuleItem]
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
            try await CanvasService.shared
                .loadAndSync(
                    CanvasRequest.getModules(courseId: courseID),
                    onCacheReceive: {
                        LoggerService.main.debug("Cache: \(($0 ?? []).description)")
                        setModules($0)
                    },
                    loadingMethod: .all(onNewPage: setModules)
                )
        } catch {
            LoggerService.main.error("Error fetching modules: \(type(of: error))")
        }

        await withTaskGroup(of: Void.self) { group in
            LoggerService.main.debug("Iterating over modules: \(self._modules.map(\.name))")
            for module in self._modules {
                LoggerService.main.debug("Adding \(module.name) task.")
                group.addTask {
                    LoggerService.main.debug("Executing \(module.name) task.")
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
                    loadingMethod: .all(onNewPage: setModuleItems(_:))
                )
        } catch {
            LoggerService.main.error("Error fetching module items: \(type(of: error))")
        }

        return []
    }

    private func setModules(_ modules: [Module]?) {
        guard let modules else { return }

        let newModules = Set(modules + _modules)
        self._modules = newModules
        LoggerService.main.debug("Modules have been added: \(modules.map(\.name).description)")
    }

    private func setModuleItems(_ moduleItems: [ModuleItem]?) {
        guard let moduleItems else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let newItems = Set(moduleItems + _moduleItems)
            _moduleItems = newItems
        }
    }
}
