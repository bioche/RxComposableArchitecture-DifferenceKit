//
//  TCADifferentiable.swift
//  UneatenIngredients
//
//  Created by Bioche on 21/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit
import ComposableArchitecture
import RxCocoa
import RxSwift

extension Store {
    static func reloadCondition(_ stateCondition: @escaping (State, State) -> Bool) -> (Store, Store) -> Bool {
        { lStore, rStore in
            stateCondition(ViewStore(lStore, removeDuplicates: { _, _ in false }).state, ViewStore(rStore, removeDuplicates: { _, _ in false }).state)
        }
    }
}


