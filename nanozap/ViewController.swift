//
//  ViewController.swift
//  nanozap
//
//  Created by Knut Nygaard on 05/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var walletbalanceLabel: UILabel!
    
    let rpcmanager: RpcManager = RpcManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        guard let client = rpcmanager.client
            else {
                return
        }
        do {
            let res = try client.walletBalance(Lnrpc_WalletBalanceRequest())
            walletbalanceLabel.text = String(format: "Balance: %ld",res.totalBalance)
        } catch {
                print("Unexpected error: \(error).")
        }
    }
        

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

