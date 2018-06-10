import RxSwift

enum Event {
    case updateAuthConfig(AuthStateUpdate)
}

struct AuthStateUpdate {
    let macaroon: String
    let hostname: String
    let cert: String
    
    init(macaroon : String, hostname : String, cert : String) {
        self.macaroon = macaroon
        self.hostname = hostname
        self.cert = cert
    }
}

extension AuthStateUpdate: CustomStringConvertible {
    var description: String {
        // create and return a String that is how
        // you’d like a Store to look when printed
        return "AuthStateUpdate{hostname=\(hostname)}"
    }
}

class AppState {
    static var sharedState = AppState()
    let disposeBag = DisposeBag()

    let updater : PublishSubject<Event> = PublishSubject()

    var hostname : String
    var cert : String
    var macaroon : String

    private let store : SecretKeeper
    
    // TODO: Fix this hackish way of saving state
    // TODO: error handling
    private func save() {
        // Valet will crash when saving empty strings
        if !hostname.isEmpty {
            _ = store.save(key: HostnameStore.hostnameKey, secret: hostname)
        }
        if !cert.isEmpty {
            _ = store.save(key: CertStore.certKey, secret: cert)
        }
        if !macaroon.isEmpty {
            _ = store.save(key: MacaroonStore.macaroonKey, secret: macaroon)
        }
    }
    
    init(store : SecretKeeper = ICloudSecretKeeper()) {
        self.store = store
        hostname = store.get(key: HostnameStore.hostnameKey) ?? "restored-hostname"
        cert = store.get(key: CertStore.certKey) ?? ""
        macaroon = store.get(key: MacaroonStore.macaroonKey) ?? ""

        updater.subscribe(
            onNext: { (evt : Event) in
                print("event=", evt)
                switch evt {
                case .updateAuthConfig(let cfg):
                    self.cert = cfg.cert
                    self.hostname = cfg.hostname
                    self.macaroon = cfg.macaroon
                }

                // TODO: fix this hack
                self.save()
            }
            // onError: ,
            // onCompleted: ,
            // onDisposed:
            )
            .disposed(by: disposeBag)
    }
    
}
