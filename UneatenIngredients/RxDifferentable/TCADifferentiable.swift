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

typealias CellCreation<EachState, EachAction>
    = (UICollectionView, IndexPath, Store<EachState, EachAction>) -> UICollectionViewCell
typealias HeaderCreation<HeaderState, HeaderAction>
    = (UICollectionView, Int, Store<HeaderState, HeaderAction>) -> UICollectionReusableView?

extension Store {
    
    // flat. By default no reload of the cell : all goes through the store
    func bind<EachState, EachAction>(collectionView: UICollectionView,
                                     to datasource: RxFlatCollectionDataSource<Store<EachState, EachAction>>,
                                       reloadCondition: @escaping (EachState, EachState) -> Bool = { _, _ in false }) -> Disposable
        where State == [EachState],
        EachState: TCAIdentifiable,
        Action == (EachState.ID, EachAction) {
            
            return scopeForEach(reloadCondition: reloadCondition)
                .debug("scopeForEach")
                .drive(collectionView.rx.items(dataSource: datasource))
    }
    
    func bind<EachState>(collectionView: UICollectionView,
                         to datasource: RxFlatCollectionDataSource<Store<EachState, Action>>,
                         reloadCondition: @escaping (EachState, EachState) -> Bool = { _, _ in false }) -> Disposable
        where State == [EachState],
        EachState: TCAIdentifiable {
            scope(state: { $0 }, action: { $1 })
                .bind(collectionView: collectionView,
                      to: datasource,
                      reloadCondition: reloadCondition)
    }
    
    func bind<SectionState, SectionAction, ItemState, ItemAction>
        (collectionView: UICollectionView,
         to datasource: RxSectionedCollectionDataSource<Store<SectionState, SectionAction>, Store<ItemState, ItemAction>>,
         itemsBuilder: SectionItemsBuilder<SectionState, SectionAction, ItemState, ItemAction>) -> Disposable
    where State == [SectionState],
        ItemState: TCAIdentifiable, SectionState: TCAIdentifiable,
        Action == (SectionState.ID, SectionAction)
    {
        /// When the content of the header itself changes
        /// or elements below have a change that calls for update of cells, we return true.
        /// Then the stores will be given to differenceKit so that it updates the cells / header that need to.
        let sectionReloadCondition: (SectionState, SectionState) -> Bool = {
            itemsBuilder.headerReloadCondition($0, $1)
                || itemsBuilder.items($0).count != itemsBuilder.items($1).count
                || !zip(itemsBuilder.items($0), itemsBuilder.items($1))
                    .allSatisfy {
                        !itemsBuilder.itemsReloadCondition($0, $1)
                            && $0.id == $1.id
                    }
        }
        
        return scopeForEach(reloadCondition: sectionReloadCondition) // --> Only reload when a difference that can't be handled by the stores themselves is detected.
            .debug("scopeForEach")
            .map { $0.map { store in
                var elements = [Store<ItemState, ItemAction>]()
                let disposable = store.scope(state: { itemsBuilder.items($0) }, action: itemsBuilder.actionScoping)
                    .scopeForEach()
                    .drive(onNext: { elements = $0 })
                disposable.dispose()
                return TCASection(model: store, items: elements, modelReloadCondition: Store<SectionState, SectionAction>.reloadCondition(itemsBuilder.headerReloadCondition), itemReloadCondition: Store<ItemState, ItemAction>.reloadCondition(itemsBuilder.itemsReloadCondition))
                }
            }
            .drive(collectionView.rx.items(dataSource: datasource))
    } 
}

struct SectionItemsBuilder<SectionState: TCAIdentifiable, SectionAction, ItemState: TCAIdentifiable, ItemAction> {
    /// Gives the items for each section
    let items: (SectionState) -> [ItemState]
    /// Return true when the difference can't be handled by stores
    /// thus requiring a reload of the cell (typically a change of cell size)
    /// Doesn't need to take id change into consideration as it's not a reload but a move
    let itemsReloadCondition: (ItemState, ItemState) -> Bool
    /// Condition to reload the header. This will reload the full section as well.
    /// Doesn't need to take id change into consideration as it's not a reload but a move
    let headerReloadCondition: (SectionState, SectionState) -> Bool
    let actionScoping: (ItemState.ID, ItemAction) -> SectionAction
}

extension SectionItemsBuilder where ItemAction == SectionAction {
    init(items: @escaping (SectionState) -> [ItemState],
         itemsReloadCondition: @escaping (ItemState, ItemState) -> Bool,
         headerReloadCondition: @escaping (SectionState, SectionState) -> Bool,
         cellCreation: @escaping CellCreation<ItemState, ItemAction>) {
        self.init(items: items,
                  itemsReloadCondition: itemsReloadCondition,
                  headerReloadCondition: headerReloadCondition,
                  actionScoping: { $1 })
    }
}
