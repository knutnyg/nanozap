import Foundation

enum RPCError: Error {
    case unableToAccessClient
    case failedToFetchChannels
    case failedToFetchInvoices
    case failedToDecodePayReq
    case genericError(error: Error)
}
