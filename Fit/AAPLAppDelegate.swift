//
//  AAPLAppDelegate.swift
//  POW
//
//  Created by Gabriela Villalobos on 06.06.17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import HealthKit
import UserNotifications


protocol HavingHealthStore: class {
    var healthStore: HKHealthStore? {get set}
}

struct AppDelegateVariables {
    static var deviceuid = ""
}


@UIApplicationMain
@objc(AAPLAppDelegate)
class AAPLAppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var settings: UIUserNotificationSettings?
    
    private var healthStore: HKHealthStore!
    
    let dashboard = DashboardViewController()
    

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        self.healthStore = HKHealthStore()
        DashboardViewController().initializeLastDaySync(year: 2017, month: 07, day: 1, hour: 0, minute: 0, second: 0)
        
        // Notifications Code
        settings = UIUserNotificationSettings(types: [.alert,.badge,.sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings!)
        UIApplication.shared.registerForRemoteNotifications()
        
        
        // Actions
        let firstAction:UIMutableUserNotificationAction = UIMutableUserNotificationAction()
        firstAction.identifier = "FIRST_ACTION"
        firstAction.title = "First Action"
        
        firstAction.activationMode = UIUserNotificationActivationMode.background
        firstAction.isDestructive = true
        firstAction.isAuthenticationRequired = false
        
        let secondAction:UIMutableUserNotificationAction = UIMutableUserNotificationAction()
        secondAction.identifier = "SECOND_ACTION"
        secondAction.title = "Second Action"
        
        secondAction.activationMode = UIUserNotificationActivationMode.foreground
        secondAction.isDestructive = false
        secondAction.isAuthenticationRequired = false
        
        let thirdAction:UIMutableUserNotificationAction = UIMutableUserNotificationAction()
        thirdAction.identifier = "THIRD_ACTION"
        thirdAction.title = "Third Action"
        
        thirdAction.activationMode = UIUserNotificationActivationMode.background
        thirdAction.isDestructive = false
        thirdAction.isAuthenticationRequired = false
        
        let openPOWAction:UIMutableUserNotificationAction = UIMutableUserNotificationAction()
        openPOWAction.identifier = "OPENPOW_ACTION"
        openPOWAction.title = "Lancer POW"
        
        openPOWAction.activationMode = UIUserNotificationActivationMode.foreground
        openPOWAction.isDestructive = false
        openPOWAction.isAuthenticationRequired = false
        
        
        // category
        
        let firstCategory:UIMutableUserNotificationCategory = UIMutableUserNotificationCategory()
        firstCategory.identifier = "FIRST_CATEGORY"
        
//        let defaultActions:NSArray = [firstAction, secondAction, thirdAction]
//        let minimalActions:NSArray = [firstAction, secondAction]
        
        let defaultActions:NSArray = [openPOWAction]
        let minimalActions:NSArray = [openPOWAction]
        
        firstCategory.setActions(defaultActions as? [UIUserNotificationAction], for: UIUserNotificationActionContext.default)
        firstCategory.setActions(minimalActions as? [UIUserNotificationAction], for: UIUserNotificationActionContext.minimal)
        
        // NSSet of all our categories
        
        let categories:NSSet = NSSet(objects: firstCategory)
        
        
        let mySettings = UIUserNotificationSettings(types: [.alert, .badge], categories: categories as? Set<UIUserNotificationCategory>)
        UIApplication.shared.registerUserNotificationSettings(mySettings)

        return true
    }
    
    func application(application: UIApplication!,
                     handleActionWithIdentifier identifier:String!,
                     forLocalNotification notification:UILocalNotification!,
                     completionHandler: (() -> Void)!){
        
        if (identifier == "FIRST_ACTION"){
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "actionOnePressed"), object: nil)
            
        }else if (identifier == "SECOND_ACTION"){
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "actionTwoPressed"), object: nil)
            
        }
        
        completionHandler()
        
    }
    

    func application(_ application: UIApplication,
                              didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        //send this device token to server
        print("Got token data! \(deviceToken)")
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Token: \(tokenString)")
        
        // Prepare device token to have a proper format
        let token = tokenString.replacingOccurrences(of: "^\\s*", with: "", options: .regularExpression)
        
        // Check if application notification settings
        let pushBadge = settings!.types.contains(.badge) ? "enabled" : "disabled"
        let pushAlert = settings!.types.contains(.alert) ? "enabled" : "disabled"
        let pushSound = settings!.types.contains(.sound) ? "enabled" : "disbled"
        
        let myDevice = UIDevice();
        let deviceName = myDevice.name
        let deviceModel = myDevice.model
        let systemVersion = myDevice.systemVersion
        let deviceId = myDevice.identifierForVendor!.uuidString
        // storing as a global variable
        AppDelegateVariables.deviceuid = deviceId
        
        var appName:String?
        if let appDisplayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") {
            appName = appDisplayName as? String
        }
        else{
            appName = Bundle.main.object(forInfoDictionaryKey: "CFBlundleNme")
                as? String
        }
        
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        
        let myUrl = URL(string: "https://pow.unil.ch/powapp/apns/apns.php");
        let request = NSMutableURLRequest(url: myUrl!);
        request.httpMethod = "POST";
        
        let postString = "task=register&appname=\(appName!)&appversion=\(appVersion!)&deviceuid=\(deviceId)&devicetoken=\(token)&devicename=\(deviceName)&devicemodel=\(deviceModel)&deviceversion=\(systemVersion)&pushbadge=\(pushBadge)&pushalert=\(pushAlert)&pushsound=\(pushSound)"
        
        request.httpBody = postString.data(using: String.Encoding.utf8);
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            if error != nil {
                print ("error= \(error!)")
                return
            }
            
            let responseString =  String(data: data!, encoding: .utf8)
            
            print("response \(responseString!)")
        }
        task.resume()
        
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error){
        print(error)
    }

    func application(_ application: UIApplication,
                              didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                              fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void){
            print("Message details \(userInfo)")
    }
}
