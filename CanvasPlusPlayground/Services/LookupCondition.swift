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
    
    func expression() -> Predicate<M> {
        return Predicate<M> { model in
            
            switch self {
                
            case let .equals(keypath, value):
                PredicateExpressions.build_Equal(
                    lhs: PredicateExpressions.KeyPath(root: model, keyPath: keypath),
                    rhs: PredicateExpressions.Value(value)
                ) as! any StandardPredicateExpression<Bool>
            
            }
            
        }

    }
}
