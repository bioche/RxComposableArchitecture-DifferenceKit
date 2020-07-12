//
//  Color.swift
//  UneatenIngredients
//
//  Created by Bioche on 12/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit

/// Codable struct for UIColor
struct Color: Codable, Equatable {
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat = 0.0
    
    /// Returns a UIColor from Color
    var uiColor: UIColor {
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// Init a Color with a UIColor
    ///
    /// - Parameter uiColor: UIColor
    init(uiColor: UIColor?) {
        uiColor?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    }
}
