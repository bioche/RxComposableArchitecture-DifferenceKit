//
//  TCAItem.swift
//  UneatenIngredients
//
//  Created by Bioche on 26/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation

public struct TCAItem<Model> {
    let model: Model
    let modelReloadCondition: (Model, Model) -> Bool
    
    init(model: Model, modelReloadCondition: @escaping (Model, Model) -> Bool) {
        self.model = model
        self.modelReloadCondition = modelReloadCondition
    }
}
