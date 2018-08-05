import Foundation
import UIKit
import SnapKit
import AVFoundation
import QRCodeReader
import RxSwift
import RxCocoa
import SwiftMessages
import QRCode

struct DepositViewState {
    let address: String?
    let adddressQR: QRCode?
}

class DepositViewController: UIViewController {
    let disposeBag = DisposeBag()

    let addressDescriptionLabel = createLabel(text: "Address to pay to:")
    let addressLabel = createLabel(text: "")
    let imageView = createImage(image: Optional.none)
    let copyButton = createButton(text: "Copy address")
    let dismissButton = createButton(text: "Close")

    enum CreatePaymentAddress {
        case loading
        case success(DepositViewState)
        case failure(Error)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        view.addSubview(addressDescriptionLabel)
        view.addSubview(addressLabel)
        view.addSubview(imageView)
        view.addSubview(copyButton)
        view.addSubview(dismissButton)

        addressDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(30)
            make.centerX.equalTo(self.view)
            make.width.equalTo(self.view).inset(20)
        }

        addressLabel.snp.makeConstraints { make in
            make.centerY.equalTo(addressDescriptionLabel).offset(20)
            make.centerX.equalTo(self.view)
            make.width.equalTo(self.view).inset(20)
        }

        imageView.snp.makeConstraints { make in
            make.top.equalTo(addressLabel.snp.bottom).offset(20)
            make.centerX.equalTo(self.view)
            make.width.equalTo(self.view).inset(10)
            make.height.equalTo(self.view.snp.width).inset(10)
        }
        copyButton.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(30)
            make.centerX.equalTo(self.view)
        }

        dismissButton.snp.makeConstraints { make in
            make.centerY.equalTo(copyButton).offset(30)
            make.centerX.equalTo(self.view)
        }

        connectCopy()
        connectDismiss()

        WalletService.shared.createWitnessAddress()
                .observeOn(AppState.userInitiatedBgScheduler)
                .map {
                    DepositViewState(address: $0.address, adddressQR: QRCode($0.address))
                }
                .map {
                    CreatePaymentAddress.success($0)
                }
                .catchError { error in
                    Observable.just(CreatePaymentAddress.failure(error))
                }
                .startWith(CreatePaymentAddress.loading)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] result in
                    switch result {
                    case .loading:
                        self?.addressLabel.text = "Creating..."
                        self?.copyButton.isEnabled = false
                    case .success(let data):
                        self?.copyButton.isEnabled = true
                        self?.addressLabel.text = data.address ?? ""
                        self?.imageView.image = data.adddressQR?.image
                    case .failure(let error):
                        self?.dismiss(animated: true)
                        displayError(message: "Error creating address: \(error)")
                    }
                }).disposed(by: disposeBag)

    }

    private func connectDismiss() {
        dismissButton.rx.tap.asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.dismissButton.isEnabled = false
                self?.dismiss(animated: true)
             }).disposed(by: disposeBag)
    }

    private func connectCopy() {
        copyButton.rx.tap.asObservable()
                .map { _ in
                    true
                }
                .subscribe(onNext: { [weak self] _ in
                    UIPasteboard.general.string = self?.addressLabel.text
                })
                .disposed(by: disposeBag)
    }
}
