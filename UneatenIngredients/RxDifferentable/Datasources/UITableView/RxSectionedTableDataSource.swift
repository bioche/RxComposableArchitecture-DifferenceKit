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
import ComposableArchitecture
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
class RxSectionedTableDataSource<SectionModel, Item>: NSObject, RxTableViewDataSourceType, UITableViewDataSource, SectionedViewDataSourceType {
    
    typealias Section = TCASection<SectionModel, Item>
    typealias Element = [Section]
    typealias CellModel = Item
    typealias ReloadingClosure = (UITableView, RxSectionedTableDataSource, Event<[Section]>) -> ()
    
    let cellCreation: (UITableView, IndexPath, CellModel) -> UITableViewCell
    let headerCreation: ((UITableView, Int, Section) -> UIView?)?
    let headerTitlesSource: ((UITableView, Int, Section) -> String?)?
    let reloading: ReloadingClosure
    
    var values: Element = []
    
    init(cellCreation: @escaping (UITableView, IndexPath, CellModel) -> UITableViewCell,
         headerCreation: ((UITableView, Int, Section) -> UIView?)? = nil,
         reloading: @escaping ReloadingClosure) {
        self.cellCreation = cellCreation
        self.headerCreation = headerCreation
        self.headerTitlesSource = nil
        self.reloading = reloading
    }
    
    init(cellCreation: @escaping (UITableView, IndexPath, CellModel) -> UITableViewCell,
         headerTitlesSource: ((UITableView, Int, Section) -> String?)? = nil,
         reloading: @escaping ReloadingClosure) {
        self.cellCreation = cellCreation
        self.headerTitlesSource = headerTitlesSource
        self.headerCreation = nil
        self.reloading = reloading
    }
    
    func tableView(_ tableView: UITableView, observedEvent: RxSwift.Event<Element>) {
        reloading(tableView, self, observedEvent)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        values[section].items.count
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
        cellCreation(tableView, indexPath, values[indexPath.section].items[indexPath.row].model)
    }

    func section(at index: Int) -> Section {
        values[index]
    }
    
    func cellModel(at indexPath: IndexPath) -> CellModel {
        section(at: indexPath.section).items[indexPath.row].model
    }
    
    func model(at indexPath: IndexPath) throws -> Any {
        cellModel(at: indexPath)
    }
}

extension RxSectionedTableDataSource where SectionModel: TCAIdentifiable, Item: TCAIdentifiable {
    static func differenceKitReloading(animation: UITableView.RowAnimation) -> ReloadingClosure {
        return { tableView, datasource, observedEvent in
            let source = datasource.values
            let target = observedEvent.element ?? []
            let changeset = StagedChangeset(source: source, target: target)
            
            print("changeset : \(changeset)")
            
            tableView.reload(using: changeset, with: animation) { data in
                datasource.values = data
            }
        }
    }
}
