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

public class RxFlatCollectionDataSource<ItemModel>: NSObject, RxCollectionViewDataSourceType, UICollectionViewDataSource {
    
    let cellCreation: (UICollectionView, IndexPath, ItemModel) -> UICollectionViewCell
    let reloading: ReloadingClosure
    var values = [Item]()
    
    typealias Item = TCAItem<ItemModel>
    typealias ReloadingClosure = (UICollectionView, RxFlatCollectionDataSource, Event<[Item]>) -> ()
    
    init(cellCreation: @escaping (UICollectionView, IndexPath, ItemModel) -> UICollectionViewCell,
         reloadingClosure: @escaping ReloadingClosure = fullReloading) {
        self.cellCreation = cellCreation
        self.reloading = reloadingClosure
    }
    
    public func collectionView(_ collectionView: UICollectionView, observedEvent: Event<[Item]>) {
        reloading(collectionView, self, observedEvent)
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        values.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cellCreation(collectionView, indexPath, values[indexPath.row].model)
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

extension RxFlatCollectionDataSource where ItemModel: TCAIdentifiable {
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
