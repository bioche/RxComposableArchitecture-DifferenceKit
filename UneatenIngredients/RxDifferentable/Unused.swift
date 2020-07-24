//
//  Unused.swift
//  UneatenIngredients
//
//  Created by Bioche on 23/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import ComposableArchitecture
import DifferenceKit

/// ⚠️ Not used for now as it made the compiler crash when used with stores as mode & item o_0 ⚠️
/// This type can't be "mangled" : RxSectionedCollectionDataSource<AnySection<Store<SectionState, SectionAction>, Store<ItemState, ItemAction>>>
struct TCASection<Model, Item> {
     var model: Model
     var items: [Item]
     let modelReloadCondition: (Model, Model) -> Bool
     let itemReloadCondition: (Item, Item) -> Bool

     init(model: Model, items: [Item], modelReloadCondition: @escaping (Model, Model) -> Bool, itemReloadCondition: @escaping (Item, Item) -> Bool) {
        self.model = model
        self.items = items
        self.itemReloadCondition = itemReloadCondition
        self.modelReloadCondition = modelReloadCondition
    }
}

extension TCASection: TCAIdentifiable, ContentIdentifiable, ContentEquatable, DifferentiableSection where Model: TCAIdentifiable, Item: TCAIdentifiable {
    var id: Model.ID { model.id }

    var differenceIdentifier: Model.ID {
        model.id
    }

    var elements: [AnyDifferentiable<Item>] {
        let reloadCondition = self.itemReloadCondition
        return items.map { AnyDifferentiable(base: $0, contentEquality: { !reloadCondition($0, $1) }) }
    }

     init<C: Swift.Collection>(source: Self, elements: C) where C.Element == AnyDifferentiable<Item> {
        self.init(model: source.model, items: elements.map { $0.base }, modelReloadCondition: source.modelReloadCondition, itemReloadCondition: source.itemReloadCondition)
    }

     func isContentEqual(to source: Self) -> Bool {
        return !modelReloadCondition(self.model, source.model)
    }
}
