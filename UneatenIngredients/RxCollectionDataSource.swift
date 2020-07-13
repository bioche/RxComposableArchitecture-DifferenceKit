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

extension ContentIdentifiable where Self: TCAIdentifiable {
    @inlinable
    var differenceIdentifier: ID {
        id
    }
}

extension String: Differentiable { }

class RxFlatCollectionDataSource<Element: Differentiable>: NSObject, RxCollectionViewDataSourceType, UICollectionViewDataSource {
    
    private typealias OnlySection<Element: Differentiable> = ArraySection<String, Element>
    
    private let sectionedDatasource: RxSectionedCollectionDataSource<OnlySection<Element>>
    
    init(cellCreation: @escaping (UICollectionView, IndexPath, Element) -> UICollectionViewCell) {
        sectionedDatasource = .init(cellCreation: cellCreation)
    }
    
    func collectionView(_ collectionView: UICollectionView, observedEvent: Event<[Element]>) {
        sectionedDatasource
            .collectionView(collectionView,
                            observedEvent: observedEvent
                                .map { [OnlySection(model: "only section", elements: $0)] })
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sectionedDatasource.numberOfSections(in: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sectionedDatasource.collectionView(collectionView, numberOfItemsInSection: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        sectionedDatasource.collectionView(collectionView, cellForItemAt: indexPath)
    }
}

class RxSectionedCollectionDataSource<Section: DifferentiableSection>: NSObject, RxCollectionViewDataSourceType, UICollectionViewDataSource, SectionedViewDataSourceType where Section.Collection.Index == Int {
    
    typealias Element = [Section]
    typealias CellModel = Section.Collection.Element
    
    let cellCreation: (UICollectionView, IndexPath, CellModel) -> UICollectionViewCell
    let headerCreation: ((UICollectionView, Int, Section) -> UICollectionReusableView?)?
    var values: Element = []
    
    private let disposeBag = DisposeBag()
    
    /// Init method
    /// - Parameters:
    ///   - cellCreation: Creation of the cell at the specified index
    ///   - headerCreation: Creation of the header for a specific section. For the headers to show, the headerReferenceSize must be set and/or implement the referenceSizeForHeaderInSection method of the collection delegate (apparently it doesn't support autolayout https://stackoverflow.com/questions/39825290/uicollectionview-header-dynamic-height-using-auto-layout ...).
    ///    For the sections where no header is returned, referenceSizeForHeaderInSection should return CGSize.zero
    init(cellCreation: @escaping (UICollectionView, IndexPath, CellModel) -> UICollectionViewCell,
         headerCreation: ((UICollectionView, Int, Section) -> UICollectionReusableView?)? = nil) {
        self.cellCreation = cellCreation
        self.headerCreation = headerCreation
    }
    
    func collectionView(_ collectionView: UICollectionView, observedEvent: Event<[Section]>) {
        let source = values
        let target = observedEvent.element ?? []
        let changeset = StagedChangeset(source: source, target: target)
        
        collectionView.reload(using: changeset) { data in
            self.values = data
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        values.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        values[section].elements.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cellCreation(collectionView, indexPath, values[indexPath.section].elements[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let section = values[safe: indexPath.section] else {
            return UICollectionReusableView()
        }
        return headerCreation?(collectionView, indexPath.section, section) ?? UICollectionReusableView()
    }
    
    func section(at index: Int) -> Section {
        values[index]
    }
    
    func cellModel(at indexPath: IndexPath) -> CellModel {
        section(at: indexPath.section).elements[indexPath.row]
    }
    
    func model(at indexPath: IndexPath) throws -> Any {
        cellModel(at: indexPath)
    }
    
}
