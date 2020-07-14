//
//  Store+differentiable.swift
//  UneatenIngredients
//
//  Created by Bioche on 14/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import DifferenceKit
import ComposableArchitecture

extension Store: Differentiable where State: Differentiable {
    public func isContentEqual(to source: Store<State, Action>) -> Bool {
        ViewStore(self, removeDuplicates: { _, _ in false }).state.isContentEqual(to: ViewStore(source, removeDuplicates: { _, _ in false }).state)
    }
    
    public var differenceIdentifier: State.DifferenceIdentifier {
        ViewStore(self, removeDuplicates: { _, _ in false }).differenceIdentifier
    }
}
