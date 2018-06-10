
import RxSwift

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
    
    let updater : PublishSubject<AuthStateUpdate> = PublishSubject()

    var hostname : String
    var cert : String
    var macaroon : String

    private let store : SecretKeeper
    
    // TODO: Fix this hackish way of saving state
    // TODO: error handling
    private func save() -> Void {
        // Valet will crash when saving empty strings
        if hostname.count > 0 {
            let _ = store.save(key: HostnameStore.hostnameKey, secret: hostname)
        }
        if cert.count > 0 {
            let _ = store.save(key: CertStore.certKey, secret: cert)
        }
        if macaroon.count > 0 {
            let _ = store.save(key: MacaroonStore.macaroonKey, secret: macaroon)
        }
    }
    
    init(store : SecretKeeper = ICloudSecretKeeper()) {
        self.store = store
        hostname = store.get(key: HostnameStore.hostnameKey) ?? "restored-hostname"
        cert = store.get(key: CertStore.certKey) ?? ""
        macaroon = store.get(key: MacaroonStore.macaroonKey) ?? ""

        updater.subscribe(
            onNext: { (event : AuthStateUpdate) in
                print("event=", event)
                self.cert = event.cert
                self.hostname = event.hostname
                self.macaroon = event.macaroon
                
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
