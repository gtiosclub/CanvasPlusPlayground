//
//  LoadingMethod.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/19/25.
//

import Foundation

enum LoadingMethod<R: APIRequest> {
    /// page `order` must be > 1
    case page(order: Int), all(onNewPage: ([R.Subject.Model]) -> Void)
}
