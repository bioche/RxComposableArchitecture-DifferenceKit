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

class RxFlatCollectionDataSource<Element: TCAIdentifiable>: NSObject, RxCollectionViewDataSourceType, UICollectionViewDataSource {
    
    let cellCreation: (UICollectionView, IndexPath, Element) -> UICollectionViewCell
    let reloadingCondition: (Element, Element) -> Bool
    var values = [AnyDifferentiable<Element>]()
    
    init(cellCreation: @escaping (UICollectionView, IndexPath, Element) -> UICollectionViewCell, reloadingCondition: @escaping (Element, Element) -> Bool) {
        self.cellCreation = cellCreation
        self.reloadingCondition = reloadingCondition
    }
    
    func collectionView(_ collectionView: UICollectionView, observedEvent: Event<[Element]>) {
        let reloadingCondition = self.reloadingCondition
        let source = values
        let target = observedEvent.element?
            .map { AnyDifferentiable(base: $0, contentEquality: { !reloadingCondition($0, $1) }) } ?? []
        let changeset = StagedChangeset(source: source, target: target, section: 0)
        
        print("changeset : \(changeset)")
        
        UIView.animate(withDuration: 1, animations: {
            collectionView.reload(using: changeset) { data in
                self.values = data
            }
            // this hack avoids weird header placement when reloading cells (the header seems to be floating above the cells ... spooky stuff)
            collectionView.performBatchUpdates({ })
        })
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        values.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cellCreation(collectionView, indexPath, values[indexPath.row].base)
    }
}
