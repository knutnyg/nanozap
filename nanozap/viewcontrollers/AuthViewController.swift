import Foundation
import UIKit
import PasswordExtension
import AVFoundation
import QRCodeReader
import RxSwift
import RxCocoa
import SnapKit

class AuthViewController : UIViewController, QRCodeReaderViewControllerDelegate {

    var onePasswordButton: UIButton!
    var hostnameTextField: UITextField!
    var certLabel: UILabel!
    var macaroonLabel: UILabel!
    var testSecretsButton: UIButton!
    var scanCert: UIButton!
    var scanMacaroon: UIButton!

    let disposeBag = DisposeBag()
    var scanType:String = "none"
    
    var macaroon:String?
    var cert:String?
    var hostname:String?

    var hostnameObs = BehaviorSubject<String?>(value: "")
    let certObs = PublishSubject<String>()
    let macaroonObs = PublishSubject<String>()
    
    override func viewDidLoad() {

        view.backgroundColor = UIColor.white

        hostnameTextField = createTextField(placeholder: "hostname:port")
        hostnameTextField.translatesAutoresizingMaskIntoConstraints = false

        certLabel = createLabel(text: "")
        macaroonLabel = createLabel(text: "")

        testSecretsButton = createButton(text: "test secrets")
        testSecretsButton.addTarget(self, action: #selector(testAuthClicked), for: .touchUpInside)

        scanCert = createButton(text: "Scan Cert")
        scanCert.addTarget(self, action: #selector(scanCertClicked), for: .touchUpInside)

        scanMacaroon = createButton(text: "Scan Macaroon")
        scanMacaroon.addTarget(self, action: #selector(scanMacaroonClicked), for: .touchUpInside)

        self.view.addSubview(hostnameTextField)
        self.view.addSubview(certLabel)
        self.view.addSubview(macaroonLabel)
        self.view.addSubview(testSecretsButton)
        self.view.addSubview(scanCert)
        self.view.addSubview(scanMacaroon)

        hostnameTextField.snp.makeConstraints { (make) in
            make.top.equalTo(self.view).offset(100)
            make.left.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-20)
            make.centerX.equalTo(self.view)
        }
        certLabel.snp.makeConstraints { (make) in
            make.top.equalTo(hostnameTextField.snp.bottom).offset(20)
            make.centerX.equalTo(self.view)
        }
        macaroonLabel.snp.makeConstraints { (make) in
            make.top.equalTo(certLabel.snp.bottom).offset(20)
            make.centerX.equalTo(self.view)
        }
        testSecretsButton.snp.makeConstraints { (make) in
            make.top.equalTo(macaroonLabel.snp.bottom).offset(20)
            make.centerX.equalTo(self.view)
        }
        scanCert.snp.makeConstraints { (make) in
            make.top.equalTo(testSecretsButton.snp.bottom).offset(20)
            make.centerX.equalTo(self.view)
        }
        scanMacaroon.snp.makeConstraints { (make) in
            make.top.equalTo(scanCert.snp.bottom).offset(20)
            make.centerX.equalTo(self.view)
        }

        self.macaroon = AppState.sharedState.macaroon
        self.cert = AppState.sharedState.cert
        self.hostname = AppState.sharedState.hostname
        self.hostnameObs = BehaviorSubject<String?>(value: AppState.sharedState.hostname)
        
        certLabel.text = (self.cert != nil) ? "Cert: ✅" : "Cert: ❌"
        macaroonLabel.text = (self.macaroon != nil) ? "Macaroon: ✅" : "Macaroon: ❌"
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

    @objc func scanCertClicked(sender: UIButton!) {
        readerVC.delegate = self
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: { self.scanType = "cert"})
    }

    @objc func scanMacaroonClicked(sender: UIButton!) {
        readerVC.delegate = self
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: { self.scanType = "macaroon"})
    }
    
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        return QRCodeReaderViewController(builder: builder)
    }()



    @objc func testAuthClicked(sender: UIButton!) {
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
            macaroonLabel.text = "✅"
            
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
