//
//  RxCollectionDataSource.swift
//  UneatenIngredients
//
//  Created by Bioche on 12/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import DifferenceKit
import ComposableArchitecture

public extension ContentIdentifiable where Self: TCAIdentifiable {
    var differenceIdentifier: ID {
        id
    }
}

extension String: Differentiable { }

class RxSectionedCollectionDataSource<SectionModel, Item>: NSObject, RxCollectionViewDataSourceType, UICollectionViewDataSource, SectionedViewDataSourceType {
    
    typealias Section = TCASection<SectionModel, Item>
    typealias Element = [Section]
    typealias CellModel = Item
    typealias ReloadingClosure = (UICollectionView, inout [Section], Event<[Section]>) -> ()
    
    let cellCreation: (UICollectionView, IndexPath, Item) -> UICollectionViewCell
    let headerCreation: ((UICollectionView, Int, SectionModel) -> UICollectionReusableView?)?
    let reloading: ReloadingClosure
    
    var values: [Section] = []
    
    /// Init method
    /// - Parameters:
    ///   - cellCreation: Creation of the cell at the specified index
    ///   - headerCreation: Creation of the header for a specific section. For the headers to show, the headerReferenceSize must be set and/or implement the referenceSizeForHeaderInSection method of the collection delegate (apparently it doesn't support autolayout https://stackoverflow.com/questions/39825290/uicollectionview-header-dynamic-height-using-auto-layout ...).
    ///    For the sections where no header is returned, referenceSizeForHeaderInSection should return CGSize.zero
    init(cellCreation: @escaping (UICollectionView, IndexPath, CellModel) -> UICollectionViewCell,
         headerCreation: ((UICollectionView, Int, SectionModel) -> UICollectionReusableView?)? = nil,
         reloading: @escaping ReloadingClosure = fullReloading) {
        self.cellCreation = cellCreation
        self.headerCreation = headerCreation
        self.reloading = reloading
    }
    
    func collectionView(_ collectionView: UICollectionView, observedEvent: Event<[Section]>) {
        reloading(collectionView, &values, observedEvent)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        values.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        values[section].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cellCreation(collectionView, indexPath, values[indexPath.section].items[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let section = values[safe: indexPath.section] else {
            return UICollectionReusableView()
        }
        return headerCreation?(collectionView, indexPath.section, section.model) ?? UICollectionReusableView()
    }
    
    func section(at index: Int) -> Section {
        values[index]
    }
    
    func cellModel(at indexPath: IndexPath) -> CellModel {
        section(at: indexPath.section).items[indexPath.row]
    }
    
    func model(at indexPath: IndexPath) throws -> Any {
        cellModel(at: indexPath)
    }
    
    static var fullReloading: (UICollectionView, inout [Section], Event<[Section]>) -> () {
        return { collectionView, values, observedEvent in
            values = observedEvent.element ?? []
            collectionView.reloadData()
            DispatchQueue.main.async { // avoid weird layout of cells 🧐
                collectionView.performBatchUpdates({ })
            }
        }
    }
}

extension RxSectionedCollectionDataSource where SectionModel: TCAIdentifiable, Item: TCAIdentifiable {
    static var differenceKitReloading: (UICollectionView, inout [Section], Event<[Section]>) -> () {
        { collectionView, values, observedEvent in
                let source = values
                let target = observedEvent.element ?? []
                let changeset = StagedChangeset(source: source, target: target)
                
                print("changeset : \(changeset)")
                
                collectionView.reload(using: changeset) { data in
                    values = data
                }
                // this hack avoids weird header placement when reloading cells (the header seems to be floating above the cells ... spooky stuff)
                collectionView.performBatchUpdates({ })
        }
    }
}
