//
//  CheckLoginViewController.swift
//  POW
//
//  Created by Gabriela Villalobos on 26.07.17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import RealmSwift


class CheckLoginViewController: UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Check if user is already created on disk
    override func viewDidAppear(_ animated: Bool) {
        let realm = try! Realm()
        let matchedUsers = realm.objects(User.self)
        if (!matchedUsers.isEmpty){
            //print("User already logged in!!!!")
            performSegue(withIdentifier: "splashToTabSegue", sender: self)
            //print(matchedUsers[0].email)
        }
        else{
            performSegue(withIdentifier: "splashToLoginSegue", sender: self)
        }
    }
}
