//
//  ParentKeyPath.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/22/24.
//


struct ParentKeyPath<K, V> {
    var writableKeyPath: ReferenceWritableKeyPath<K, V>?
    var readableKeyPath: KeyPath<K, V>
    
    static func createWritable(_ keyPath: ReferenceWritableKeyPath<K, V>) -> Self {
        ParentKeyPath(writableKeyPath: keyPath, readableKeyPath: keyPath)
    }
    
    static func createReadable(_ keyPath: KeyPath<K, V>) -> Self {
        ParentKeyPath(readableKeyPath: keyPath)
    }
}