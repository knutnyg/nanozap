//
//  AuthViewController.swift
//  nanozap
//
//  Created by Knut Nygaard on 09/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation
import UIKit

class AuthViewController : UIViewController {
    
    @IBOutlet weak var certTextView: UITextView!
    @IBOutlet weak var macaroonTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    
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
    
    @IBAction func click(_ sender: UIButton) {
        macaroonStore.saveMacaroon(secret: macaroonTextView.text)
        macaroonTextView.text = ""
        
        certStore.saveCert(certData: certTextView.text)
        certTextView.text = ""
    }
}
