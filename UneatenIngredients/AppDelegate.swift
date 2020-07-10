//
//  AppDelegate.swift
//  UneatenIngredients
//
//  Created by Bioche on 07/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.window = UIWindow()
        self.window?.rootViewController = UINavigationController(
            rootViewController: MenuViewController.create())
        self.window?.makeKeyAndVisible()
        
        return true
    }


}

