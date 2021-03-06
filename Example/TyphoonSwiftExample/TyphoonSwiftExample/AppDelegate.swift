//
//  AppDelegate.swift
//  TyphoonSwiftExample
//
//  Created by Aleksey Garbarev on 23/10/2016.
//  Copyright © 2016 AppsQuick.ly. All rights reserved.
//

import UIKit



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        Typhoon.activateAssemblies()
        
        
        let men = CoreComponents.assembly.allComponentsForType() as [Man]
        for aMan in men {
            print("name = \(aMan.name)")
        }
        
        let keyedMen = CoreComponents.assembly.component(forKey: "man") as Man?
        print("found by key: \(keyedMen?.name)")
        
        let man = CoreComponents.assembly.manWithInitializer()
        
        print("man.name = \(man.name)")
        
        let manWithPet = CoreComponents.assembly.manWithMethods()
        
        print("Pet: \(manWithPet.pet)")
        print("Company: \(manWithPet.company)")
    
        let component = CoreComponents.assembly.component1()

        if let backRef = component.dependency?.dependency?.dependency  {
            if backRef === component {
                print("Matches!")
            } else {
                print("\(backRef) != \(component)")
            }
        } else {
            print("Can't get gependency")
        }
        
        let byTypeWoman = CoreComponents.assembly.componentForType() as Woman?
        
        var woman = Woman()
        CoreComponents.assembly.inject(&woman)
        print("injected woman: \(woman.name)")
        
        print("name \(CoreComponents.assembly.name())")
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

