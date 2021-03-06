
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
            ),
            priceInfo: PriceInfo(timestamp: Date(), priceInEUR: 0.0, priceInUSD: 0.0)
    )

    let txs: [Transaction]
    let balance: WalletBalance
    let priceInfo: PriceInfo
}

struct CreateAddressResult {
    let address: String
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
        let priceInfo = PriceInfoService.shared.getPriceInfo().map{ res in res.priceInfo }

        return Observable.zip(bal, txs, priceInfo) { (bal, txs, priceInfo) in
            return WalletData(txs: txs, balance: bal, priceInfo: priceInfo)
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

    struct SendCoinsRequest {
        // The address to send coins to
        let address: String

        // The amount in satoshis to send
        let amount: Int64

        // The target number of blocks that this transaction should be confirmed by.
        let confirmationTarget: Int32

        //// A manual fee rate set in sat/byte that should be used when crafting the transaction.
        let satPerByte: Int64
    }

    struct SendCoinsResult {
        let txid: String
    }

    public func sendCoins(data: SendCoinsRequest) -> Observable<SendCoinsResult> {
        return Observable.create { obs in
            if let client = self.rpcmanager.client() {
                var req = Lnrpc_SendCoinsRequest()
                req.amount = data.amount
                req.satPerByte = data.satPerByte
                req.addr = data.address
                req.targetConf = data.confirmationTarget

                let res: Result<Lnrpc_SendCoinsResponse, AnyError>
                        = Result(attempt: { () in try client.sendCoins(req) })

                switch res {
                case .success(let result):
                    let scr = SendCoinsResult(
                            txid: result.txid
                    )
                    obs.onNext(scr)
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
