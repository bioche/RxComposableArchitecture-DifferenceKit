//
//  UneatenViewController.swift
//  CookEat
//
//  Created by Bioche on 05/07/2020.
//  Copyright © 2020 SEB. All rights reserved.
//

import UIKit
import ComposableArchitecture
import RxCocoa
import RxSwift

protocol UneatenCategoriesService {
    func getPossibleCategories() -> Single<[UneatenCategory]>
    
    func getSelectedCategoriesKeys() -> Single<[String]>
    func save(selectedCategoriesKeys: [String]) -> Single<Void>
}

struct UneatenCategoriesMockService: UneatenCategoriesService {
    static var selectedKeys = [String]()
    
    func getPossibleCategories() -> Single<[UneatenCategory]> {
        .just([UneatenCategory(key: "chickenKey", name: "chicken"), UneatenCategory(key: "SaladKey", name: "salad")])
    }
    
    func getSelectedCategoriesKeys() -> Single<[String]> {
        .just(Self.selectedKeys)
    }
    
    func save(selectedCategoriesKeys: [String]) -> Single<Void> {
        Self.selectedKeys = selectedCategoriesKeys
        return Observable.just(())
            .delay(.seconds(3), scheduler: MainScheduler())
            .asSingle()
    }
}

struct UneatenEnvironment {
    let uneatenService: UneatenCategoriesService
}

struct UneatenCategory {
    let key: String
    let name: String
    //let subcategories: [UneatenCategory] --> we ignore it for now
}

/// The state of the uneaten feature. Later mapped to the ViewState
struct UneatenState {
    var categoriesStates: [CategoryState]
    /// Have the choices been saved
    var saved: Bool
    
    var pendingValidation: Bool
    
    var selectedCategoriesKeys: [String] {
        categoriesStates.compactMap { $0.isSelected ? $0.category.key : nil }
    }
}

struct CategoryState {
    let category: UneatenCategory
    var isSelected: Bool
    
    func selected(_ isSelected: Bool) -> CategoryState {
        .init(category: category, isSelected: isSelected)
    }
    
}

/// The actions of the uneaten feature.
enum UneatenAction {
    case validateSelection
    case toggleCategory(index: Int)
    
    case acknowledgeValidation
}

let uneatenReducer = Reducer<UneatenState, UneatenAction, UneatenEnvironment> { state, action, environment in
    switch action {
    case .validateSelection:
        state.pendingValidation = true
        return Effect(environment.uneatenService.save(selectedCategoriesKeys: state.selectedCategoriesKeys).asObservable()).map { .acknowledgeValidation }
    case .toggleCategory(let index):
        state.saved = false
        state.categoriesStates[index].isSelected.toggle()
    case .acknowledgeValidation:
        state.saved = true
        state.pendingValidation = false
    }
    return .none
}

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
        viewStore.driver.cellStates.drive(categoriesCollectionView.rx.items) { (collectionView, row, config) in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "category", for: IndexPath(row: row, section: 0)) as? UneatenCategoryCollectionViewCell else {
                assertionFailure()
                return .init()
            }
            cell.apply(viewState: config)
            return cell
        }
        .disposed(by: disposeBag)
        
        // listen to the tapped index
        categoriesCollectionView.rx.itemSelected.subscribe(onNext: { [weak self] indexpath in
            self?.viewStore.send(.toggleCategory(index: indexpath.row))
        })
        .disposed(by: disposeBag)
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

class UneatenCategoryCollectionViewCell: UICollectionViewCell {
    struct ViewState: Equatable {
        let imageName: String
        let title: String
        let tint: Color
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    func apply(viewState: ViewState) {
        imageView.image = UIImage(named: viewState.imageName)
        titleLabel.text = viewState.title
        imageView.tintColor = viewState.tint.uiColor
        titleLabel.textColor = viewState.tint.uiColor
    }
}

extension CategoryState {
    var view: UneatenCategoryCollectionViewCell.ViewState {
        .init(imageName: "btn_close", title: category.name, tint: isSelected ? Color(uiColor: .green) : Color(uiColor: .black))
    }
}

/// Codable struct for UIColor
struct Color: Codable, Equatable {
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat = 0.0
    
    /// Returns a UIColor from Color
    var uiColor: UIColor {
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// Init a Color with a UIColor
    ///
    /// - Parameter uiColor: UIColor
    init(uiColor: UIColor?) {
        uiColor?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    }
}
