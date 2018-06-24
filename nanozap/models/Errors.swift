import Foundation

enum RPCError: Error {
    case unableToAccessClient
    case failedToFetchChannels
    case failedToDecodePayReq
    case genericError(error: Error)
}
