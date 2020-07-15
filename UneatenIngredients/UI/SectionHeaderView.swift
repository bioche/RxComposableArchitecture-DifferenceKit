//
//  SectionHeaderView.swift
//  UneatenIngredients
//
//  Created by Bioche on 13/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit
import RxSwift
import ComposableArchitecture

class SectionHeaderView: UICollectionReusableView {
    
    struct ViewState: Equatable {
        var isSelected: Bool
        var name: String
    }
    
    enum ViewAction {
        case toggleCategory
    }
    
    @IBOutlet private weak var pictoImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var selectionSwitch: UISwitch!
    
    private var viewStore: ViewStore<ViewState, Never>!
    private let disposeBag = DisposeBag()
    
    func configure(viewStore: ViewStore<ViewState, Never>) {
        self.viewStore = viewStore
        
        viewStore.driver.isSelected
            .drive(selectionSwitch.rx.isOn)
            .disposed(by: disposeBag)
//        selectionSwitch.rx.isOn
//            .distinctUntilChanged()
//            .subscribe(onNext: { _ in
//                print("toggling category !!")
//                viewStore.send(.toggleCategory)
//            })
//            .disposed(by: disposeBag)
        
        nameLabel.text = viewStore.name
    }
}
