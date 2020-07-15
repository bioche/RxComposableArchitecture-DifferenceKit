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

struct UneatenCategory: Equatable {
    let key: String
    let name: String
    let subcategories: [UneatenCategory]
}

/// The state of the uneaten feature. Later mapped to the ViewState
struct UneatenState {
    var categoriesStates: [CategoryState]
    /// Have the choices been saved
    var saved: Bool
    
    var pendingValidation: Bool
    
    var selectedCategoriesKeys: [String] {
        categoriesStates.compactMap { $0.isSelected ? $0.id : nil }
    }
    
    var groups: [CategoryGroupState] {
        categoriesStates.map { .topCategory($0) }
    }
}

struct CategoryState: TCAIdentifiable, Equatable {
    
    let id: String
    var name: String
    var isSelected: Bool
    
    var substates: [CategoryState]
}

/// The actions of the uneaten feature.
enum UneatenAction {
    case validateSelection
    case toggleCategory(index: Int)
    
    case acknowledgeValidation
    
    case append(text: String)
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
    case .append(let text):
        state.categoriesStates.indices.forEach {
            state.categoriesStates[$0].name.append(contentsOf: text)
        }
    }
    return .none
}
