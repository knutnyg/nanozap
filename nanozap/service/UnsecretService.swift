//
//  UnsecretService.swift
//  nanozap
//
//  Created by Knut Nygaard on 09/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation
class UnsecretService: UnsecretServiceProt {
    func getSecrets() -> Secrets? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: "secrets.dat") as? Secrets
    }
    
    func save(secrets:Secrets) {
        NSKeyedArchiver.archiveRootObject(secrets, toFile: "secrets.dat")
    }
}
