//
//  CategoriesCore.swift
//  UneatenIngredients
//
//  Created by Bioche on 12/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import ComposableArchitecture
import DifferenceKit

struct UneatenEnvironment {
    let uneatenService: UneatenCategoriesService
}

struct UneatenCategory: Equatable {
    let key: String
    let name: String
    let subcategories: [UneatenCategory]
}

/// The state of the uneaten feature. Later mapped to the ViewState
struct UneatenState: Equatable {
    var categoriesStates: [CategoryState]
    /// Have the choices been saved
    var saved: Bool
    
    var pendingValidation: Bool
    
    var selectedCategoriesKeys: [String] {
        categoriesStates.compactMap { $0.isSelected ? $0.id : nil }
    }
    
    var groups: [CategoryGroupState] {
        var standaloneCategories = [CategoryState]()
        let topCategories: [CategoryGroupState] =
            categoriesStates.compactMap {
                guard !$0.substates.isEmpty else {
                    standaloneCategories.append($0)
                    return nil
                }
                return .topCategory($0)
            }
        return [.standaloneCategories(standaloneCategories)] + topCategories
    }
}

struct CategoryState: TCAIdentifiable, Equatable {
    
    let id: String
    var name: String
    var isSelected: Bool
    
    var substates: [CategoryState]
}

extension CategoryState: Differentiable {
    /// Use the content equality to take into account the changes that need a reload.
    /// Here a change of name is the only change that necessitate a proper reload because it may alter the size of cells. However the selection state only changes the tint.
    func isContentEqual(to source: CategoryState) -> Bool {
        name == source.name
    }
}

/// The actions of the uneaten feature.
enum UneatenAction {
    case validateSelection
    
    case toggleCategory(index: Int)
    case toggleSubcategory(id: String, parentId: String?)
    case toggleSuperCategory(id: String)
    
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
    case .toggleSuperCategory(let id), .toggleSubcategory(let id, parentId: nil):
        print("toggling category of top level : \(id)")
        guard let index = state.categoriesStates.firstIndex(where: { $0.id == id }) else {
            assertionFailure("didn't find category with id: \(id)")
            return .none
        }
        state.saved = false
        state.categoriesStates[index].isSelected.toggle()
    case .toggleSubcategory(let id, let parentId?):
        print("toggling category of second level : \(id) in category : \(parentId)")
        guard let index = state.categoriesStates.firstIndex(where: { $0.id == parentId }),
            let subIndex = state.categoriesStates[index].substates.firstIndex(where: { $0.id == id }) else {
                assertionFailure("didn't find category with id: \(id) in category with id \(parentId)")
                return .none
        }
        state.saved = false
        state.categoriesStates[index].substates[subIndex].isSelected.toggle()
    case .acknowledgeValidation:
        state.saved = true
        state.pendingValidation = false
    case .append(let text):
        var firstsubCategories = state.categoriesStates[safe: 2]?.substates ?? []
        firstsubCategories.indices.forEach {
            firstsubCategories[$0].name.append(contentsOf: text)
        }
        state.categoriesStates[safe: 2]?.substates = firstsubCategories
    }
    return .none
}
