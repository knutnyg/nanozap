//
//  AuthViewController.swift
//  nanozap
//
//  Created by Knut Nygaard on 09/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation
import UIKit
import PasswordExtension

class AuthViewController : UIViewController {
    
    @IBOutlet weak var certTextView: UITextView!
    @IBOutlet weak var macaroonTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var onePasswordButton: UIButton!
    
    var macaroonStore:MacaroonStore!
    var certStore:CertStore!
    
    var macaroon:String?
    var cert:String?
    
    override func viewDidLoad() {
        self.macaroonStore = MacaroonStore()
        self.certStore = CertStore()
        
        self.macaroon = macaroonStore.getMacaroon()
        self.cert = certStore.getCert()

        macaroonTextView.text = self.macaroon ?? "no macaroon stored"
        certTextView.text = self.cert ?? "no cert stored"
    }
    
    @IBAction func onePasswordButtonClicked(_ sender: Any) {
        // Using the provided classes
        PasswordExtension.shared.findLoginDetails(for: "https://github.com/lnd", viewController: self, sender: nil) { (loginDetails, error) in
            if let loginDetails = loginDetails {
                print("Title: \(loginDetails.title ?? "")")
                print("Username: \(loginDetails.username)")
                print("Password: \(loginDetails.password ?? "")")
                print("Notes: \(loginDetails.notes ?? "")")
                print("URL: \(loginDetails.urlString)")
//                print("Fields: \(loginDetails.fields ?? "")")
            } else if let error = error {
                switch error.code {
                case .extensionCancelledByUser:
                    print(error.localizedDescription)
                default:
                    print("Error: \(error)")
                }
            }
        }
    }
    
    @IBAction func click(_ sender: UIButton) {
        macaroonStore.saveMacaroon(secret: macaroonTextView.text)
        macaroonTextView.text = ""
        
        certStore.saveCert(certData: certTextView.text)
        certTextView.text = ""
    }
}
