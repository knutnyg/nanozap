//
//  AppDelegate.swift
//  nanozap
//
//  Created by Knut Nygaard on 05/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import UIKit
import FontAwesome_swift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let iconSize = CGSize(width: 30, height: 30)
        let iconColor = NanoColors.blue
        let exchangeIcon = UIImage.fontAwesomeIcon(name: .exchange, textColor: iconColor, size: iconSize)

        window = UIWindow(frame: UIScreen.main.bounds)
        let walletVC: WalletViewController = WalletViewController()
        walletVC.title = "Wallet"
        walletVC.tabBarItem = UITabBarItem(title: "Wallet", image: exchangeIcon, tag: 0)

        let channelsVC = ChannelsTableViewController()
        channelsVC.title = "Channels"
        channelsVC.tabBarItem = UITabBarItem(tabBarSystemItem: .contacts, tag: 1)

        let authVC = AuthViewController()
        authVC.title = "Auth"
        authVC.tabBarItem = UITabBarItem(tabBarSystemItem: .downloads, tag: 2)

        let tabBarController: UITabBarController = UITabBarController()

        let controllers = [walletVC, channelsVC, authVC]
        tabBarController.viewControllers = controllers


        window!.rootViewController = tabBarController
        window!.makeKeyAndVisible()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state.
        // This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message)
        // or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks.
        // Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough application state information to restore your application to its
        // current state in case it is terminated later.
        // If your application supports background execution,
        // this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state;
        // here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started)
        // while the application was inactive.
        // If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate.
        // See also applicationDidEnterBackground:.
    }
}
