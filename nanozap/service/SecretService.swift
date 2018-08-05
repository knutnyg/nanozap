import Valet

protocol SecretKeeper {
    func save(key: String, secret: String) -> Bool
    func get(key: String) -> String?
}

struct ICloudSecretKeeper: SecretKeeper {
    //TODO: find out if identifier should be random or secret itself.
    let appValet = Valet.iCloudValet(
        with: Identifier(nonEmpty: "TQRQLA8ubzVgPtTWWswAZTs")!,
        accessibility: .whenUnlocked
    )

    //let appValet = Valet.valet(with: Identifier(nonEmpty: "TQRQLA8ubzVgPtTWWswAZTs")!, accessibility: .whenUnlocked)

    public func save(key: String, secret: String) -> Bool {
        return appValet.set(string: secret, forKey: key)
    }

    public func get(key: String) -> String? {
        return appValet.string(forKey: key)
    }
}

struct HostnameStore {
    static let hostnameKey = "hostname"
}

struct CertStore {
    static let certKey = "lnd-cert"
}

struct MacaroonStore {
    static let macaroonKey = "macaroon"
}

struct OnboardingStore {
    static let startedAtKey = "onboarding-started-at"
}
