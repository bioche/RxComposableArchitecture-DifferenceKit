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
    @IBOutlet weak var groupedUneatenButton: UIButton!
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uneatenButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                let initialState = UneatenState(categoriesStates: [CategoryState(id: "chickenKey", name: "chicken", isSelected: false, substates: []), CategoryState(id: "SaladKey", name: "salad", isSelected: false, substates: [])], saved: true, pendingValidation: false)
                let store = ComposableArchitecture.Store<UneatenState, UneatenAction>(initialState: initialState, reducer: uneatenReducer, environment: UneatenEnvironment(uneatenService: UneatenCategoriesMockService()))
                let uneatenController = UneatenViewController.create(store: store)
                self?.navigationController?.pushViewController(uneatenController, animated: true)
            })
        .disposed(by: disposeBag)
        
        groupedUneatenButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                
                let standaloneCategories = [
                    CategoryState(id: "fishKey", name: "Fish", isSelected: false, substates: [])
                    ,CategoryState(id: "shellfishKey", name: "Shellfish", isSelected: false, substates: [])
                ]
                
                let meatSubCategories = [
                    CategoryState(id: "beefKey", name: "beef", isSelected: false, substates: []),
                    CategoryState(id: "turkeyKey", name: "turkey", isSelected: false, substates: []),
                    CategoryState(id: "chickenKey", name: "chicken", isSelected: false, substates: []),
                    CategoryState(id: "lambKey", name: "lamb", isSelected: false, substates: [])
                ]
                
                let milkySubCategories = [
                    CategoryState(id: "cheeseKey", name: "cheese", isSelected: false, substates: []),
                    CategoryState(id: "butterKey", name: "butter", isSelected: false, substates: [])
                ]
                
                let initialState = UneatenState(categoriesStates: standaloneCategories + [CategoryState(id: "meatKey", name: "meats", isSelected: false, substates: meatSubCategories), CategoryState(id: "milkyKey", name: "milky stuff", isSelected: false, substates: milkySubCategories)], saved: true, pendingValidation: false)
                let store = ComposableArchitecture.Store<UneatenState, UneatenAction>(initialState: initialState, reducer: uneatenReducer, environment: UneatenEnvironment(uneatenService: UneatenCategoriesMockService()))
                let uneatenController = SectionedUneatenViewController.create(store: store)
                self?.navigationController?.pushViewController(uneatenController, animated: true)
            })
        .disposed(by: disposeBag)
    }
    
}


