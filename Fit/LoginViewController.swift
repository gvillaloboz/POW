//
//  LoginViewController.swift
//  POW
//
//  Created by Gabriela Villalobos on 22.06.17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import RealmSwift


class LoginViewController: UIViewController{
    
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var messageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Login View")
    }
    
    
    
    /// <#Description#>
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func loginButton(_ sender: Any) {
        
        let email = emailTextField.text
        //let userId = MyVariables.userId
        if(Reachability().isInternetAvailable()){
            selectUserId(email: email!){userId, response in
                print("User Id obtained from server: ", userId)
                self.updatePUIDonUserTable(deviceuid: AppDelegateVariables.deviceuid, userId: userId)
                DispatchQueue.main.async {
                    self.moveToNextScreen(userId: userId, response: response)
                }
            }
        }
        else{
            self.messageLabel.text = "Vérifiez votre connexion Internet!"
        }
        
        
    }
    
    
    /// Moves to the next screen of the app if login succesful (if we received a user id from the server)
    func moveToNextScreen(userId : String, response : [String]){
        if(userId == "0"){ //previously 0 results
            self.messageLabel.text = "Ton email n'est pas enregistré!"
        }
            
        else{
            performSegue(withIdentifier: "loginToTabSegue", sender: self)
            //createUserObject(email: emailTextField.text!)
            self.createUserObject(id: (response[0]),email: self.emailTextField.text!,name: (response[1]),lastName: (response[2]))
        }
    }
    
   
    func updatePUIDonUserTable(deviceuid: String, userId: String){
        
        let request = NSMutableURLRequest(url: NSURL (string: "https://pow.unil.ch/powapp/db/updatePUID.php")! as URL)
        request.httpMethod = "POST"
        
        let postString = "a=\(deviceuid)&b=\(userId)"
        
        print(postString)
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            if error != nil {
                print("error=\(error!)")
                return
            }
            
            print("response = \(response!)")
            
            let responseString =  String(data: data!, encoding: .utf8)
            print("responseString = \(responseString!)")
            
        }
        task.resume()
        
    }
    
   
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - email: previously registered on the server DB
    ///   - completionHandler: until we get the id from the server can't move to check if possible to move to next screen
    func selectUserId(email: String, completion:@escaping (String, [String]) -> Void){
        
        let request = NSMutableURLRequest(url: NSURL (string: "https://pow.unil.ch/powapp/db/selectUserId.php")! as URL)
        request.httpMethod = "POST"
        
        let postString = "a=\(email)"
        
        print(postString)
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            if error != nil {
                print("error=\(error!)")
                return
            }
            print("data = \(data!)")
            print("response = \(response!)")
            
            let responseString =  String(data: data!, encoding: .ascii)
            
            print("responseString = \(responseString!)")
            
            var splitString = [String]()
            splitString = (responseString?.components(separatedBy: " "))!
            completion(splitString[0],splitString)
        }
        task.resume()
        
    }
    

    
    /// Stores on disk the user object
    ///
    /// - Parameter email: email store on DB for user registration
    func createUserObject(id: String, email: String, name: String, lastName: String)-> Bool{
        print("-> ",id, email, name, lastName)
        
        let user = User()
        user.email = email
        user.id = id
        user.name = name
        user.lastName = lastName
        
        let realm = try! Realm()
        
        if let existingUser = realm.object(ofType: User.self, forPrimaryKey: id){
            print("User already exists on disc")
            return false
        }
        
    
        try! realm.write{
            realm.add(user)
        }
        return true
    }
}





