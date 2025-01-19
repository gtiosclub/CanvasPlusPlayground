//
//  LoadingMethod.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/19/25.
//

import Foundation

enum LoadingMethod<R: APIRequest> {
    case page(order: Int), all(onNewPage: ([R.Subject.Model]) -> Void)
}
