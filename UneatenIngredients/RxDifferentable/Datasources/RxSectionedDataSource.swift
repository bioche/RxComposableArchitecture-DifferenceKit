//
//  RxSectionedDataSource.swift
//  pureairconnect
//
//  Created by Eric Blachère on 06/12/2019.
//  Copyright © 2019 Eric Blachère. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import DifferenceKit

extension Array {
    public subscript(safe index: Int) -> Element? {
        get {
            guard index >= 0, index < endIndex else {
                return nil
            }

            return self[index]
        }
        set {
            guard index >= 0, index < endIndex, let newValue = newValue else {
                return
            }
            self[index] = newValue
        }
    }
}

/// Allows for simple table view animations on changes based on DifferenceKit. (Avoids the heaviness of RxDatasource)
class RxSectionedDataSource<Section: DifferentiableSection>: NSObject, RxTableViewDataSourceType, UITableViewDataSource, SectionedViewDataSourceType where Section.Collection.Index == Int {
    
    // The Element of RxTableViewDatasource represents the whole datasource
    typealias Element = [Section]
    typealias CellModel = Section.Collection.Element
    
    let animation: UITableView.RowAnimation
    let cellCreation: (UITableView, IndexPath, CellModel) -> UITableViewCell
    let headerCreation: ((UITableView, Int, Section) -> UIView?)?
    let headerTitlesSource: ((UITableView, Int, Section) -> String?)?
    var values: Element = []
    
    private let disposeBag = DisposeBag()
    
    init(with animation: UITableView.RowAnimation = .fade,
         cellCreation: @escaping (UITableView, IndexPath, CellModel) -> UITableViewCell,
         headerCreation: ((UITableView, Int, Section) -> UIView?)? = nil) {
        self.animation = animation
        self.cellCreation = cellCreation
        self.headerCreation = headerCreation
        self.headerTitlesSource = nil
    }
    
    init(with animation: UITableView.RowAnimation = .fade,
         cellCreation: @escaping (UITableView, IndexPath, CellModel) -> UITableViewCell,
         headerTitlesSource: ((UITableView, Int, Section) -> String?)? = nil) {
        self.animation = animation
        self.cellCreation = cellCreation
        self.headerTitlesSource = headerTitlesSource
        self.headerCreation = nil
    }
    
    func tableView(_ tableView: UITableView, observedEvent: RxSwift.Event<Element>) {
        let source = values
        let target = observedEvent.element ?? []
        let changeset = StagedChangeset(source: source, target: target)
        
        tableView.isEditing = false
        
        tableView.reload(using: changeset, with: animation) { data in
            self.values = data
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        values[section].elements.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        values.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIndex: Int) -> String? {
        guard let section = values[safe: sectionIndex] else {
            return nil
        }
        return headerTitlesSource?(tableView, sectionIndex, section)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection sectionIndex: Int) -> UIView? {
        guard let section = values[safe: sectionIndex] else {
            return nil
        }
        return headerCreation?(tableView, sectionIndex, section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellCreation(tableView, indexPath, values[indexPath.section].elements[indexPath.row])
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
