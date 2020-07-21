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
        
        static var empty: Self {
            .init(isSelected: false, name: "")
        }
    }
    
    enum ViewAction {
        case toggleSwitch
    }
    
    @IBOutlet private weak var pictoImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var selectionSwitch: UISwitch!
    
    private var viewStore: ViewStore<ViewState, ViewAction>!
    private var disposeBag = DisposeBag()
    
    func configure(viewStore: ViewStore<ViewState, ViewAction>) {
        self.viewStore = viewStore
        
        viewStore.driver.isSelected
            .drive(selectionSwitch.rx.isOn)
            .disposed(by: disposeBag)
        selectionSwitch.rx.isOn
            .distinctUntilChanged()
            .skip(1) // isOn is always triggered on launch
            .subscribe(onNext: { _ in
                print("toggling category !!")
                viewStore.send(.toggleSwitch)
            })
            .disposed(by: disposeBag)
        
        nameLabel.text = viewStore.name
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
    }
}
