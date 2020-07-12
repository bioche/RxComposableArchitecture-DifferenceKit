//
//  CategoriesCore.swift
//  UneatenIngredients
//
//  Created by Bioche on 12/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import ComposableArchitecture

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

struct CategoryState: TCAIdentifiable {
    
    var id: String { category.key }
    
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
