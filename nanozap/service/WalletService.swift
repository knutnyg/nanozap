//
//  WalletService.swift
//  nanozap
//
//  Created by Knut Nygaard on 09/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation

class WalleteService {
    let rpcmanager:RpcManager = RpcManager.shared
    let client:Lnrpc_LightningServiceClient
    
    public func getBalance() throws -> Int {
        do {
            let res = try client.walletBalance(Lnrpc_WalletBalanceRequest())
            return Int(res.totalBalance)
        } catch {
            print("Unexpected error: \(error).")
            throw RPCErrors.failedToFetchChannels
        }
    }
    
    init() throws {
        guard let client = rpcmanager.client
            else {
                throw RPCErrors.unableToAccessClient
        }
        self.client = client
    }
}
