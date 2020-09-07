//
//  User.swift
//  Fit
//
//  Created by Gabriela Villalobos on 21.06.17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import RealmSwift

final class User: Object{
    
    // MARK: - Init
    convenience  init(email: String) {
        self.init()
        self.email = email
    }
    
    // MARK: - Properties
    dynamic var id = ""
    dynamic var name = ""
    dynamic var lastName = ""
    dynamic var email = ""
    dynamic var group = "default"
    
    
    // MARK: - Meta
    
    override static func primaryKey() -> String?{
        return "id"
    }
}






