import Foundation

enum RPCErrors: Error {
    case unableToAccessClient
    case failedToFetchChannels
    case failedToDecodePayReq
}
