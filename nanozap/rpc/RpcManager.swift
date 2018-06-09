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
        
        var cert = certStore.getCert()
        var macaroon = macStore.getMacaroon()
        
        if let path = Bundle.main.path(forResource: "tls", ofType: "cert") {
            do {
                cert = try String.init(contentsOfFile: path)
            } catch {
                print("Failed to fetch tls.cert: \(error)")
            }
        }
        
        if let path = Bundle.main.path(forResource: "admin", ofType: "macaroon") {
            do {
                macaroon = try Data(contentsOf: URL(fileURLWithPath: path)).hexString()
            } catch {
                print("Failed to fetch macaroon: \(error)")
            }
        }
        
        guard let _cert = cert, let _macaroon = macaroon
            else {
                print("Missing cert or macaroon")
                client = nil
                return
            }
        
        self.client = Lnrpc_LightningServiceClient(address: "192.168.100.15:10009", certificates: _cert)
        
        do {
            try self.client!.metadata.add(key: "macaroon", value: _macaroon)
        } catch {
            print("Failed to setup macaroon: \(error)")
        }
    }
}


