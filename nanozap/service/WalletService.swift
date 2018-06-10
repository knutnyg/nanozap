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
    
    public func getBalance() throws -> Int {
        do {
            let res = try rpcmanager.client()!.walletBalance(Lnrpc_WalletBalanceRequest())
            return Int(res.totalBalance)
        } catch {
            print("Unexpected error: \(error).")
            throw RPCErrors.failedToFetchChannels
        }
    }
    
}
