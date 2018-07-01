import Foundation
import RxSwift
import Result

struct CreateInvoiceRequest {
    let amount : Int64
    let description : String
}

struct AddInvoiceResponse {
    let paymentRequest : String
    let rHash : Data
    let req : CreateInvoiceRequest

    init(from: Lnrpc_AddInvoiceResponse, req: CreateInvoiceRequest) {
        self.paymentRequest = from.paymentRequest
        self.rHash = from.rHash
        self.req = req
    }
}

class InvoiceService {
    let rpcmanager:RpcManager = RpcManager.shared
    static let shared = InvoiceService()

    public func decodeInvoice(payreqString:String) throws -> Invoice {
        do {
            var payreq = Lnrpc_PayReqString()
            payreq.payReq = payreqString
            let res = try rpcmanager.client()!.decodePayReq(payreq)
            let timestamp = Date.init(timeIntervalSince1970: TimeInterval(res.timestamp))
            let expiry = Date.init(timeIntervalSince1970: TimeInterval(res.expiry))

            return Invoice(
                timestamp: timestamp,
                amount: Int(res.numSatoshis),
                description: res.description_p,
                expiry: expiry,
                payreq: payreqString
            )
        } catch {
            print("Unexpected error decoding payreq: \(error).")
            throw RPCError.failedToDecodePayReq
        }
    }

    public func payInvoice(invoice:Invoice) throws -> Bool {
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

    public func createInvoice(cir : CreateInvoiceRequest) -> Observable<AddInvoiceResponse> {
        return Observable.create { obs in
            if let client = self.rpcmanager.client() {
                var req = Lnrpc_Invoice()
                req.value = cir.amount
                req.memo = cir.description

                let res = Result(attempt: { () throws in try client.addInvoice(req) })
                    .map { res in AddInvoiceResponse(from: res, req: cir) }

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

    private init() {}
}
