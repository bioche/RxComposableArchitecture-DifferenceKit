//
//  Store+ReloadCondition.swift
//  UneatenIngredients
//
//  Created by Bioche on 27/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import ComposableArchitecture

extension Store {
    static func reloadCondition(_ stateCondition: @escaping ReloadCondition<State>) -> ReloadCondition<Store<State, Action>> {
        { lStore, rStore in
            stateCondition(ViewStore(lStore, removeDuplicates: { _, _ in false }).state, ViewStore(rStore, removeDuplicates: { _, _ in false }).state)
        }
    }
}
