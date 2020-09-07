//
//  HistoryViewController.swift
//  POW
//
//  Created by Gabriela Villalobos on 07.06.17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class HistoryViewController: UITableViewController{

    let dataArray = ["iOS", "Android", "Raspberry", "Blender"]
    let dateArray = ["1.6.17", "2.6.17", "3.6.17", "4.6.17", "5.6.17"]
    let stepsArray = ["8,524", "10,256","4,590", "6,909", "12,593"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Contact View Loaded")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Number of sections inside the table
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return 2
//    }
//    
    // Number of rows for each section.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dateArray.count
    }
    
    // Index
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! HistoryViewControllerTableViewCell
        
        cell.dateLabel.text = dateArray[indexPath.row]
        cell.stepsLabel.text = stepsArray[indexPath.row]
        //cell.textLabel?.text = dataArray[indexPath.row]
        
        return cell
    }
    
    
    // Get all the Records where email = "test@gmail.com" // current user and order them by time, get the records where lastMonth < time < Now
    func getRecordsFromLastMonth(email : String) -> String{ // email is being used as id, later needs to be changed
        let realm = try! Realm()
        let userId = realm.objects(User.self).filter("email = %@", email).first?.id // Check as I am getting the first one
        
        
        // Filtering by time
        
        let calendar = NSCalendar.current
        let date = NSDate()
        
        let components = calendar.dateComponents([.year, .month], from: date as Date)
        let startOfMonth = calendar.date(from: components)
        
        //let predicate = NSPredicate(format: "timestamp > %@", startOfMonth)
        //let predicate = NSPredicate(format:"%@ >= timestamp AND %@ <= timestamp", date, startOfMonth as! NSDate)
        //let pred = NSPredicate(format: "(date >= %@) AND (date <= %@)", startOfMonth, date)

        
        
        //let records = realm.objects(Record).filter("email = %@", email).filter(predicate)
        
        return userId!
    }
    
    
}
