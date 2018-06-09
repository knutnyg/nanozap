import Foundation
import UIKit
import RxSwift
import PasswordExtension

class AuthViewController : UIViewController {
    
    @IBOutlet weak var certTextView: UITextView!
    @IBOutlet weak var macaroonTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var onePasswordButton: UIButton!
    @IBOutlet weak var hostnameTextField: UITextField!
    
    var macaroonStore:MacaroonStore!
    var certStore:CertStore!
    var secretStore:SecretKeeper!
    
    private let macaroonFieldVariable = Variable("")
    var macaroonFieldValue : Observable<String> {
        return macaroonFieldVariable.asObservable()
    }

    private let certFieldVariable = Variable("")
    var certFieldValue : Observable<String> {
        return certFieldVariable.asObservable()
    }
    
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

        macaroonTextView.text = self.macaroon ?? "no macaroon stored"
        certTextView.text = self.cert ?? "no cert stored"
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
    
    @IBAction func click(_ sender: UIButton) {
        macaroonStore.saveMacaroon(secret: macaroonTextView.text)
        macaroonTextView.text = ""
        
        certStore.saveCert(certData: certTextView.text)
        certTextView.text = ""
    }
}
