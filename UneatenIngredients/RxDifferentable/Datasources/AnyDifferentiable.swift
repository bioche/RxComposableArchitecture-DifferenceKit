//
//  AnyDifferentiable.swift
//  UneatenIngredients
//
//  Created by Bioche on 22/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import DifferenceKit
import ComposableArchitecture

/// For internal purposes only.
struct AnyDifferentiable<Base: TCAIdentifiable>: Differentiable {
    
    let base: Base
    let contentEquality: (Base, Base) -> Bool
    
    func isContentEqual(to source: AnyDifferentiable<Base>) -> Bool {
        contentEquality(base, source.base)
    }
    
    var differenceIdentifier: Base.ID {
        base.id
    }
}
