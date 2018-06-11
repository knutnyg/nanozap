import RxSwift

class RpcManager {
    static let shared = RpcManager()
    private var myClient: Lnrpc_LightningServiceClient?

    let disposeBag = DisposeBag()
    
    public func client() -> Lnrpc_LightningServiceClient? {
        return myClient
    }

    private func reload() {
        let hostname = AppState.sharedState.hostname
        let cert = AppState.sharedState.cert
        let macaroon = AppState.sharedState.macaroon

       if cert.count < 1 || macaroon.count < 1 {
            print("Missing cert or macaroon")
            myClient = nil
            return
        }

        self.myClient = Lnrpc_LightningServiceClient(
                address: hostname,
                certificates: cert,
                arguments: [.keepAliveTimeout(5)]
        )
        self.myClient?.timeout = 5

        do {
            try self.myClient!.metadata.add(key: "macaroon", value: macaroon)
        } catch {
            print("Failed to setup macaroon: \(error)")
        }
    }

    private init() {
        setenv("GRPC_SSL_CIPHER_SUITES", "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384", 1)

        reload()
        
        AppState.sharedState.updater
            .subscribe(
                //onError: ,
                //onCompleted: ,
                //onDisposed: ,
                onNext: { (evt : Event) in
                    switch(evt) {
                    case .updateAuthConfig(_):
                        self.reload()
                    }
                }
            ).disposed(by: disposeBag)
    }
}


