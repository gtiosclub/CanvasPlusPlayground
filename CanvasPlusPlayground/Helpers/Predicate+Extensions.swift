//
//  Predicate+Extensions.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/22/24.
//
import Foundation

extension Predicate {
    static func isAlwaysTrue<T>() -> Predicate<T> { #Predicate<T> {_ in true} }
}
