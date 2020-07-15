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

// created to
struct StoreDifferentiableSection<State: DifferentiableSection>: DifferentiableSection
    where State.Collection.Element: TCAIdentifiable {
    
    let store: Store<State, Never>
    let elements: [Store<State.Collection.Element, Never>]
    
    init<C: Swift.Collection>(source: StoreDifferentiableSection<State>, elements: C) where C.Element == Self.Collection.Element {
        fatalError("see if necessary but I don't see why ...")
    }
    
    init(store: Store<State, Never>) {
        self.store = store
        var elements = [Store<State.Collection.Element, Never>]()
        store
            .scope(state: { Array($0.elements) })
            .scopeForEach()
            .drive(onNext: { elements = $0 })
        self.elements = elements
    }
    
    func isContentEqual(to source: StoreDifferentiableSection<State>) -> Bool {
        store.isContentEqual(to: source.store)
    }
    
    var differenceIdentifier: State.DifferenceIdentifier {
        store.differenceIdentifier
    }
}

//extension Store: DifferentiableSection where State: DifferentiableSection,  State.Collection.Element: TCAIdentifiable, Action == Never {
//    public convenience init<C: Collection>(source: Store<State, Action>, elements: C) where C.Element == Store.Collection.Element {
//        fatalError("shouldn't be necessary")
//    }
//
//    public var elements: [Store<State.Collection.Element, Never>] {
//        //TODO : Deal with Action
//        // we keep
//        var result = [Store<State.Collection.Element, Never>]()
//        self.scope(state: { Array($0.elements) })
//            .scopeForEach()
//            .drive(onNext: { result = $0 })
//        return result
//    }
//}


// Store<[Group]> --> Driver<[Store<Group>]>
// Section : Store<Group>
// Element : Store<Category>
