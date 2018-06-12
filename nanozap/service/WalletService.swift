//
//  WalletService.swift
//  nanozap
//
//  Created by Knut Nygaard on 09/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation
import RxSwift

struct WalletBalance {
    //// The balance of the wallet
    let totalBalance: Int64

    //// The confirmed balance of a wallet(with >= 1 confirmations)
    let confirmedBalance: Int64

    //// The unconfirmed balance of a wallet(with 0 confirmations)
    let unconfirmedBalance: Int64
}

struct WalletData {
    public static let initWallet = WalletData(
            txs: [],
            balance: WalletBalance(
                    totalBalance: 0,
                    confirmedBalance: 0,
                    unconfirmedBalance: 0
            ))


    let txs: [Transaction]
    let balance: WalletBalance
}

class WalletService {
    let rpcmanager: RpcManager = RpcManager.shared
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

    public func getData() -> Observable<WalletData> {
        let bal = getWalletBalance()
        let txs = listTransactionsObs()

        return Observable.zip(bal, txs) { (bal, txs) in
            return WalletData(txs: txs, balance: bal)
        }
    }

    public func getWalletBalance() -> Observable<WalletBalance> {
        return Observable.deferred {
            let res = try self.rpcmanager.client()!.walletBalance(Lnrpc_WalletBalanceRequest())

            let bal = WalletBalance(
                    totalBalance: res.totalBalance,
                    confirmedBalance: res.confirmedBalance,
                    unconfirmedBalance: res.unconfirmedBalance
            )

            return Observable.just(bal)
        }
    }

    public func listTransactionsObs() -> Observable<[Transaction]> {
        return Observable.deferred {
            let txs = try self.listTransactions()

            return Observable.just(txs)
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

    private init() {
    }
}
