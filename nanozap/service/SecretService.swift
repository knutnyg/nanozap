import Valet

protocol SecretKeeper {
    func saveMacaroon(secret: String) -> Bool
    func getMacaroon() -> String?
}

struct SecretService: SecretKeeper {

    //TODO: find out if identifier should be random or secret itself.
    let appValet = Valet.iCloudValet(with: Identifier(nonEmpty: "TQRQLA8ubzVgPtTWWswAZTs")!, accessibility: .whenUnlocked)
    //let appValet = Valet.valet(with: Identifier(nonEmpty: "TQRQLA8ubzVgPtTWWswAZTs")!, accessibility: .whenUnlocked)

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