//
//  SectionedUneatenViewController.swift
//  UneatenIngredients
//
//  Created by Bioche on 15/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit
import ComposableArchitecture
import DifferenceKit
import RxCocoa
import RxSwift

enum CategoryGroupState: Equatable {
    case standaloneCategories([CategoryState])
    case topCategory(CategoryState)
}

extension CategoryGroupState: TCAIdentifiable {
    var id: String {
        switch self {
        case .standaloneCategories:
            return "standaloneSection"
        case .topCategory(let topCategory):
            return topCategory.id
        }
    }
}

extension CategoryGroupState: DifferentiableSection {
    init<C>(source: Self, elements: C) where C : Collection, C.Element == Self.Collection.Element {
        fatalError("shouldn't be necessary")
    }
    
    func isContentEqual(to source: Self) -> Bool {
        elements.count == source.elements.count &&
            zip(elements, source.elements).allSatisfy { $0.isContentEqual(to: $1) }
    }
    
    var elements: [CategoryState] {
        switch self {
        case .standaloneCategories(let categories):
            return categories
        case .topCategory(let topCategory):
            return topCategory.substates
        }
    }
}

class SectionedUneatenViewController: UIViewController {
    
    fileprivate struct ViewState: Equatable {
        let validateButtonTitle: String
        let validateButtonEnabled: Bool
        let validateButtonHidden: Bool
        let activityIndicatorHidden: Bool
    }
    
    /// The actions emitted by the view. Should be as close as possible to the user actions. (just like PureAir Inputs). In this case (and probably often) it matches the feature action.
    fileprivate typealias ViewAction = UneatenAction
    
    private var store: Store<UneatenState, UneatenAction>!
    private var viewStore: ViewStore<ViewState, ViewAction>!
    
    @IBOutlet private weak var validateButton: UIButton!
    @IBOutlet private weak var categoriesCollectionView: UICollectionView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    private let disposeBag = DisposeBag()
    
    static func create(store: Store<UneatenState, UneatenAction>) -> Self {
        guard let controller = UIStoryboard(name: "uneaten", bundle: .main).instantiateViewController(withIdentifier: "grouped") as? Self else {
            fatalError()
        }
        controller.store = store
        controller.viewStore = ViewStore(store.scope(state: { print("Mapping : \($0.view)"); return $0.view }))
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewStore.driver.validateButtonTitle
            .drive(validateButton.rx.title())
            .disposed(by: disposeBag)
        viewStore.driver.validateButtonEnabled
            .drive(validateButton.rx.isEnabled)
            .disposed(by: disposeBag)
        viewStore.driver.activityIndicatorHidden
            .drive(activityIndicator.rx.isHidden)
            .disposed(by: disposeBag)
        viewStore.driver.validateButtonHidden
            .drive(validateButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        validateButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.viewStore.send(.validateSelection)
        })
        .disposed(by: disposeBag)
        
        categoriesCollectionView.register(UINib(nibName: "SectionHeaderView", bundle: .main), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeaderView")
       // categoriesCollectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeaderView")
        
        let flow = categoriesCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flow.headerReferenceSize = CGSize(width: 30, height: 60)
        
        // fill the collection with cell states
        let datasource = RxSectionedCollectionDataSource<StoreDifferentiableSection<CategoryGroupState>>(cellCreation: { (collectionView, indexPath, categoryStore) -> UICollectionViewCell in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "category", for: indexPath) as? UneatenCategoryCollectionViewCell else {
                assertionFailure()
                return .init()
            }
            let viewStore = ViewStore(categoryStore.scope(state: { $0.view }))
            cell.configure(viewStore: viewStore)
            return cell
        }, headerCreation: { (collectionView: UICollectionView, sectionIndex: Int, section: StoreDifferentiableSection<CategoryGroupState>) -> UICollectionReusableView? in
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeaderView", for: IndexPath(row: 0, section: sectionIndex)) as? SectionHeaderView else {
                return nil
            }
            let viewStore = ViewStore(section.store.scope(state: { $0.view }))
            headerView.configure(viewStore: viewStore)
            return headerView
        })
        
        // we bind the store to the table view cells using differenceKit.
        store
            .actionless
            .scope(state: { $0.groups }) // --> just simplify the store to a simple array of groups
            .scopeForEach(shouldAvoidReload: { $0.isContentEqual(to: $1) }) // --> Create one store for each category
            .debug("scopeForEach")
            .map { $0.map { StoreDifferentiableSection(store: $0) } }
            .drive(categoriesCollectionView.rx.items(dataSource: datasource)) // --> Bind to the datasource --> The stores will be set in the cells
            .disposed(by: disposeBag)
        
        // listen to the tapped index
//        categoriesCollectionView.rx.itemSelected.subscribe(onNext: { [weak self] indexpath in
//            self?.viewStore.send(.toggleCategory(index: indexpath.row))
//        })
//        .disposed(by: disposeBag)
        
    }
}

extension UneatenState {
    fileprivate var view: SectionedUneatenViewController.ViewState {
        let validateButtonTitle = saved || pendingValidation ? "Aucun changement" : "Valider la sélection"
        let validateButtonEnabled = !saved
        let validateButtonHidden = pendingValidation
        let activityIndicatorHidden = !pendingValidation
        
        return .init(validateButtonTitle: validateButtonTitle, validateButtonEnabled: validateButtonEnabled, validateButtonHidden: validateButtonHidden, activityIndicatorHidden: activityIndicatorHidden)
    }
}

extension CategoryGroupState {
    var view: SectionHeaderView.ViewState {
        .init(isSelected: false, name: "trololo")
    }
}
