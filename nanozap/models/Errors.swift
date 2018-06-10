//
//  Errors.swift
//  nanozap
//
//  Created by Knut Nygaard on 09/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation

enum RPCErrors: Error {
    case unableToAccessClient
    case failedToFetchChannels
    case failedToDecodePayReq
}
