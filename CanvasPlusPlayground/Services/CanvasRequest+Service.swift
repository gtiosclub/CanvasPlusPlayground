//
//  CanvasRequest+Service.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/3/24.
//

import Foundation


extension CanvasRequest {
    /// If the request is for a single model, it returns a filter that checks for the model's id. If the request is for multiple models, it filters based on the model's parent ids.
    func cacheFilter<M: Cacheable & AnyObject>() -> Predicate<M> {
        //let expectedM = self.associatedModel
        //guard let id = self.id else { return #Predicate<M> { _ in true } }
        
        let readKeyPath: KeyPath<M, String> = self.readableIdKeyPath()
        let condition = LookupCondition<M, String>.equals(keypath: readKeyPath, value: self.id)
        return condition.expression()
        
    }
    
    /// The keypath to compare `self.id` to when retrieving cached results of request.
    func writableIdKeypath<M: Cacheable & AnyObject>() -> ReferenceWritableKeyPath<M, String>? {
        switch self {
        case .getCourse:
            return nil
        case .getCourseRootFolder, .getAllCourseFiles, .getAllCourseFolders, .getFilesInFolder, .getFoldersInFolder, .getTabs, .getAnnouncements, .getAssignments, .getPeople, .getCourses:
            return \M.parentId
        }
    }
    
    /// The keypath to compare `self.id` to when retrieving cached results of request.
    func readableIdKeyPath<M: Cacheable & AnyObject>() -> KeyPath<M, String> {
        switch self {
        // Requests that must be identified by the return model's id
        case .getCourse:
            return \M.id
        // Requests that must be identified by the return model's parentId
        case .getCourseRootFolder, .getAllCourseFiles, .getAllCourseFolders, .getFilesInFolder, .getFoldersInFolder, .getTabs, .getAnnouncements, .getAssignments, .getPeople, .getCourses:
            return \M.parentId
        }
    }
}

