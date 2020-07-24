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
    
    var isStandalone: Bool {
        switch self {
        case .standaloneCategories:
            return true
        case .topCategory:
            return false
        }
    }
}

extension CategoryGroupState: TCAIdentifiable {
    
    static var standaloneGroupId: String { "standaloneGroup" }
    
    var id: String {
        switch self {
        case .standaloneCategories:
            return Self.standaloneGroupId
        case .topCategory(let topCategory):
            return topCategory.id
        }
    }
}

extension CategoryGroupState: DifferentiableSection {
    init<C>(source: Self, elements: C) where C : Collection, C.Element == Self.Collection.Element {
        switch source {
        case .standaloneCategories:
            self = .standaloneCategories(Array(elements))
        case .topCategory(var topCategory):
            topCategory.substates = Array(elements)
            self = .topCategory(topCategory)
        }
    }
    
    func isContentEqual(to source: Self) -> Bool {
//        elements.count == source.elements.count &&
//        zip(elements, source.elements).allSatisfy { $0.isContentEqual(to: $1) }
        switch (self, source) {
        case (.standaloneCategories, .standaloneCategories):
            return true
        case let (.topCategory(topCategory), .topCategory(sourceTopCategory)):
            return topCategory.isContentEqual(to: sourceTopCategory)
        default:
            return false
        }
    }
    
    var elements: [CategoryState] {
        switch self {
        case .standaloneCategories(let categories):
            return categories
        case .topCategory(let topCategory):
            if topCategory.isSelected {
                return []
            }
            return topCategory.substates
        }
    }
    
    /// When the content of the header itself changes
    /// or elements below have a change that calls for update of cells, we return true.
    /// Then the stores will be given to differenceKit so that it updates the cells / header that need to.
    func datasourceNeedsUpdate(for new: Self) -> Bool {
        !isContentEqual(to: new)
            || elements.count != new.elements.count
            || !zip(elements, new.elements)
                .allSatisfy {
                    $0.isContentEqual(to: $1)
                    && $0.differenceIdentifier == $1.differenceIdentifier
                }
    }
}

class SectionedUneatenViewController: UIViewController {
    
    fileprivate struct ViewState: Equatable {
        let validateButtonTitle: String
        let validateButtonEnabled: Bool
        let validateButtonHidden: Bool
        let activityIndicatorHidden: Bool
        let headerIndices: [Int]
    }
    
    /// The actions emitted by the view. Should be as close as possible to the user actions. (just like PureAir Inputs). In this case (and probably often) it matches the feature action.
    fileprivate typealias ViewAction = UneatenAction
    
    typealias ElementAction = UneatenCategoryCollectionViewCell.ViewAction
    enum SectionAction {
        case toggleSubcategoryWithId(String)
        case toggleTopCategory
    }
    
    private var store: Store<UneatenState, UneatenAction>!
    private var viewStore: ViewStore<ViewState, ViewAction>!
    
    @IBOutlet weak var increaseCategoriesNameButton: UIButton!
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
        
        self.categoriesCollectionView.delegate = self
        
        
        
        let itemsBuilder = SectionItemsBuilder<CategoryGroupState, SectionAction, CategoryState, ElementAction>
            .init(items: { $0.elements },
                  itemsReloadCondition: { $0.name != $1.name },
                  actionScoping: { id, _ in SectionAction.toggleSubcategoryWithId(id) },
                  cellCreation: { (collectionView, indexPath, categoryStore) in
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "category", for: indexPath) as? UneatenCategoryCollectionViewCell else {
                        assertionFailure()
                        return .init()
                    }
                    let viewStore = ViewStore(categoryStore.scope(state: { $0.view }))
                    cell.configure(viewStore: viewStore)
                    return cell
            })
        
        let headerBuilder = SectionHeaderBuilder<CategoryGroupState, SectionAction>
            .init(headerReloadCondition: { _, _ in false })
            { [weak self] (collectionView, sectionIndex, sectionStore) -> UICollectionReusableView? in
                guard self?.viewStore.headerIndices.contains(sectionIndex) ?? false,
                    let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeaderView", for: IndexPath(row: 0, section: sectionIndex)) as? SectionHeaderView else {
                        return nil
                }
                let viewStore = ViewStore(sectionStore.scope(state: { $0.view }, action: { (_: SectionHeaderView.ViewAction) in .toggleTopCategory }))
                headerView.configure(viewStore: viewStore)
                return headerView
            }

       store
        .scope(state: { $0.groups }, action: UneatenAction.fromSection(sectionId:sectionAction:))
        .bindTo(collectionView: categoriesCollectionView, itemsBuilder: itemsBuilder, headerBuilder: headerBuilder)
        .disposed(by: disposeBag)

        
        // listen to the tapped index
//        categoriesCollectionView.rx.itemSelected.subscribe(onNext: { [weak self] indexpath in
//            self?.viewStore.send(.toggleCategory(index: indexpath.row))
//        })
//        .disposed(by: disposeBag)
        
        increaseCategoriesNameButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.viewStore.send(.append(text: " bla bla", keys: ["beefKey", "turkeyKey"]))
        })
        .disposed(by: disposeBag)
    }
}

extension SectionedUneatenViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        viewStore.headerIndices.contains(section) ? CGSize(width: 30, height: 40) : CGSize.zero
    }
}

extension UneatenState {
    fileprivate var view: SectionedUneatenViewController.ViewState {
        let validateButtonTitle = saved || pendingValidation ? "Aucun changement" : "Valider la sélection"
        let validateButtonEnabled = !saved
        let validateButtonHidden = pendingValidation
        let activityIndicatorHidden = !pendingValidation
        
        return .init(validateButtonTitle: validateButtonTitle, validateButtonEnabled: validateButtonEnabled, validateButtonHidden: validateButtonHidden, activityIndicatorHidden: activityIndicatorHidden, headerIndices: groups.enumerated().filter { !$1.isStandalone }.map { index, _ in index })
    }
}

extension CategoryGroupState {
    var view: SectionHeaderView.ViewState {
        switch self {
        case .standaloneCategories:
            return .empty
        case .topCategory(let topCategory):
            return .init(isSelected: topCategory.isSelected,
                         name: topCategory.name)
        }
    }
}

extension UneatenAction {
    fileprivate static func fromSection(sectionId: String, sectionAction: SectionedUneatenViewController.SectionAction) -> Self {
        switch sectionAction {
        case .toggleTopCategory:
            return .toggleSuperCategory(id: sectionId)
        case .toggleSubcategoryWithId(let id):
            if sectionId == CategoryGroupState.standaloneGroupId {
                return .toggleSubcategory(id: id, parentId: nil)
            } else {
                return .toggleSubcategory(id: id, parentId: sectionId)
            }
            
        }
    }
}
