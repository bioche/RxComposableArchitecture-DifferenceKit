//
//  RxFlatCollectionDataSource.swift
//  UneatenIngredients
//
//  Created by Bioche on 22/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import ComposableArchitecture
import DifferenceKit

struct DummyShit<Item> {
    
}

extension DummyShit where Item: TCAIdentifiable {
    
}


class RxFlatCollectionDataSource<Item>: NSObject, UICollectionViewDataSource {
    
    let cellCreation: (UICollectionView, IndexPath, Item) -> UICollectionViewCell
    let reloadingCondition: (Item, Item) -> Bool
    var values = [Item]()
    
    init(cellCreation: @escaping (UICollectionView, IndexPath, Item) -> UICollectionViewCell, reloadingCondition: @escaping (Item, Item) -> Bool) {
        self.cellCreation = cellCreation
        self.reloadingCondition = reloadingCondition
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        values.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cellCreation(collectionView, indexPath, values[indexPath.row])
    }
}

extension RxFlatCollectionDataSource: RxCollectionViewDataSourceType where Item:TCAIdentifiable {
    func collectionView(_ collectionView: UICollectionView, observedEvent: Event<[Item]>) {
        let reloadingCondition = self.reloadingCondition
        let source = values.map { AnyDifferentiable(base: $0, contentEquality: { !reloadingCondition($0, $1) }) }
        let target = observedEvent.element?
            .map { AnyDifferentiable(base: $0, contentEquality: { !reloadingCondition($0, $1) }) } ?? []
        let changeset = StagedChangeset(source: source, target: target, section: 0)
        
        print("changeset : \(changeset)")
        
        UIView.animate(withDuration: 1, animations: {
            collectionView.reload(using: changeset) { data in
                self.values = data.map { $0.base }
            }
            // this hack avoids weird header placement when reloading cells (the header seems to be floating above the cells ... spooky stuff)
            collectionView.performBatchUpdates({ })
        })
    }
}
