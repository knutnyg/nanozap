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
            .do(onNext: { (val : String?) in self.hostname = val })
            .startWith(hostname ?? "")

        let obs2 = certObs.distinctUntilChanged().startWith(cert ?? "")
        let obs3 = macaroonObs.distinctUntilChanged().startWith(macaroon ?? "")

        _ = Observable
            .combineLatest(obs1, obs2, obs3)
            .debounce(1.0, scheduler: MainScheduler.instance)
            .map { (hostname, cert, macaroon) -> AuthStateUpdate in
                return AuthStateUpdate(macaroon: macaroon, hostname: hostname ?? "", cert: cert)
            }
            .map { action -> Event in
                return Event.updateAuthConfig(action)
            }
            .bind(to: AppState.sharedState.updater)
            .disposed(by: disposeBag)
    }
    
    @IBAction func onePasswordButtonClicked(_ sender: Any) {
        // Using the provided classes
        let domain = self.hostname ?? "https://github.com"

        PasswordExtension.shared.findLoginDetails(for: domain, viewController: self, sender: nil) { (loginDetails, error) in
            if let loginDetails = loginDetails {
                print("Title: \(loginDetails.title ?? "")")
                print("Username: \(loginDetails.username)")
                print("Password: \(loginDetails.password ?? "")")
                print("Notes: \(loginDetails.notes ?? "")")
                print("URL: \(loginDetails.urlString)")
                print("Fields: ", loginDetails.fields)
                print("Fields: ", loginDetails.returnedFields)

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
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        print(result.value)
        switch scanType {
        case "cert":
            //TODO: sanitycheck result
            certObs.onNext(result.value)
            certLabel.text = "✅"
        case "macaroon":
            //TODO: sanitycheck result
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
}
