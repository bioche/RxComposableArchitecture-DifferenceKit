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
    
    typealias DifferenceIdentifier = Base.ID
    
    let base: Base
    let contentEquality: (Base, Base) -> Bool
    
    init(base: Base, contentEquality: @escaping (Base, Base) -> Bool) {
        self.base = base
        self.contentEquality = contentEquality
    }
    
    func isContentEqual(to source: AnyDifferentiable<Base>) -> Bool {
        contentEquality(base, source.base)
    }
    
    var differenceIdentifier: Base.ID {
        base.id
    }
}

struct AnyStoreDifferentiable<State: TCAIdentifiable, Action>: Differentiable {
    let store: Store<State, Action>
    let contentEquality: (State, State) -> Bool

    func isContentEqual(to source: Self) -> Bool {
        contentEquality(ViewStore(store, removeDuplicates: {_, _ in false}).state, ViewStore(source.store, removeDuplicates: {_, _ in false}).state)
    }

    var differenceIdentifier: State.ID {
        ViewStore(store, removeDuplicates: {_, _ in false}).state.id
    }
}
