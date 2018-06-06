//
//  ViewController.swift
//  nanozap
//
//  Created by Knut Nygaard on 05/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import UIKit
import SwiftGRPC
import SwiftProtobuf

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let path = Bundle.main.path(forResource: "tls", ofType: "cert")
        let macpath = Bundle.main.path(forResource: "admin", ofType: "macaroon")
        let data = try? Data(contentsOf: URL(fileURLWithPath: macpath!))
        if let tlsCert = try? String.init(contentsOfFile: path!) {
            let macaroon = data!.hexString()
            print(tlsCert)
            
            do {
                setenv("GRPC_SSL_CIPHER_SUITES", "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384", 1)
                let client = Lnrpc_LightningServiceClient(address: "192.168.100.15:10009", certificates: tlsCert)
                try client.metadata.add(key: "macaroon", value: macaroon)
                
                let res = try client.walletBalance(Lnrpc_WalletBalanceRequest())
                print(res)
            } catch {
                print("Unexpected error: \(error).")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

