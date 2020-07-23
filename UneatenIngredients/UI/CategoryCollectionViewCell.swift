//
//  CategoryCollectionViewCell.swift
//  UneatenIngredients
//
//  Created by Bioche on 12/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit
import RxSwift
import ComposableArchitecture

class UneatenCategoryCollectionViewCell: UICollectionViewCell {
    struct ViewState: Equatable {
        let imageName: String
        let title: String
        let tint: Color
    }
    enum ViewAction {
        case toggleCategory
    }
    
    @IBOutlet weak var cheapSwitch: UISwitch!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectionButton: UIButton!
    
    private var disposeBag = DisposeBag()
    
    var viewStore: ViewStore<ViewState, ViewAction>!
    
    func configure(viewStore: ViewStore<ViewState, ViewAction>) {
        
        cheapSwitch.isOn = true
        
        self.viewStore = viewStore
        
        print("configuring cell \(viewStore.title)")
        
        imageView.image = UIImage(named: viewStore.imageName)
        titleLabel.text = viewStore.title
//        viewStore.driver.title.drive(onNext: { [weak self] in
//            self?.titleLabel.text = $0
//        }).disposed(by: disposeBag)
        viewStore.driver.tint.drive(onNext: { [weak self] in
            print("tinting this shit : \(self?.viewStore.title). Tint : \($0)")
            self?.imageView.tintColor = $0.uiColor
            self?.titleLabel.textColor = $0.uiColor
        }).disposed(by: disposeBag)
        selectionButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.viewStore.send(.toggleCategory)
        }).disposed(by: disposeBag)
//        selectionButton.rx.tap.subscribe(onNext: { [weak self] in
//            print("tinting this shit")
//            self?.imageView.tintColor = UIColor.blue
//            self?.titleLabel.textColor = UIColor.blue
//        }).disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
    }
}

extension CategoryState {
    var view: UneatenCategoryCollectionViewCell.ViewState {
        .init(imageName: "btn_close", title: name, tint: isSelected ? Color(uiColor: .green) : Color(uiColor: .black))
    }
}
