//
//  TCASection.swift
//  UneatenIngredients
//
//  Created by Bioche on 26/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation

public struct TCASection<Model, ItemModel> {
     let model: Model
     let items: [TCAItem<ItemModel>]
     let modelReloadCondition: ReloadCondition<Model>

     init(model: Model, items: [TCAItem<ItemModel>], modelReloadCondition: @escaping ReloadCondition<Model>) {
        self.model = model
        self.items = items
        self.modelReloadCondition = modelReloadCondition
    }
}
