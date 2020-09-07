//
//  DashboardViewController.swift
//  POW
//
//  Created by Gabriela Villalobos on 06.06.17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import RealmSwift


extension UIApplication {
    class func openAppSettings() {
        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
    }
    
    class func openPrivacy(){
        UIApplication.shared.openURL(URL(string: "App-Prefs:root=Privacy&path=HEALTH")!)
        
    }
}


class DashboardViewController: UIViewController, HavingHealthStore {
    
    //MARK: Variables
    var healthStore: HKHealthStore?
    
    var realm: Realm!
    var tenThousandStepsNotification = false
    var internetConnection = false
    
    @IBOutlet weak var stepsValueLabel: UILabel!
    @IBOutlet var dateValueLabel: UILabel!
    @IBOutlet weak var medalImage: UIImageView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        healthStore = HKHealthStore()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /// Launched every time DashboardViewController appears, it is executed after viewDidLoad()
    ///
    /// - Parameter animated: <#animated description#>
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if HKHealthStore.isHealthDataAvailable() {
            let readDataTypes = self.stepsTypesToRead()
            self.healthStore?.requestAuthorization(toShare: [], read: readDataTypes, completion: { [unowned self] (success, error) in
                if success {
                    
                    NotificationCenter.default.addObserver(
                        self,
                        selector: #selector(self.handleApplicationDidBecomeActive),
                        name: .UIApplicationDidBecomeActive,
                        object: nil)
                    
                    DispatchQueue.main.async {
                        self.updateUsersStepsLabelAndDateValueLabel()
                        self.pushUnsyncStepsToServer()
                        self.scheduleALocalNotification()
                    }
                    
                } else if let error = error {
                    print(error.localizedDescription)
                }
            })
            
        }
    }
    
    /// Gets called everytime the app comes from background to foreground.
    func handleApplicationDidBecomeActive() {
        checkForNotificationsEnabled()
        //checkForWriteStepsEnabled()
        updateUsersStepsLabelAndDateValueLabel()
        pushUnsyncStepsToServer()
        pushFailedStepsToServer()
    }
    
    
    //MARK: Notification Permissions
    
    /*
     *  Check for notification permissions and Health Kit permissions
    */
    
    /// Check if the notifications permission is off. If yes shows an alert that promts the user to the systems settings.
    func checkForNotificationsEnabled(){
        let notificationType = UIApplication.shared.currentUserNotificationSettings?.types
        if notificationType?.rawValue == 0 {
            let alertController = UIAlertController(title: "Bonjour!", message: "S'il vous plaît autorisez les notifications, pour participar à l'experience.", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "Autorizer", style: .default, handler: notificationAuthorizationHandler)
            alertController.addAction(defaultAction)
            present(alertController, animated: true, completion: nil)
        } else {
        }
        
    }
    
    func notificationAuthorizationHandler(action: UIAlertAction){
        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
    }
    

    
    //MARK: Health Kit Permissions
    
    func checkForWriteStepsEnabled(){
        if (self.healthStore?.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!) == .sharingAuthorized) {
            print("Permission Granted to Access Steps")
        } else {
            print("Permission Denied to Access Steps")
        }
    }
    
    func HealthKitAuthorizationHandler(action: UIAlertAction){
        UIApplication.shared.openURL(URL(string: "App-Prefs:root=Privacy&path=HEALTH")!)
    }

    private func stepsTypesToRead() -> Set<HKObjectType> {
        let stepsType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        
        return [stepsType]
    }
    
    
    //MARK: Update Steps Label
    
    public func updateUsersStepsLabelAndDateValueLabel(){
        let now = Date()
        //let startOfDay = Calendar.current.startOfDay(for: now)// 2017-08-09 22:00:00 UTC
    
        var calendar = Calendar.current
        //calendar.timeZone = TimeZone(abbreviation: "UTC")! //OR NSTimeZone.localTimeZone()
        calendar.timeZone = NSTimeZone.local
        let startOfDay = calendar.startOfDay(for: Date())

        var components = DateComponents()
        components.day = 1
        components.second = -1
        let endOfDay = calendar.date(byAdding: components, to: startOfDay)
        
        //print(startOfDay)
        //print(endOfDay!)
        
        requestStepsToHKWithCompletion(start: startOfDay, end: endOfDay!, completion: {steps in
            //            if(steps == 0){
            //                print("HK OFF")
            //                let alertController = UIAlertController(title: "Bonjour!", message: "Autorisez HealthKit.", preferredStyle: .alert)
            //                let defaultAction = UIAlertAction(title: "Autorizer", style: .default, handler: self.HealthKitAuthorizationHandler)
            //                alertController.addAction(defaultAction)
            //                // self.present(alertController, animated: true, completion: nil)
            //
            //            }
            let oldSteps = self.stepsValueLabel.text
            let stepsNumberFormatted = NumberFormatter.localizedString(from: steps as NSNumber, number: .none)
            if(oldSteps != stepsNumberFormatted ){
                DispatchQueue.main.async {self.stepsValueLabel.text = stepsNumberFormatted
                }
                if(steps > 10000){
                    self.stepsValueLabel.textColor = UIColor.init(red: 0.109, green: 0.584, blue: 0.803, alpha: 1.0)
                    self.stepsValueLabel.font = UIFont.boldSystemFont(ofSize: 28.0)
                    self.medalImage.isHidden = false
                }
                else if(steps < 10000){
                    self.stepsValueLabel.textColor = UIColor.black
                    self.stepsValueLabel.font = UIFont.systemFont(ofSize: 28.0)
                    self.medalImage.isHidden = true
                }
                // le suma dos hora más al now que ya está bien
                // el date formatter agarra el date de GMT y lo pone
                // sirve para poner etiquetas o strings del tiempo actual
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                dateFormatter.locale = Locale.current
                
                //let dateString = dateFormatter.string(from: now)
                let dateString = self.convertDateToString(date: now)
                let updateLabel = "Dernière mise à jour:   \(dateString)"
                DispatchQueue.main.async {self.dateValueLabel.text = updateLabel
                }
                self.internetConnection = Reachability().isInternetAvailable()
                if(self.internetConnection){
                    self.submitSteps(steps: steps,
                                     userId: self.getUserId(),
                                     timestamp: dateString,
                                     completion: {result in
                                        print(result)
                                        
                                        if(result == "done"){
                                            self.createStepObject(userId: self.getUserId(), steps: steps, timestamp: dateString)
                                            self.insertNewSyncDate()
                                        }
                                        else if(result == "Code=-1001"){ // The request timed out.
                                            self.createFailedStepObject(userId: self.getUserId(),
                                                                        steps: steps,
                                                                        timestamp: dateString)
                                        }
                    })
                    }
            }
        })
    }
    
    
    //MARK: Push Unsync Steps to Server
    
    private func pushUnsyncStepsToServer(){
        let lastDaySync = getLastDaySync()
        let unsyncDays = getDifferenceInDays(start: lastDaySync, end: Date())
        getNStepsBack(daysBack: unsyncDays)
    }
    
    private func getLastDaySync() -> Date{
        let realm = try! Realm()
        if (realm.objects(Sync.self).isEmpty){
            return getSpecificDate(year: 1999, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        }
        else{
            let lastDaySync = realm.objects(Sync.self).last?.timestamp
            print("Last Sync Date: ", lastDaySync!)
            return lastDaySync!
        }
    }
    
    private func getNStepsBack(daysBack : Int){
        for i in 0 ..< daysBack{
            
            let yesterdayStartOfDay = getNDaysBackStartOfDay(numberOfDaysBack: i)
            let yesterdayEndOfDay = getNDaysBackEndOfDay(numberOfDaysBack: i)
            
            requestStepsToHKWithCompletion(start: yesterdayStartOfDay, end: yesterdayEndOfDay, completion: {steps in
                print("YESTERDAY START: ", yesterdayStartOfDay)
                print("YESTERDAY END: ", yesterdayEndOfDay)
                self.internetConnection = Reachability().isInternetAvailable()
                if(self.internetConnection){
                    self.submitSteps(steps: steps,
                                     userId: self.getUserId(),
                                     timestamp: self.convertDateToString(date: yesterdayEndOfDay),
                                     completion: {result in
                                        print(result)
                                        
                                        if(result == "done"){
                                            self.createStepObject(userId: self.getUserId(), steps: steps, timestamp: self.convertDateToString(date: yesterdayEndOfDay))
                                            self.insertNewSyncDate()
                                        }
                                        else if(result == "Code=-1001"){ // The request timed out.
                                            self.createFailedStepObject(userId: self.getUserId(),
                                                                        steps: steps,
                                                                        timestamp: self.convertDateToString(date: yesterdayEndOfDay))
                                        }
                    })
                }
                else{
                    //self.storeStepsOnDisk(steps: steps, timestamp: self.convertDateToString(date: yesterdayEndOfDay))
                    self.createStepObject(userId: self.getUserId(), steps: steps, timestamp: self.convertDateToString(date: yesterdayEndOfDay))
                }
            })
        }
    }
    
    private func requestStepsToHKWithCompletion(start : Date , end : Date, completion:@escaping (Double) -> Void){
        
        let timePredicate : NSPredicate = HKQuery.predicateForSamples(withStart: start as Date, end: end as Date, options: .strictStartDate)
        // Get only steps which were NOT user entered. HKMetadataKeyWasUserEntered == true
        let notManuallyInputPredicate: NSPredicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyWasUserEntered, operatorType: .notEqualTo, value: true)
        // Builds a compound predicate with time and notManually input steps
        let predicate: NSCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timePredicate, notManuallyInputPredicate])
        
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let query = HKStatisticsQuery(quantityType: stepsQuantityType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { (_, result, error) in
                                        var resultCount = 0.0
                                        
                                        guard let result = result else{
                                            print ("Failed to fetch steps = \(error?.localizedDescription ?? "N/A")")
                                            completion(resultCount)
                                            return
                                        }

                                        if let sum = result.sumQuantity() {
                                            resultCount = sum.doubleValue(for: HKUnit.count())
                                            //print ("Start: ", start)
                                            //print ("End: ", end)
                                            //print ("Steps: ", resultCount)
                                            //self.stepsNumber = resultCount
                                        }
                                        
                                        DispatchQueue.main.async {
                                            completion(resultCount)
                                        }
        }
        healthStore?.execute(query)
    }
    
    /// Inserts into steps table the number of steps given
    ///
    /// - Parameter steps: number of steps retrieved
    func submitSteps(steps: Double, userId: String, timestamp: String, completion:@escaping (String) -> Void){
        let request = NSMutableURLRequest(url: NSURL (string: "https://pow.unil.ch/powapp/db/syncSteps.php")! as URL)
        request.httpMethod = "POST"
        
        // Convert Date to String
        let a = String(describing: timestamp)
        let backSlash = "\'"
        let timeString = backSlash + a + backSlash
        // End Convert Date to String
        
        let postString = "a=\(steps)&b=\(userId)&c=\(timeString)"
        print(postString)
        
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            if error != nil {
                print("error=\(error!)")
                var splitString = [String]()
                splitString = (String(describing: error).components(separatedBy: " "))
                completion(splitString[2])
                return
            }
            
            //print("response = \(response!)")
            
            let responseString =  String(data: data!, encoding: .utf8)
            
            print("respnseString = \(responseString!)")
            
            var splitString = [String]()
            splitString = (responseString?.components(separatedBy: "."))!
            completion(splitString[0])
        }
        task.resume()
    }
    
    private func pushFailedStepsToServer(){
        let failedStepsArray = getFailedSyncSteps()
    
        for failedStep in failedStepsArray{
            
            let steps = failedStep.steps
            let userId = failedStep.userId
            let timestamp = failedStep.timestamp
            
            if(self.internetConnection){
                self.submitSteps(steps: steps,
                                 userId: userId,
                                 timestamp: timestamp,
                                 completion: {result in
                                    print(result)
                                    
                                    if(result == "done"){
                                        self.createStepObject(userId: userId, steps: steps, timestamp: timestamp)
                                        let realm = try! Realm()
                                        try! realm.write {
                                             realm.delete(realm.objects(FailedStep.self).filter("timestamp=%@",timestamp))
                                        }
                                        
                                        self.insertNewSyncDate()
                                    }
                                    else if(result == "Code=-1001"){ // The request timed out.
                                        self.createFailedStepObject(userId: userId,
                                                                    steps: steps,
                                                                    timestamp: timestamp)
                                    }
                })
            }
        }
    }
    
    //MARK: Notifications
    
    /// Triggers a local notification in the time specified by the dateComp
    private func pushLocalNotification(){
        NotificationCenter.default.addObserver(self, selector: Selector(("drawAShape:")), name: NSNotification.Name(rawValue: "actionOnePressed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: Selector(("showAMessage:")), name: NSNotification.Name(rawValue: "actionTwoPressed"), object: nil)
        
        
        let dateComp:NSDateComponents = NSDateComponents()
        dateComp.year = 2017
        dateComp.month = 08
        dateComp.day = 9
        dateComp.hour = 11
        dateComp.minute = 23
        dateComp.timeZone = NSTimeZone.system
        
        let calender:NSCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let date:NSDate = calender.date(from: dateComp as DateComponents)! as NSDate
        
        let notification:UILocalNotification = UILocalNotification()
        notification.category = "FIRST_CATEGORY"
        notification.alertBody = "Hello, this is a local notification"
        notification.fireDate = date as Date
        
        UIApplication.shared.scheduleLocalNotification(notification)
        
        
    }
    
    private func scheduleALocalNotification(){
        UIApplication.shared.cancelAllLocalNotifications() // if previous are not cancelled they will keep adding and all trigger at the same time
        NotificationCenter.default.addObserver(self, selector: Selector(("drawAShape:")), name: NSNotification.Name(rawValue: "actionOnePressed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: Selector(("showAMessage:")), name: NSNotification.Name(rawValue: "actionTwoPressed"), object: nil)
        
        
        let dateComp:NSDateComponents = NSDateComponents()
        dateComp.year = 2017
        dateComp.month = 08
        dateComp.day = 9
        dateComp.hour = 20
        dateComp.minute = 0
        dateComp.timeZone = NSTimeZone.system
        
        let calender:NSCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let date:NSDate = calender.date(from: dateComp as DateComponents)! as NSDate
        
        let notification:UILocalNotification = UILocalNotification()
        notification.repeatInterval = NSCalendar.Unit.day
        notification.category = "FIRST_CATEGORY"
        notification.alertBody = "Bonjour, tapez sur la notification pour synchroniser vos pas!"
        notification.fireDate = date as Date
        
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    

    
    //MARK: Calculations
    
    private func getDifferenceInDays(start : Date, end : Date) -> Int{
        let components = Calendar.current.dateComponents([.day], from: start, to: end)
        
        print(start)
        print(end)
        print("difference is \(components.day ?? 0) days")
        return components.day ?? 0
    }
    
    
    private func getNowTimestamp()->String{
        let now = Date()
        //let startOfDay = Calendar.current.startOfDay(for: now)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        dateFormatter.locale = Locale.init(identifier: "en_GB")
        let dateObj = dateFormatter.string(from: now)
        return dateObj
    }
    
    private func convertDateToString(date : Date) -> String{
        var myStringafd : String
        
        let locale = NSLocale.current
        let f : String = DateFormatter.dateFormat(fromTemplate: "j", options:0, locale:locale)!
        if f.contains("a") {
            //phone is set to 12 hours
            print("12hr")
            let formatter = DateFormatter()
            // initially set the format based on your datepicker date
            formatter.dateFormat = "yyyy-MM-dd H:mm:ss a"
            //formatter.timeZone = TimeZone(identifier: "UTC")!
            formatter.timeZone = NSTimeZone.local
            let myString = formatter.string(from: date)
            // convert your string to date
            let yourDate = formatter.date(from: myString)
            formatter.locale = Locale(identifier: "en_US_POSIX") //ARG
            //then again set the date format whhich type of output you need
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            // again convert your date to string
            myStringafd = formatter.string(from: yourDate!)

            
        } else {
            //phone is set to 24 hours
            print("24hr")
            let formatter = DateFormatter()
            // initially set the format based on your datepicker date
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            //formatter.timeZone = TimeZone(identifier: "UTC")!
            formatter.timeZone = NSTimeZone.local
            let myString = formatter.string(from: date)
            // convert your string to date
            let yourDate = formatter.date(from: myString)
            //then again set the date format whhich type of output you need
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            // again convert your date to string
            myStringafd = formatter.string(from: yourDate!)
            
            //print(myStringafd)
        }
        
        return myStringafd
    }
    
    
    private func getCurrentDate()->Date{
        // Este código verdaderamente le da el now o tiempo actual,
        var calendar = Calendar.current
        //calendar.timeZone = TimeZone(abbreviation: "UTC")! //OR NSTimeZone.localTimeZone() FIXED 24.08.17
        calendar.timeZone = NSTimeZone.local
        let components = NSDateComponents()
        // Está agregando, sin el day = 0 le agrega un día del componente anterior
        components.day = 0
        components.hour = 0
        components.second = 0
        
        let now = calendar.date(byAdding: components as DateComponents, to: Date())
        //
        return now!
        
    }
    
    
    //    calendar.timeZone = TimeZone(abbreviation: "UTC")!
    //
    //    2017-08-15 00:00:00 +0000: steps = 35.0
    //    2017-08-17 00:00:00 +0000: steps = 79.0
    //    2017-08-18 00:00:00 +0000: steps = 219.0
    //    2017-08-21 00:00:00 +0000: steps = 1011.68716606901
    //    2017-08-22 00:00:00 +0000: steps = 106.312833930995
    //
    //    calendar.timeZone = NSTimeZone.local
    //
    //    2017-08-14 22:00:00 +0000: steps = 325.0
    //    2017-08-16 22:00:00 +0000: steps = 41.0
    //    2017-08-17 22:00:00 +0000: steps = 257.0
    //    2017-08-20 22:00:00 +0000: steps = 172.0
    //    2017-08-21 22:00:00 +0000: steps = 946.0
    
    
    // Always use UTC time for calculations. Do not add two hours to UTC!
    private func getNDaysBackStartOfDay(numberOfDaysBack : Int)->Date{
        var calendar = Calendar.current
        //calendar.timeZone = TimeZone(abbreviation: "UTC")! //OR NSTimeZone.localTimeZone()
        calendar.timeZone = NSTimeZone.local
        let dateAtMidnight = calendar.startOfDay(for: Date())
        
        let components = NSDateComponents()
        components.day = -numberOfDaysBack - 1
        
        let yesterDayStartofDay = calendar.date(byAdding: components as DateComponents, to: dateAtMidnight)
        
        return yesterDayStartofDay!
        
    }
    
    private func getNDaysBackEndOfDay(numberOfDaysBack : Int)->Date{
        var calendar = Calendar.current
        //calendar.timeZone = TimeZone(abbreviation: "UTC")! //OR NSTimeZone.localTimeZone()
        calendar.timeZone = NSTimeZone.local
        let dateAtMidnight = calendar.startOfDay(for: Date())
        
        
        let components = NSDateComponents()
        components.day = -numberOfDaysBack //tenía 0
        components.second = -1
        
        let yesterDayStartofDay = calendar.date(byAdding: components as DateComponents, to: dateAtMidnight)
        
        return yesterDayStartofDay!
        
    }
    
    private func getYesterdayStartOfDay()->Date{
        // Este código verdaderamente le da el now o tiempo actual,
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")! //OR NSTimeZone.localTimeZone()
        let dateAtMidnight = calendar.startOfDay(for: Date())
        
        
        let components = NSDateComponents()
        components.day = -1
        
        let yesterDayStartofDay = calendar.date(byAdding: components as DateComponents, to: dateAtMidnight)
        
        return yesterDayStartofDay!
        
    }
    
    private func getYesterdayEndOfDay()->Date{
        // Este código verdaderamente le da el now o tiempo actual,
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")! //OR NSTimeZone.localTimeZone()
        let dateAtMidnight = calendar.startOfDay(for: Date())
        
        
        let components = NSDateComponents()
        components.day = 0
        components.second = -1
        
        let yesterDayStartofDay = calendar.date(byAdding: components as DateComponents, to: dateAtMidnight)
        
        return yesterDayStartofDay!
        
    }

    
    private func getSpecificDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> Date{
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        dateFormatter.locale = Locale.init(identifier: "en_GB")
        dateFormatter.timeZone = NSTimeZone.local //just added 22.08.17
        
        let dateComponents:NSDateComponents = NSDateComponents()
        dateComponents.timeZone = NSTimeZone.local //just added 22.08.17
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour // Because Date() return GMT * check *
        dateComponents.minute = minute
        dateComponents.second = second
        
        let calendar:NSCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let date:NSDate = calendar.date(from: dateComponents as DateComponents)! as NSDate
        return date as Date
        
    }
    

    
    //MARK: Realm
    
    /// Stores on disk the step object
    ///
    /// - Parameter email:
    
    func createStepObject(userId: String, steps: Double, timestamp: String)-> Void{
        let step = Step()
        step.userId = userId
        step.steps = steps
        step.timestamp = timestamp
        
        let realm = try! Realm()
        
        try! realm.write{
            realm.add(step)
            print("[ Step Object Created ] Steps: ", steps, "User Id: ", userId, "Timestamp: ", timestamp)
        }
    }
    
    /// Stores on disk the failed step object
    ///
    /// - Parameter email:
    
    func createFailedStepObject(userId: String, steps: Double, timestamp: String)-> Void{
        let failedStep = FailedStep()
        failedStep.userId = userId
        failedStep.steps = steps
        failedStep.timestamp = timestamp
        
        let realm = try! Realm()
        
        try! realm.write{
            realm.add(failedStep)
            print("[ Failed Step Object Created ] Steps: ", steps, "User Id: ", userId, "Timestamp: ", timestamp)
        }
    }
    
    
    private func insertNewSyncDate(){
        let sync = Sync()
        //sync.timestamp = getCurrentDate() // Tenía Date()
        //let dateString = self.convertDateToString(date: Date())
        sync.timestamp = Date()
        print("LAST SYNC: ", sync.timestamp)
        let realm = try! Realm()
        
        try! realm.write{
            realm.add(sync)
        }
        
    }

    
    func getUserId(email : String) -> String{
        let realm = try! Realm()
        let userId = realm.objects(User.self).filter("email = %@", email).first?.id // Check as I am getting the first one
        
        return userId!
    }
    
    func getUserId() -> String{
        let realm = try! Realm()
        let userId = realm.objects(User.self).first?.id // Check as I am getting the first one
        
        return userId!
    }
    
    func getFailedSyncSteps()->Results<FailedStep>{
        let realm = try! Realm()
        let failedSyncStepsArray = realm.objects(FailedStep.self)
        return failedSyncStepsArray
    }
    

    public func initializeLastDaySync(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int)-> Void{
        
        let storedLastDaySync = getLastDaySync() // if there is anything stored
        
        let lastDaySync = getSpecificDate(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
        
        //let difference  = lastDaySync < storedLastDaySync
        let difference = getDifferenceInDays(start: storedLastDaySync, end: lastDaySync)
        
        if(difference > 0){
            let sync = Sync()
            sync.timestamp = lastDaySync
            
            let realm = try! Realm()
            
            try! realm.write{
                realm.add(sync)
            }
        }
    }
    
    func show10KAlert(){
        let alertController = UIAlertController(title: "Bonjour!", message: "S'il vous plaît autorisez les notifications, pour participar à l'experience.", preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "Autorizer", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func checkFor10KSteps(steps: Double){
        // Local notification if more than 10 thousand steps
        let date = Date()
        if(steps > 10 && !self.tenThousandStepsNotification){ // and is in the proper condition
            
            
            self.tenThousandStepsNotification = true
            
            //            let notification:UILocalNotification = UILocalNotification()
            //            notification.category = "FIRST_CATEGORY"
            //            notification.alertBody = "Congratulations you've reached 10 thousand steps!"
            //            notification.fireDate = date as Date
            //
            //            UIApplication.shared.scheduleLocalNotification(notification)
        }
    }
    
}


