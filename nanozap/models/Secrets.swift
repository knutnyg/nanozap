//
//  Secrets.swift
//  nanozap
//
//  Created by Knut Nygaard on 09/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation
class Secrets : NSObject, NSCoding {
    let cert:String
    let macaroon:String
    
    init(cert:String, macaroon:String) {
        self.cert = cert
        self.macaroon = macaroon
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let cert = aDecoder.decodeObject(forKey: "cert") as? String,
            let macaroon = aDecoder.decodeObject(forKey: "macaroon") as? String
        else { return nil }
        
        self.init(cert: cert, macaroon: macaroon)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(cert, forKey: "cert")
        aCoder.encode(macaroon, forKey: "macaroon")
    }
}
