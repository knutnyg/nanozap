//
//  WalletService.swift
//  nanozap
//
//  Created by Knut Nygaard on 09/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation
import RxSwift
import Result

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

struct CreateAddressResult {
    let address : String
}

class WalletService {
    let rpcmanager: RpcManager = RpcManager.shared
    static let shared = WalletService()

    private init() {
        // no instances
    }

    public func getBalance() throws -> Int {
        do {
            if let res = try rpcmanager.client()?.walletBalance(Lnrpc_WalletBalanceRequest()) {
                return Int(res.totalBalance)
            } else {
                throw RPCError.unableToAccessClient
            }
        } catch {
            print("Unexpected error: \(error).")
            throw RPCError.unableToAccessClient
        }
    }

    public func getWallet() -> Observable<WalletData> {
        let bal = getWalletBalance()
        let txs = listTransactions()

        return Observable.zip(bal, txs) { (bal, txs) in
            return WalletData(txs: txs, balance: bal)
        }
    }

    public func getWalletBalance() -> Observable<WalletBalance> {
        return Observable.deferred {
            if let res = try self.rpcmanager.client()?.walletBalance(Lnrpc_WalletBalanceRequest()) {
                let bal = WalletBalance(
                        totalBalance: res.totalBalance,
                        confirmedBalance: res.confirmedBalance,
                        unconfirmedBalance: res.unconfirmedBalance
                )

                return Observable.just(bal)
            } else {
                //throw RPCErrors.unableToAccessClient
                // return Observable.empty()
                return Observable.error(RPCError.unableToAccessClient)
            }
        }
    }

    public func createWitnessAddress() -> Observable<CreateAddressResult> {
        return Observable.create { obs in
            if let client = self.rpcmanager.client() {
                let req = Lnrpc_NewWitnessAddressRequest()

                let res: Result<Lnrpc_NewAddressResponse, AnyError>
                        = Result(attempt: { () in try client.newWitnessAddress(req) })

                switch res {
                case .success(let result):
                    let car = CreateAddressResult(
                            address: result.address
                    )
                    obs.onNext(car)
                    obs.onCompleted()
                case .failure(let error):
                    obs.onError(error)
                }
            } else {
                obs.onError(RPCError.unableToAccessClient)
            }

            return Disposables.create()
        }
    }

    public func createAddress() -> Observable<CreateAddressResult> {
        return Observable.create { obs in
            if let client = self.rpcmanager.client() {
                var req = Lnrpc_NewAddressRequest()
                req.type = .witnessPubkeyHash

                let res: Result<Lnrpc_NewAddressResponse, AnyError>
                        = Result(attempt: { () in try client.newAddress(req) })

                switch res {
                case .success(let result):
                    let car = CreateAddressResult(
                            address: result.address
                    )
                    obs.onNext(car)
                    obs.onCompleted()
                case .failure(let error):
                    obs.onError(error)
                }
            } else {
                obs.onError(RPCError.unableToAccessClient)
            }

            return Disposables.create()
        }
    }

    public func listTransactions() -> Observable<[Transaction]> {
        return Observable.deferred {
            if let res = try self.rpcmanager.client()?.getTransactions(Lnrpc_GetTransactionsRequest()) {

                let txs: [Transaction] = res.transactions.map({ transaction in
                            let timestamp = Date.init(timeIntervalSince1970: TimeInterval(transaction.timeStamp))

                            return Transaction.init(
                                    txHash: transaction.txHash,
                                    timestamp: timestamp,
                                    numConfirmations: Int(transaction.numConfirmations),
                                    blockHash: transaction.blockHash,
                                    blockHeight: Int(transaction.blockHeight),
                                    amount: Int(transaction.amount),
                                    totalFees: Int(transaction.totalFees),
                                    destination: transaction.destAddresses
                            )
                        })
                        .sorted(by: { $0.timestamp > $1.timestamp })

                return Observable.just(txs)
            } else {
                //throw RPCErrors.unableToAccessClient
                // return Observable.empty()
                return Observable.error(RPCError.unableToAccessClient)
            }
        }
    }
}
