//
//  WalletService.swift
//  nanozap
//
//  Created by Knut Nygaard on 09/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation

class WalletService {
    let rpcmanager:RpcManager = RpcManager.shared
    static let shared = WalletService()
    
    public func getBalance() throws -> Int {
        do {
            let res = try rpcmanager.client()!.walletBalance(Lnrpc_WalletBalanceRequest())
            return Int(res.totalBalance)
        } catch {
            print("Unexpected error: \(error).")
            throw RPCErrors.unableToAccessClient
        }
    }
    
    public func listTransactions() throws -> [Transaction] {
        do {
            let res = try rpcmanager.client()!.getTransactions(Lnrpc_GetTransactionsRequest())
            return res.transactions.map({ transaction in
                let timestamp = Date.init(timeIntervalSince1970: TimeInterval(transaction.timeStamp))
                return Transaction(
                    timestamp: timestamp,
                    amount: Int(transaction.amount),
                    destination: transaction.destAddresses[0]
                )
            })
        } catch {
            print("Unexpected error: \(error).")
            throw RPCErrors.unableToAccessClient
        }
    }
    
    private init() {}
    
}
