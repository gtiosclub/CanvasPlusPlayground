//
//  LookupCondition.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/8/24.
//

import Foundation

/// M -> Model type, V -> field value type
enum LookupCondition<M: Cacheable, V: Equatable> {
    case equals(keypath: KeyPath<M, V>, value: V)
    case contains(keypath: KeyPath<M, String>, value: String)
    
    func expression() -> Predicate<M> {
        return Predicate<M> { model in
            
            switch self {
                
            case let .equals(keypath, value):
                PredicateExpressions.build_Equal(
                    lhs: PredicateExpressions.KeyPath(root: model, keyPath: keypath),
                    rhs: PredicateExpressions.Value(value)
                ) as! any StandardPredicateExpression<Bool>
            
            case let .contains(keypath, value):
                PredicateExpressions.build_contains(
                    PredicateExpressions.KeyPath(root: model, keyPath: keypath),
                    PredicateExpressions.Value(value)
                ) as! any StandardPredicateExpression<Bool>
                
            }
            
        }

    }
}
