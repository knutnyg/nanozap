import Foundation
import UIKit
import PasswordExtension
import AVFoundation
import QRCodeReader

class AuthViewController : UIViewController, QRCodeReaderViewControllerDelegate {
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var onePasswordButton: UIButton!
    @IBOutlet weak var hostnameTextField: UITextField!
    @IBOutlet weak var certLabel: UILabel!
    @IBOutlet weak var macaroonLabal: UILabel!
    
    var macaroonStore:MacaroonStore!
    var certStore:CertStore!
    var secretStore:SecretKeeper!
    var scanType:String = "none"
    
    
    var macaroon:String?
    var cert:String?
    var hostname:String?
    
    override func viewDidLoad() {
        self.macaroonStore = MacaroonStore()
        self.certStore = CertStore()
        self.secretStore = ICloudSecretKeeper()
        
        self.hostname = secretStore.get(key: "hostname")
        self.macaroon = macaroonStore.getMacaroon()
        self.cert = certStore.getCert()
        
        certLabel.text = (self.cert != nil) ? "✅" : "❌"
        macaroonLabal.text = (self.macaroon != nil) ? "✅" : "❌"

        hostnameTextField.text = self.hostname ?? ""
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
                //print("Fields: \(loginDetails.fields ?? "")")
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
            cert = result.value
            certLabel.text = "✅"
            let success = certStore.saveCert(certData: result.value)
            success ? print("cert stored") : print("failed to store cert")
            
        case "macaroon":
            //TODO: sanitycheck result
            let base64Macaroon = Data(base64Encoded: result.value)!
            
            macaroon = base64Macaroon.hexString()
            macaroonLabal.text = "✅"
            let success = macaroonStore.saveMacaroon(secret: macaroon!)
            success ? print("macaroon stored") : print("failed to store macaroon")
            
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
