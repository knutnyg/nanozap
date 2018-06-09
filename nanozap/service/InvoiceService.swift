import Foundation

class InvoiceService {
    let rpcmanager:RpcManager = RpcManager.shared
    let client:Lnrpc_LightningServiceClient
    
    public func decodeInvoice(invoice:String) throws -> Invoice {
        do {
            var payreq = Lnrpc_PayReqString()
            payreq.payReq = invoice
            let res = try client.decodePayReq(payreq)
            let date = Date.init(timeIntervalSince1970: TimeInterval(res.timestamp))
            
            return Invoice(timestamp: date, ammount: Int(res.numSatoshis), description: res.description_p, expiry: date)
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
