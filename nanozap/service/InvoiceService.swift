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

class InvoiceService {
    let rpcmanager: RpcManager = RpcManager.shared
    static let shared = InvoiceService()

    public func decodeInvoice(payreqString: String) throws -> DecodedInvoice {
        do {
            var payreq = Lnrpc_PayReqString()
            payreq.payReq = payreqString
            let res = try rpcmanager.client()!.decodePayReq(payreq)
            let timestamp = Date.init(timeIntervalSince1970: TimeInterval(res.timestamp))
            let expiry = Date.init(timeIntervalSince1970: TimeInterval(res.expiry))

            return DecodedInvoice(
                    timestamp: timestamp,
                    amount: Int(res.numSatoshis),
                    description: res.description_p,
                    expiry: expiry,
                    payreq: payreqString,
                    settled: false
            )
        } catch {
            print("Unexpected error decoding payreq: \(error).")
            throw RPCError.failedToDecodePayReq
        }
    }

    public func payInvoice(invoice: Invoice) throws -> Bool {
        guard let client = RpcManager.shared.client() else {
            print("Could not load client")
            throw RPCError.unableToAccessClient
        }
        do {
            var request = Lnrpc_SendRequest()
            request.paymentRequest = invoice.payreq
            _ = try client.sendPaymentSync(request)
            return true
        } catch {
            print("Failed to pay")
            return false
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

    public func listInvoices() throws -> [Invoice] {
        do {
            if let res = try rpcmanager.client()?.listInvoices(Lnrpc_ListInvoiceRequest()) {
                return res.invoices.map({ (lndInvoice: Lnrpc_Invoice) in
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
            } else {
                return []
            }
        } catch {
            print("Unexpected error: \(error).")
            throw RPCError.failedToFetchInvoices
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
