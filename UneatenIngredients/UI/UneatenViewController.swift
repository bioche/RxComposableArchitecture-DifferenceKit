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

class UneatenViewController: UIViewController {
    /// The state of the view. Should be as close as possible to the view contents. (just like PureAir Outputs)
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
            let viewStore = ViewStore(categoryStore.scope(state: { $0.view }))
            cell.configure(viewStore: viewStore)
            return cell
        }
    
        // we bind the store to the table view cells using differenceKit.
        store.actionless // remove the action --> No action on cell
            .scope(state: { $0.categoriesStates }) // --> just simplify the store to a simple array of categories
            .scopeForEach(shouldAvoidReload: { $0.isContentEqual(to: $1) }) // --> Create one store for each category
            .debug("scopeForEach")
            .drive(categoriesCollectionView.rx.items(dataSource: datasource)) // --> Bind to the datasource --> The stores will be set in the cells
            .disposed(by: disposeBag)
        
        // listen to the tapped index
        categoriesCollectionView.rx.itemSelected.subscribe(onNext: { [weak self] indexpath in
            self?.viewStore.send(.toggleCategory(index: indexpath.row))
        })
        .disposed(by: disposeBag)
        
        // Just a dummy test of the cell size increase
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.viewStore.send(.append(text: "bla bla bla"))
        }
    }
}

extension UneatenState {
    fileprivate var view: UneatenViewController.ViewState {
        let validateButtonTitle = saved || pendingValidation ? "Aucun changement" : "Valider la sélection"
        let validateButtonEnabled = !saved
        let validateButtonHidden = pendingValidation
        let activityIndicatorHidden = !pendingValidation
        
        return .init(validateButtonTitle: validateButtonTitle, validateButtonEnabled: validateButtonEnabled, validateButtonHidden: validateButtonHidden, activityIndicatorHidden: activityIndicatorHidden)
    }
}
