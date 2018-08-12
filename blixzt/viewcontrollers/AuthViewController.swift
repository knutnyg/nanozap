import Foundation
import UIKit
import PasswordExtension
import AVFoundation
import QRCodeReader
import RxSwift
import RxCocoa
import SnapKit

enum AuthEvent {
    case stateUpdate(AuthState)
    case displaySuccess(message: String)
    case displayFailure(message: String)
}

struct AuthState {
    var macaroon: String?
    var cert: String?
    var hostname: String?

    func new(
            macaroon: String? = nil,
            cert: String? = nil,
            hostname: String? = nil) -> AuthState {
        return AuthState(
                macaroon: macaroon ?? self.macaroon,
                cert: cert ?? self.cert,
                hostname: hostname ?? self.hostname)
    }
}

enum ScanObject {
    case cert
    case macaroon
}

enum AuthUIAction {
    case displaySuccess(message: String)
    case displayFailure(message: String)
}

private enum AuthStateChanges {
    case hostname(hostname: String)
    case cert(cert: String)
    case macaroon(macaroon: String)
}

class AuthViewController: UIViewController, QRCodeReaderViewControllerDelegate {

    var onePasswordButton: UIButton!
    var hostnameTextField: UITextField!
    var certLabel: UILabel!
    var macaroonLabel: UILabel!
    var testSecretsButton: UIButton!
    var scanCert: UIButton!
    var scanMacaroon: UIButton!

    let disposeBag = DisposeBag()
    var scanType: ScanObject = .cert

    let state = BehaviorSubject<AuthState>(value: AuthState(
            macaroon: AppState.sharedState.macaroon,
            cert: AppState.sharedState.cert,
            hostname: AppState.sharedState.hostname)
    )
    let uiActions = PublishSubject<AuthUIAction>()
    private let stateChanges = PublishSubject<AuthStateChanges>()

    override func viewDidLoad() {

        view.backgroundColor = UIColor.white

        hostnameTextField = createTextField(placeholder: "hostname:port")
        hostnameTextField.keyboardType = .URL

        certLabel = createLabel(text: "")
        macaroonLabel = createLabel(text: "")

        testSecretsButton = createButton(text: "test secrets")
        scanCert = createButton(text: "Scan Cert")
        scanMacaroon = createButton(text: "Scan Macaroon")

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

        state
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (state: AuthState) in
                    self.certLabel.text = (state.cert != nil) ? "Cert: ✅" : "Cert: ❌"
                    self.macaroonLabel.text = (state.macaroon != nil) ? "Macaroon: ✅" : "Macaroon: ❌"
                    self.hostnameTextField.text = state.hostname ?? ""
                }).disposed(by: disposeBag)

        stateChanges
                .observeOn(AppState.userInitiatedBgScheduler)
                .subscribe(onNext: { (change: AuthStateChanges) in
                    if let state = self.getState() {
                        switch (change) {
                        case .hostname(let hostname): self.state.onNext(state.new(hostname: hostname))
                        case .cert(let cert): self.state.onNext(state.new(cert: cert))
                        case .macaroon(let macaroon): self.state.onNext(state.new(macaroon: macaroon))
                        }

                        let config = RpcConfig(
                                address: state.hostname ?? "",
                                macaroon: state.macaroon ?? "",
                                cert: state.cert ?? "")

                        let valid = RpcManager.testConfig(cfg: config)
                        if (valid) {
                            let state = AuthStateUpdate(macaroon: config.macaroon, hostname: config.address, cert: config.cert)
                            AppState.sharedState.updater.onNext(.updateAuthConfig(state))
                        }
                    }
                }).disposed(by: disposeBag)

        scanCert.rx.tap
                .asObservable()
                .subscribe(onNext: { _ in
                    self.readerVC.delegate = self
                    self.readerVC.modalPresentationStyle = .formSheet
                    self.present(self.readerVC, animated: true, completion: { self.scanType = .cert })
                })
                .disposed(by: disposeBag)

        scanMacaroon.rx.tap
                .asObservable()
                .subscribe(onNext: { _ in
                    self.readerVC.delegate = self
                    self.readerVC.modalPresentationStyle = .formSheet
                    self.present(self.readerVC, animated: true, completion: { self.scanType = .macaroon })
                })
                .disposed(by: disposeBag)

        testSecretsButton.rx.tap
                .asObservable()
                .subscribe(onNext: { _ in
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
                })
                .disposed(by: disposeBag)

        hostnameTextField.rx.text
                .asObservable()
                .debounce(0.5, scheduler: AppState.userInitiatedBgScheduler)
                .subscribe(onNext: { (val: String?) in
                    self.stateChanges.onNext(.hostname(hostname: val!))
                })
                .disposed(by: disposeBag)

        uiActions
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (action: AuthUIAction) in
                    switch (action) {
                    case .displayFailure(let message): displayError(message: message)
                    default: break
                    }
                }).disposed(by: disposeBag)
    }

    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        return QRCodeReaderViewController(builder: builder)
    }()

    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()

        switch scanType {
        case .cert:
            if !(certIsValid(cert: result.value)) {
                self.uiActions.onNext(.displayFailure(message: "Error scanning"))
            } else {
                stateChanges.onNext(.cert(cert: result.value))
            }
        case .macaroon:
            if !(macaroonIsValid(macaroon: result.value)) {
                self.uiActions.onNext(.displayFailure(message: "Error scanning"))
            } else {
                let base64Macaroon = Data(base64Encoded: result.value)!
                let macaroon = base64Macaroon.hexString()
                stateChanges.onNext(.macaroon(macaroon: macaroon))
            }
        }

        dismiss(animated: true, completion: nil)
    }

    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()

        dismiss(animated: true, completion: nil)
    }

    public func certIsValid(cert: String) -> Bool {
        return cert.contains("-----BEGIN CERTIFICATE-----") &&
                cert.contains("-----END CERTIFICATE-----")
    }

    public func macaroonIsValid(macaroon: String) -> Bool {
        if let data = Data(base64Encoded: macaroon) {
            return !data.isEmpty
        }

        return false
    }

    private func getState() -> AuthState? {
        do {
            return try self.state.value()
        } catch let error {
            print(error)
        }
        return nil
    }
}
