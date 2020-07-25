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

class RxFlatCollectionDataSource<Item>: NSObject, RxCollectionViewDataSourceType, UICollectionViewDataSource {
    
    let cellCreation: (UICollectionView, IndexPath, Item) -> UICollectionViewCell
    let reloading: ReloadingClosure
    var values = [Item]()
    
    typealias ReloadingClosure = (UICollectionView, RxFlatCollectionDataSource, Event<[Item]>) -> ()
    
    init(cellCreation: @escaping (UICollectionView, IndexPath, Item) -> UICollectionViewCell,
         reloadingClosure: @escaping ReloadingClosure = fullReloading) {
        self.cellCreation = cellCreation
        self.reloading = reloadingClosure
    }
    
    func collectionView(_ collectionView: UICollectionView, observedEvent: Event<[Item]>) {
        reloading(collectionView, self, observedEvent)
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
    
    static var fullReloading: ReloadingClosure {
        return { collectionView, datasource, observedEvent in
            datasource.values = observedEvent.element ?? []
            collectionView.reloadData()
            
            // avoid weird layout of cells 🧐
            collectionView.performBatchUpdates({ })
        }
    }
}

extension RxFlatCollectionDataSource where Item: TCAIdentifiable&Differentiable {
    static var differenceKitReloading: ReloadingClosure {
        return { collectionView, datasource, observedEvent in
            let source = datasource.values
            let target = observedEvent.element ?? []
            let changeset = StagedChangeset(source: source, target: target)
            
            print("changeset : \(changeset)")
            
            collectionView.reload(using: changeset) { data in
                datasource.values = data
            }
            
            // this hack avoids weird header placement when reloading cells (the header seems to be floating above the cells ... spooky stuff)
            collectionView.performBatchUpdates({ })
        }
    }
}
