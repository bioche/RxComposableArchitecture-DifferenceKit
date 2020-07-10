//
//  MenuViewController.swift
//  UneatenIngredients
//
//  Created by Bioche on 07/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ComposableArchitecture

/// Navigation handling :
/// State could contain the navigation stack.
/// But who builds the next screen ?
/// who pushes or presents it ?

class MenuViewController: UIViewController {
    
    static func create() -> MenuViewController {
        guard let controller = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "main") as? MenuViewController else {
                fatalError()
        }
        return controller
    }
    
    @IBOutlet weak var uneatenButton: UIButton!
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uneatenButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                let initialState = UneatenState(categoriesStates: [CategoryState(category: UneatenCategory(key: "chickenKey", name: "chicken"), isSelected: false), CategoryState(category: UneatenCategory(key: "SaladKey", name: "salad"), isSelected: false)], saved: true, pendingValidation: false)
                let store = ComposableArchitecture.Store<UneatenState, UneatenAction>(initialState: initialState, reducer: uneatenReducer, environment: UneatenEnvironment(uneatenService: UneatenCategoriesMockService()))
                let uneatenController = UneatenViewController.create(store: store)
                self?.navigationController?.pushViewController(uneatenController, animated: true)
            })
        .disposed(by: disposeBag)
    }
    
}


