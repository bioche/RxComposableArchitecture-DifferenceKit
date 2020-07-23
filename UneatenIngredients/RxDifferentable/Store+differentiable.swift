//
//  Store+differentiable.swift
//  UneatenIngredients
//
//  Created by Bioche on 14/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
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

extension Store: TCAIdentifiable where State: TCAIdentifiable {
    public var id: State.ID {
        ViewStore(self, removeDuplicates: {_, _ in false }).id
    }
}

// created to
struct StoreDifferentiableSection<SectionState: TCAIdentifiable, SectionAction, ItemState: TCAIdentifiable, ItemAction>: DifferentiableSection {

    let store: Store<SectionState, SectionAction>
    let elements: [AnyStoreDifferentiable<ItemState, ItemAction>]

    let headerReloadCondition: (SectionState, SectionState) -> Bool

    init<C: Swift.Collection>(source: Self, elements: C) where C.Element == Self.Collection.Element {
        self.store = source.store
        self.elements = Array(elements)
        self.headerReloadCondition = source.headerReloadCondition
    }

    init(store: Store<SectionState, SectionAction>, itemStores: [Store<ItemState, ItemAction>], headerReloadCondition: @escaping (SectionState, SectionState) -> Bool, itemReloadCondition: @escaping (ItemState, ItemState) -> Bool) {
        self.store = store
        self.elements = itemStores
            .map { AnyStoreDifferentiable(store: $0, contentEquality: { !itemReloadCondition($0, $1) } ) }
        self.headerReloadCondition = headerReloadCondition
    }

    func isContentEqual(to source: Self) -> Bool {
        !Store.reloadCondition(headerReloadCondition)(self.store, source.store)
    }

    var differenceIdentifier: SectionState.ID { store.id }
}
