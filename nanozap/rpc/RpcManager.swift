//
//  RpcManager.swift
//  nanozap
//
//  Created by Knut Nygaard on 06/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation

class RpcManager {
    static let shared = RpcManager()
    
    let client: Lnrpc_LightningServiceClient?

    let macStore = MacaroonStore()
    let certStore = CertStore()

    private init() {
        setenv("GRPC_SSL_CIPHER_SUITES", "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384", 1)
        
        guard let cert = certStore.getCert(), let macaroon = macStore.getMacaroon() else {
            print("failed to setup client. Setup secrets in auth")
            client = nil
            return
        }
        
        do {
            self.client = Lnrpc_LightningServiceClient(address: "84.214.74.65:10009", certificates: cert)
            try self.client!.metadata.add(key: "macaroon", value: macaroon)
            
        } catch {
            print("Failed to setup macaroon: \(error)")
        }
    }
}


