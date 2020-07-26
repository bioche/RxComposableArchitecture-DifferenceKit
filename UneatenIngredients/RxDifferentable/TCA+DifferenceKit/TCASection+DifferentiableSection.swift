//
//  TCASection+differenceKit.swift
//  UneatenIngredients
//
//  Created by Bioche on 26/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import ComposableArchitecture
import DifferenceKit

extension TCASection: TCAIdentifiable, ContentIdentifiable, ContentEquatable, DifferentiableSection where Model: TCAIdentifiable, ItemModel: TCAIdentifiable {
    
    public var id: Model.ID { model.id }
    public var differenceIdentifier: Model.ID { model.id }
    public var elements: [TCAItem<ItemModel>] { items }

    public init<C: Swift.Collection>(source: Self, elements: C) where C.Element == TCAItem<ItemModel> {
        self.init(model: source.model, items: Array(elements), modelReloadCondition: source.modelReloadCondition)
    }

    public func isContentEqual(to source: Self) -> Bool {
        !modelReloadCondition(self.model, source.model)
    }
}
