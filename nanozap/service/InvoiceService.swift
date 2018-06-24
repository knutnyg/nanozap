import Foundation

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

    private init() {}
}
