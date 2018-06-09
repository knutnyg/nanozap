import Valet

protocol SecretKeeper {
    func save(key: String, secret: String) -> Bool
    func get(key: String) -> String?
}

struct ICloudSecretKeeper: SecretKeeper {
    //TODO: find out if identifier should be random or secret itself.
    let appValet = Valet.iCloudValet(with: Identifier(nonEmpty: "TQRQLA8ubzVgPtTWWswAZTs")!, accessibility: .whenUnlocked)

    //let appValet = Valet.valet(with: Identifier(nonEmpty: "TQRQLA8ubzVgPtTWWswAZTs")!, accessibility: .whenUnlocked)

    public func save(key: String, secret: String) -> Bool {
        return appValet.set(string: secret, forKey: key)
    }

    public func get(key: String) -> String? {
        return appValet.string(forKey: key)
    }
}

struct CertStore {
    let store = ICloudSecretKeeper()
    let certKey = "lnd-cert"

    public func getCert() -> String? {
        return store.get(key: certKey)
    }

    public func saveCert(certData: String) -> Bool {
        return store.save(key: certKey, secret: certData)
    }
}

struct MacaroonStore {

    let macaroonKey = "macaroon"

    public func getMacaroon() -> String? {
        let myMacaroon = appValet.string(forKey: macaroonKey)

        return myMacaroon
    }

    // saveMacaroon returns false if item could not be saved.
    // Typically this means we were not able to access the Keychain.
    public func saveMacaroon(secret: String) -> Bool {
        return appValet.set(string: secret, forKey: macaroonKey)
    }

}
