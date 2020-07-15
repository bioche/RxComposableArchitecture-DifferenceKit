//
//  UneatenCategoriesService.swift
//  UneatenIngredients
//
//  Created by Bioche on 12/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import RxSwift

protocol UneatenCategoriesService {
    func getPossibleCategories() -> Single<[UneatenCategory]>
    
    func getSelectedCategoriesKeys() -> Single<[String]>
    func save(selectedCategoriesKeys: [String]) -> Single<Void>
}

struct UneatenCategoriesMockService: UneatenCategoriesService {
    static var selectedKeys = [String]()
    
    func getPossibleCategories() -> Single<[UneatenCategory]> {
        .just([UneatenCategory(key: "chickenKey", name: "chicken", subcategories: []), UneatenCategory(key: "SaladKey", name: "salad", subcategories: [])])
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
