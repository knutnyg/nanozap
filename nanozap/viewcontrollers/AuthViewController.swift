import Foundation
import UIKit
import PasswordExtension
import AVFoundation
import QRCodeReader
import RxSwift
import RxCocoa

class AuthViewController : UIViewController, QRCodeReaderViewControllerDelegate {
    
    @IBOutlet weak var onePasswordButton: UIButton!
    @IBOutlet weak var hostnameTextField: UITextField!
    @IBOutlet weak var certLabel: UILabel!
    @IBOutlet weak var macaroonLabal: UILabel!
    @IBOutlet weak var testSecretsButton: UIButton!
    
    let disposeBag = DisposeBag()
    var scanType:String = "none"
    
    var macaroon:String?
    var cert:String?
    var hostname:String?

    var hostnameObs = BehaviorSubject<String?>(value: "")
    let certObs = PublishSubject<String>()
    let macaroonObs = PublishSubject<String>()
    
    override func viewDidLoad() {
        self.macaroon = AppState.sharedState.macaroon
        self.cert = AppState.sharedState.cert
        self.hostname = AppState.sharedState.hostname
        self.hostnameObs = BehaviorSubject<String?>(value: AppState.sharedState.hostname)
        
        certLabel.text = (self.cert != nil) ? "✅" : "❌"
        macaroonLabal.text = (self.macaroon != nil) ? "✅" : "❌"
        hostnameTextField.text = self.hostname ?? ""

        hostnameTextField.rx.text
            .distinctUntilChanged()
            .bind(to: hostnameObs)
            .disposed(by: disposeBag)

        let obs1 = hostnameObs.asObservable()
            .do(onNext: { (val : Any) in print("host=", val) })
            .filter { optVal in optVal.map { value in true }.or(false) }
            .map { val in val.or("") }
            .do(onNext: { (val : String) in self.hostname = val })
            .startWith(hostname ?? "")

        let obs2 = certObs.distinctUntilChanged().startWith(cert ?? "")
        let obs3 = macaroonObs.distinctUntilChanged().startWith(macaroon ?? "")

        let configs = Observable
            .combineLatest(obs1, obs2, obs3)
            .debounce(0.5, scheduler: AppState.userInitiatedBgScheduler)
            .observeOn(AppState.userInitiatedBgScheduler)
            .map { (address, cert, macaroon) in
                RpcConfig(address: address, macaroon: macaroon, cert: cert)
            }
        
        let validConfigs = configs
            .filter { cfg in RpcManager.testConfig(cfg: cfg) }

        validConfigs
            .map { (rpcConfig) in
                AuthStateUpdate(macaroon: rpcConfig.macaroon, hostname: rpcConfig.address, cert: rpcConfig.cert)
            }
            .map { action in
                Event.updateAuthConfig(action)
            }
            .bind(to: AppState.sharedState.updater)
            .disposed(by: disposeBag)
    }
    
    @IBAction func onePasswordButtonClicked(_ sender: Any) {
        // Using the provided classes
        let domain = self.hostname ?? "https://github.com"

        PasswordExtension.shared
            .findLoginDetails(for: domain, viewController: self, sender: nil) { (loginDetails, error) in
                if let loginDetails = loginDetails {
                    print("Title: \(loginDetails.title ?? "")")
                    print("Username: \(loginDetails.username)")
                    print("Password: \(loginDetails.password ?? "")")
                    print("Notes: \(loginDetails.notes ?? "")")
                    print("URL: \(loginDetails.urlString)")
                    print("Fields: ", loginDetails.fields ?? "")
                    print("Fields: ", loginDetails.returnedFields ?? "")

                    self.certObs.onNext(loginDetails.notes ?? "")
                    self.macaroonObs.onNext(loginDetails.password ?? "")
                    self.hostnameTextField.text = loginDetails.urlString
                    
                } else if let error = error {
                    switch error.code {
                    case .extensionCancelledByUser:
                        print(error.localizedDescription)
                    default:
                        print("Error: \(error)")
                    }
                }
        }
    }
    
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        return QRCodeReaderViewController(builder: builder)
    }()
    
    @IBAction func scanCert(_ sender: AnyObject) {
        readerVC.delegate = self
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: { self.scanType = "cert"})
    }
    
    @IBAction func scanMacaroon(_ sender: AnyObject) {
        readerVC.delegate = self
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: { self.scanType = "macaroon"})
    }
    
    @IBAction func testAuth(_ sender: Any) {
        do {
            _ = try WalletService.shared.getBalance()
            let alert = UIAlertController(
                title: "Success 🙌",
                message: "Successfully made a request to LND",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(
                title: "Great",
                style: .default,
                handler: nil
            ))
            self.present(alert, animated: true)
        } catch {
            let alert = UIAlertController(
                title: "Failure 😢",
                message: "Failed to make a request to LND",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(
                title: "OK",
                style: .default,
                handler: nil
            ))
            self.present(alert, animated: true)
        }
    }
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        switch scanType {
        case "cert":
            if !(certIsValid(cert: result.value)) {
                return
            }
            certObs.onNext(result.value)
            certLabel.text = "✅"
        case "macaroon":
            if !(macaroonIsValid(macaroon: result.value)) {
                return
            }
            let base64Macaroon = Data(base64Encoded: result.value)!
            
            macaroon = base64Macaroon.hexString()
            macaroonObs.onNext(macaroon ?? "")
            macaroonLabal.text = "✅"
            
        default:
            print(result.value)
        }

        dismiss(animated: true, completion: nil)
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    public func certIsValid(cert:String) -> Bool {
        return
            cert.contains("-----BEGIN CERTIFICATE-----") &&
            cert.contains("-----END CERTIFICATE-----")
    }
    
    public func macaroonIsValid(macaroon:String) -> Bool {
        if let data = Data(base64Encoded: macaroon) {
            return !data.isEmpty
        }
        
        return false
    }
}
