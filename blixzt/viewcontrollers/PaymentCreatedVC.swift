import Foundation
import UIKit
import RxSwift
import RxCocoa
import SnapKit
import QRCode

struct PaymentCreatedModel {
    let amount : Int
    let description : String
    let paymentHash : String
    let rHash : Data
}

class PaymentCreatedVC: UIViewController {
    let disposeBag = DisposeBag()

    let imageView = createImage(image: Optional.none)
    let amountField = createLabel(text: "")
    let descriptionField = createLabel(text: "")
    let descriptionFieldHeader = createLabel(text: "")
    let dismissButton = createButton(text: "Cancel")

    let createPaymentButton = createButton(text: "Create payment")

    var model : PaymentCreatedModel?

    convenience init(model: PaymentCreatedModel) {
        self.init()
        self.model = model
        self.view.backgroundColor = .white
        let qrcode = QRCode(model.paymentHash)

        self.imageView.image = qrcode?.image
        self.amountField.text = "Amount: \(model.amount) SAT"
        self.descriptionFieldHeader.text = "Description:"
        self.descriptionField.text = "\(model.description)"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(imageView)
        self.view.addSubview(amountField)
        self.view.addSubview(descriptionFieldHeader)
        self.view.addSubview(descriptionField)
        self.view.addSubview(dismissButton)

        imageView.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(10)
            make.left.equalTo(self.view).offset(10)
            make.right.equalTo(self.view).offset(-10)
            make.height.equalTo(self.view.snp.height).dividedBy(2)
        }

        amountField.snp.makeConstraints { make in
            make.centerX.equalTo(self.imageView)
            make.top.equalTo(self.imageView.snp.bottom).offset(15)
        }
        descriptionFieldHeader.snp.makeConstraints { make in
            make.centerX.equalTo(self.imageView)
            make.top.equalTo(self.amountField.snp.bottom).offset(15)
        }
        descriptionField.snp.makeConstraints { make in
            make.centerX.equalTo(self.imageView)
            make.top.equalTo(self.descriptionFieldHeader.snp.bottom).offset(15)
        }
        dismissButton.snp.makeConstraints { make in
            make.centerX.equalTo(self.imageView)
            make.top.equalTo(self.descriptionField.snp.bottom).offset(15)
        }

        connectDismissButton()
    }

    private func connectDismissButton() {
        self.dismissButton.rx.tap.asObservable()
            .map { _ in true }
            .subscribe(onNext: { val in self.dismiss(animated: true, completion: nil) } )
            .disposed(by: disposeBag)
    }

    public static func make(model : PaymentCreatedModel) -> PaymentCreatedVC {
        let vc = PaymentCreatedVC(model: model)
        return vc
    }
}
