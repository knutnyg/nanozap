import RxSwift

struct RpcConfig {
    // address is a string on the format hostname:port
    let address : String
    // macaroon is a hex string of some random bytes
    let macaroon : String
    // cert is a certificate
    let cert : String
}

class RpcManager {
    static let shared = RpcManager()
    private var myClient: Lnrpc_LightningServiceClient?

    let disposeBag = DisposeBag()
    
    public func client() -> Lnrpc_LightningServiceClient? {
        return myClient
    }

    public static func testConfig(cfg : RpcConfig) -> Bool {
        do {
            if cfg.cert.count < 1 || cfg.macaroon.count < 1 || cfg.address.count < 0{
                return false
            }
            
            let testClient = try createClient(address: cfg.address, cert: cfg.cert, macaroon: cfg.macaroon)
            
            if let result = try testClient?.walletBalance(Lnrpc_WalletBalanceRequest()) {
                return true
            }
        } catch(let error) {
            print("error with config: ", error)
        }
        return false
    }
    
    private static func createClient(address : String, cert : String, macaroon : String) throws -> Lnrpc_LightningServiceClient? {
        let client = Lnrpc_LightningServiceClient(
            address: address,
            certificates: cert,
            arguments: [.keepAliveTimeout(5)]
        )
        
        client.timeout = 5
        try client.metadata.add(key: "macaroon", value: macaroon)
        
        return client
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
        
        do {
            self.myClient = try RpcManager.createClient(
                    address: hostname,
                    cert: cert,
                    macaroon: macaroon
            )
        } catch {
            self.myClient = nil
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


