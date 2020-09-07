//
//  ContactViewController.swift
//  POW
//
//  Created by Gabriela Villalobos on 07.06.17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import UIKit

class ContactViewController: UIViewController{
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func openMailClient() {
        let subject = "Question sur POW"
        let body = "Ton message ici..."
        let coded = "mailto:ux-research@unil.ch?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        if let emailURL: NSURL = NSURL(string: coded!) {
            if UIApplication.shared.canOpenURL(emailURL as URL) {
                UIApplication.shared.openURL(emailURL as URL)
            }
        }
    }
    
    @IBAction func openMailButton(_ sender: UIButton){
        openMailClient()
    }
    
}


