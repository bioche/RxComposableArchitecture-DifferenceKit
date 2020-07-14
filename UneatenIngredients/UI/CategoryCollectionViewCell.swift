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
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    private let disposeBag = DisposeBag()
    
    var viewStore: ViewStore<ViewState, Never>!
    
    func configure(viewStore: ViewStore<ViewState, Never>) {
        self.viewStore = viewStore
        
        imageView.image = UIImage(named: viewStore.imageName)
        titleLabel.text = viewStore.title
        viewStore.driver.tint.drive(onNext: { [weak self] in
            self?.imageView.tintColor = $0.uiColor
            self?.titleLabel.textColor = $0.uiColor
        }).disposed(by: disposeBag)
    }
}

extension CategoryState {
    var view: UneatenCategoryCollectionViewCell.ViewState {
        .init(imageName: "btn_close", title: category.name, tint: isSelected ? Color(uiColor: .green) : Color(uiColor: .black))
    }
}
