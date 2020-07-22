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

//protocol TCADifferentiable: TCAIdentifiable {
//
//    func shouldReloadFor(newValue: Self) -> Bool
//}
//
//protocol TCADifferentiableElement: TCADifferentiable {
//
//}
//
//protocol TCADifferentiableSection: TCADifferentiable {
//
//    associatedtype Element: TCADifferentiableElement
//
//    var elements: [Element] { get }
//}

extension Store {
    static func reloadCondition(_ stateCondition: @escaping (State, State) -> Bool) -> (Store, Store) -> Bool {
        { lStore, rStore in
            stateCondition(ViewStore(lStore, removeDuplicates: { _, _ in false }).state, ViewStore(rStore, removeDuplicates: { _, _ in false }).state)
        }
    }
}

extension Store {
    
    // flat. By default no reload of the cell : all goes through the store
    func bindTo<EachState, EachAction>(collectionView: UICollectionView, reloadCondition: @escaping (EachState, EachState) -> Bool = { _, _ in false }, cellCreation: @escaping (UICollectionView, IndexPath, Store<EachState, EachAction>) -> UICollectionViewCell) -> Disposable
        where State == [EachState],
        EachState: TCAIdentifiable,
        Action == (EachState.ID, EachAction) {
        scopeForEach(shouldAvoidReload: { !reloadCondition($0, $1) })
            .debug("scopeForEach")
            .drive(collectionView.rx.items(dataSource: RxFlatCollectionDataSource(cellCreation: cellCreation, reloadingCondition: Store<EachState, EachAction>.reloadCondition(reloadCondition))))
    }
    
    func bindTo<EachState>(collectionView: UICollectionView, reloadCondition: @escaping (EachState, EachState) -> Bool = { _, _ in false }, cellCreation: @escaping (UICollectionView, IndexPath, Store<EachState, Action>) -> UICollectionViewCell) -> Disposable
        where State == [EachState],
        EachState: TCAIdentifiable {
            scope(state: { $0 }, action: { $1 })
                .bindTo(collectionView: collectionView,
                        reloadCondition: reloadCondition,
                        cellCreation: cellCreation)
    }
    
//    func scopeForEach<EachState, EachAction>() -> Driver<[Store<EachState, EachAction>]> where State == [EachState], EachState: TCAIdentifiable, Action == (EachState.ID, EachAction) {
//        scopeForEach(shouldAvoidReload: { !$0.shouldReloadFor(newValue: $1) })
//    }
    
}
