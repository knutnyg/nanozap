//
//  UnsecretServiceProtocol.swift
//  nanozap
//
//  Created by Knut Nygaard on 09/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation

protocol UnsecretServiceProt {
    func save(secrets:Secrets)
    func getSecrets() -> Secrets?
}
