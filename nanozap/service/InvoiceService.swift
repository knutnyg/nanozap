import Foundation
import RxSwift
import Result

struct CreateInvoiceRequest {
    let amount: Int64
    let description: String
}

struct AddInvoiceResponse {
    let paymentRequest: String
    let rHash: Data
    let req: CreateInvoiceRequest

    init(from: Lnrpc_AddInvoiceResponse, req: CreateInvoiceRequest) {
        self.paymentRequest = from.paymentRequest
        self.rHash = from.rHash
        self.req = req
    }
}

struct PayableInvoice {
    let payreq: String
    let amount: Int
}

struct DecodeInvoiceResponse {

    let decodedInvoice: DecodedInvoice

    init(from: Lnrpc_PayReq, payreq: String) {
        let timestamp = Date.init(timeIntervalSince1970: TimeInterval(from.timestamp))
        let expiry = Date.init(timeIntervalSince1970: TimeInterval(from.expiry))

        self.decodedInvoice = DecodedInvoice(
                timestamp: timestamp,
                amount: Int(from.numSatoshis),
                description: from.description_p,
                expiry: expiry,
                payreq: payreq
        )
    }
}

struct PayInvoiceResponse {
    let response: Lnrpc_SendResponse
}

class InvoiceService {
    let rpcmanager: RpcManager = RpcManager.shared
    static let shared = InvoiceService()

    public func decodeInvoice(payreqString: String) -> Observable<DecodeInvoiceResponse> {
        return Observable.create { obs in
            if let client = self.rpcmanager.client() {
                var payreq = Lnrpc_PayReqString()
                payreq.payReq = payreqString

                let res = Result(attempt: { () throws in try client.decodePayReq(payreq) })
                        .map { res in
                            DecodeInvoiceResponse(from: res, payreq: payreqString)
                        }

                switch res {
                case .success(let value):
                    obs.onNext(value)
                    obs.onCompleted()
                case .failure(let error):
                    obs.onError(error)
                }
            } else {
                obs.onError(RPCError.unableToAccessClient)
            }

            return Disposables.create(with: { () in obs.onCompleted() })
        }
    }

    public func listPayables() -> Observable<[Payable]> {
        let payments = self.listPayments()
                .map { payments in
                    payments.map { payment in
                        Payable.payment(p: payment)
                    }
                }
        let invoices = self.listInvoices()
                .map { invoices in
                    invoices.map { invoice in
                        Payable.invoice(i: invoice)
                    }
                }

        return Observable.zip(payments, invoices) { (payms, invs) in
            return [payms, invs].flatMap {
                $0
            }
        }
    }

    public func payInvoice(invoice: PayableInvoice) -> Observable<PayInvoiceResponse> {
        return Observable.create { obs in
            if let client = self.rpcmanager.client() {
                var request = Lnrpc_SendRequest()
                request.paymentRequest = invoice.payreq

                let res = Result(attempt: { () throws in try client.sendPaymentSync(request) })
                        .map { res in
                            PayInvoiceResponse(response: res)
                        }

                switch res {
                case .success(let value):
                    obs.onNext(value)
                    obs.onCompleted()
                case .failure(let error):
                    obs.onError(error)
                }
            } else {
                obs.onError(RPCError.unableToAccessClient)
            }

            return Disposables.create(with: { () in obs.onCompleted() })
        }
    }

    public func createInvoice(cir: CreateInvoiceRequest) -> Observable<AddInvoiceResponse> {
        return Observable.create { obs in
            if let client = self.rpcmanager.client() {
                var req = Lnrpc_Invoice()
                req.value = cir.amount
                req.memo = cir.description

                let res = Result(attempt: { () throws in try client.addInvoice(req) })
                        .map { res in
                            AddInvoiceResponse(from: res, req: cir)
                        }

                switch res {
                case .success(let value):
                    obs.onNext(value)
                    obs.onCompleted()
                case .failure(let error):
                    obs.onError(error)
                }
            } else {
                obs.onError(RPCError.unableToAccessClient)
            }

            return Disposables.create(with: { () in obs.onCompleted() })
        }
    }

    public func listPayments() -> Observable<[Payment]> {
        return Observable.create { obs in
            if let client = self.rpcmanager.client() {

                let req = Lnrpc_ListPaymentsRequest()

                let result = Result(attempt: { () in try client.listPayments(req) })

                switch (result) {
                case .success(let res):
                    let payments = res.payments.map { (pay: Lnrpc_Payment) -> Payment in
                        let timestamp = Date.init(timeIntervalSince1970: TimeInterval(pay.creationDate))

                        return Payment(
                                amount: pay.value,
                                fee: Int(pay.fee),
                                path: pay.path,
                                paymentHash: pay.paymentHash,
                                paymentPreimage: pay.paymentPreimage,
                                creationDate: timestamp
                        )
                    }

                    obs.onNext(payments)
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

    public func listInvoices() -> Observable<[Invoice]> {
        return Observable.create { obs in
            if let client = self.rpcmanager.client() {
                let req = Lnrpc_ListInvoiceRequest()

                let result = Result(attempt: { () in try client.listInvoices(req) })

                switch result {
                case .success(let res):
                    let invoices = res.invoices.map({ (lndInvoice: Lnrpc_Invoice) -> Invoice in
                        let timestamp = Date.init(timeIntervalSince1970: TimeInterval(lndInvoice.creationDate))
                        let expiry = Date.init(timeIntervalSince1970: TimeInterval(lndInvoice.expiry))

                        return Invoice(
                                timestamp: timestamp,
                                amount: Int(lndInvoice.value),
                                description: lndInvoice.memo,
                                expiry: expiry,
                                payreq: lndInvoice.paymentRequest,
                                settled: lndInvoice.settled,
                                rHash: lndInvoice.rHash
                        )
                    })
                    obs.onNext(invoices)
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

    public func getChannels() throws -> [Channel] {
        do {
            if let res = try rpcmanager.client()?.listChannels(Lnrpc_ListChannelsRequest()) {
                return res.channels.map({ (lndChannel: Lnrpc_Channel) in
                    return Channel(
                            active: lndChannel.active,
                            remotePubkey: lndChannel.remotePubkey,
                            channelPoint: lndChannel.channelPoint,
                            channelId: Int(lndChannel.chanID),
                            capacity: Int(lndChannel.capacity),
                            remoteBalance: Int(lndChannel.remoteBalance),
                            commitFee: Int(lndChannel.commitFee),
                            commitWeight: Int(lndChannel.commitWeight),
                            feePerKw: Int(lndChannel.feePerKw),
                            numUpdates: Int(lndChannel.numUpdates),
                            csvDelay: Int(lndChannel.csvDelay)
                    )
                })
            } else {
                return []
            }
        } catch {
            print("Unexpected error: \(error).")
            throw RPCError.failedToFetchChannels
        }
    }

    private init() {
    }
}
