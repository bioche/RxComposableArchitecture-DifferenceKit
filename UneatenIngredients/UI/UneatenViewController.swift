//
//  UneatenViewController.swift
//  CookEat
//
//  Created by Bioche on 05/07/2020.
//  Copyright © 2020 SEB. All rights reserved.
//

import UIKit
import ComposableArchitecture
import DifferenceKit
import RxCocoa
import RxSwift

// tableView
  // Section --> CategoryState
    // Header --> CategoryHeaderState (isSelected + image)
    // TopCategoryCell --> [CategoryState]
      // CollectionView
        // CollectionCell --> CategoryState
        // CollectionCell --> CategoryState


// The collectionView can be hidden --> size variation

// tableView
  // TopCategoryCell
    // headerView
    // CollectionView
      // CollectionCell
      // CollectionCell


class UneatenViewController: UIViewController {
    /// The state of the view. Should be as close as possible to the view contents. (just like PureAir Outputs)
    fileprivate struct ViewState: Equatable {
        let validateButtonTitle: String
        let validateButtonEnabled: Bool
        let validateButtonHidden: Bool
        let activityIndicatorHidden: Bool
        
        // this should probably not be here. Currently, each time a cell will be tapped, we will reload the whole collection view ...
        let cellStates: [UneatenCategoryCollectionViewCell.ViewState]
    }
    
    /// The actions emitted by the view. Should be as close as possible to the user actions. (just like PureAir Inputs). In this case (and probably often) it matches the feature action.
    fileprivate typealias ViewAction = UneatenAction
    
    private var store: Store<UneatenState, UneatenAction>!
    private var viewStore: ViewStore<ViewState, ViewAction>!
    
    @IBOutlet private weak var validateButton: UIButton!
    @IBOutlet private weak var categoriesCollectionView: UICollectionView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    private let disposeBag = DisposeBag()
    
    static func create(store: Store<UneatenState, UneatenAction>) -> UneatenViewController {
        guard let controller = UIStoryboard(name: "uneaten", bundle: .main).instantiateViewController(withIdentifier: "main") as? UneatenViewController else {
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
        
        // fill the collection with cell states
        let datasource = RxFlatCollectionDataSource<Store<CategoryState, Never>> { (collectionView, indexPath, categoryStore) -> UICollectionViewCell in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "category", for: indexPath) as? UneatenCategoryCollectionViewCell else {
                assertionFailure()
                return .init()
            }
            cell.configure(store: categoryStore)
            return cell
        }
    
        store.actionless
            .scope(state: { $0.categoriesStates })
            .scopeForEach(shouldAvoidReload: { $0.isContentEqual(to: $1) })
            .debug("scopeForEach")
            .drive(categoriesCollectionView.rx.items(dataSource: datasource))
            .disposed(by: disposeBag)
        
        // listen to the tapped index
        categoriesCollectionView.rx.itemSelected.subscribe(onNext: { [weak self] indexpath in
            self?.viewStore.send(.toggleCategory(index: indexpath.row))
        })
        .disposed(by: disposeBag)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.viewStore.send(.append(text: "bsdfsdf sdfdsf"))
        }
    }
}

extension CategoryState: Differentiable { }

extension Store: Differentiable where State: Differentiable {
    public func isContentEqual(to source: Store<State, Action>) -> Bool {
        ViewStore(self, removeDuplicates: { _, _ in false }).state.isContentEqual(to: ViewStore(source, removeDuplicates: { _, _ in false }).state)
    }
    
    public var differenceIdentifier: State.DifferenceIdentifier {
        ViewStore(self, removeDuplicates: { _, _ in false }).differenceIdentifier
    }
}

extension UneatenState {
    fileprivate var view: UneatenViewController.ViewState {
        let validateButtonTitle = saved || pendingValidation ? "Aucun changement" : "Valider la sélection"
        let validateButtonEnabled = !saved
        let validateButtonHidden = pendingValidation
        let activityIndicatorHidden = !pendingValidation
        let cellStates = categoriesStates.map { $0.view }
        
        return .init(validateButtonTitle: validateButtonTitle, validateButtonEnabled: validateButtonEnabled, validateButtonHidden: validateButtonHidden, activityIndicatorHidden: activityIndicatorHidden, cellStates: cellStates)
    }
}
