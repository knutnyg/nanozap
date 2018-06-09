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
    
    let secrets:Secrets?
    
    override func viewDidLoad() {
        let unsecretService = UnsecretService()
        self.secrets = unsecretService.getSecrets()
        
        
    }
    
    @IBAction func click(_ sender: UIButton) {
        print(certTextView.text)
    }
    
    
}
