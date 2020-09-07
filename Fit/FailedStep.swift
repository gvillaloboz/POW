//
//  FailedStep.swift
//  POW
//
//  Created by Gabriela Villalobos on 24.08.17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import RealmSwift

final class FailedStep: Object{
    
    // MARK: - Properties
    dynamic var userId = ""
    dynamic var steps = 0.0
    dynamic var timestamp = String()
}
