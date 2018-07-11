import Foundation
import UIKit
import AVFoundation
import QRCodeReader
import RxSwift
import RxCocoa
import SwiftMessages

struct PayableInvoice {
    let payreq: String
    let amount: Int
}

enum UIEvents {
    case startScan
    case startPayment
    case dismissView
}

struct PayInvoiceViewModel {
    var invoice: DecodedInvoice?
}

class PayInvoiceViewController: UIViewController {
    var scanButton: UIButton!
    var payButton: UIButton!

    var timeLabel: UILabel!
    var descLabel: UILabel!
    var amountLabel: UILabel!
    var expiryLabel: UILabel!

    let disposeBag = DisposeBag()

    let dismissButton = createButton(text: "Cancel")

    let qrSubject = PublishSubject<QRData>()
    let uiActions = PublishSubject<UIEvents>()
    let paySubject = PublishSubject<PayableInvoice>()
    let model = BehaviorSubject<PayInvoiceViewModel>(value: PayInvoiceViewModel())

    var qrReader: QRReader!
    var confirmPay: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        self.qrReader = QRReader(deletate: self, subject: qrSubject)

        scanButton = createButton(text: "Scan")
        payButton = createButton(text: "Pay!")

        timeLabel = createLabel(text: "")
        descLabel = createLabel(text: "")
        amountLabel = createLabel(text: "")
        expiryLabel = createLabel(text: "")

        view.addSubview(scanButton)
        view.addSubview(payButton)
        view.addSubview(timeLabel)
        view.addSubview(descLabel)
        view.addSubview(amountLabel)
        view.addSubview(expiryLabel)
        view.addSubview(dismissButton)

        let views: [String: UIView] = [
            "scanButton": scanButton,
            "payButton": payButton,
            "timeLabel": timeLabel,
            "descLabel": descLabel,
            "amountLabel": amountLabel,
            "expiryLabel": expiryLabel,
            "dismissButton": dismissButton
        ]

        setUpConstraints(views: views)

        connectScanButton()
        connectPayButton()
        connectDismissButton()

        uiActions
                .subscribe(onNext: { event in
                    switch (event) {
                    case .startScan: self.qrReader.present()
                    case .startPayment: self.present(self.confirmPay!, animated: true)
                    case .dismissView: self.dismiss(animated: true)
                    }
                })
                .disposed(by: disposeBag)

        qrSubject
                .asObservable()
                .map { (qrData: QRData) in
                    let charList = qrData.data
                    if let colon = charList.index(of: ":") {
                        return String(charList[charList.index(after: colon)..<charList.endIndex])
                    } else {
                        return ""
                    }
                }
                .observeOn(AppState.userInitiatedBgScheduler)
                .flatMap { payreq in
                    return InvoiceService.shared.decodeInvoice(payreqString: payreq)
                            .retry(3)
                            .catchError { error in
                                return Observable.empty()
                            }
                }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (res: DecodeInvoiceResponse) in
                    self.model.onNext(PayInvoiceViewModel(invoice: res.decodedInvoice))
                })
                .disposed(by: disposeBag)

        paySubject
                .asObservable()
                .observeOn(AppState.userInitiatedBgScheduler)
                .flatMap { payment in
                    InvoiceService.shared.payInvoice(invoice: payment)
                            .retry(3)
                            .catchError { error in
                                print("Failed: \(error)")
                                displayError(message: "Ops.. Something went wrong")
                                return Observable.empty()
                            }
                }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    self.model.onNext(PayInvoiceViewModel())
                    displayError(message: "Payment success!")
                })
                .disposed(by: disposeBag)

        model
                .asObservable()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (res: PayInvoiceViewModel) in
                    if let invoice = res.invoice {
                        self.updateInvoiceLabels(invoice: invoice)
                        self.updateConfirmPay(invoice: invoice)
                        self.payButton.isEnabled = true
                    } else {
                        self.payButton.isEnabled = false
                    }
                })
                .disposed(by: disposeBag)
    }

    private func connectDismissButton() {
        dismissButton.rx.tap
                .asObservable()
                .subscribe(onNext: { _ in
                    self.uiActions.onNext(UIEvents.dismissView)
                })
                .disposed(by: disposeBag)
    }

    private func updateInvoiceLabels(invoice: DecodedInvoice) {
        self.descLabel.text = "\(invoice.description)"
        self.amountLabel.text = "\(invoice.amount)"
        self.expiryLabel.text = "\(invoice.expiry)"
        self.timeLabel.text = "\(invoice.timestamp)"
    }

    private func updateConfirmPay(invoice: DecodedInvoice) {
        if let alert = self.confirmPay {
            alert.message = "Confirm paying \(invoice.amount) SAT"
        } else {
            let alert = UIAlertController(
                    title: "Pay?",
                    message: "Confirm paying \(invoice.amount) SAT",
                    preferredStyle: .actionSheet
            )
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                print("Yes was clicked")
                self.paySubject.onNext(PayableInvoice(payreq: invoice.payreq, amount: invoice.amount))
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
                print("Cancel was clocked")
            }))
            self.confirmPay = alert
        }
    }

    private func connectPayButton() {
        payButton.rx.tap
                .asObservable()
                .observeOn(AppState.userInitiatedBgScheduler)
                .subscribe(onNext: { _ in
                    self.uiActions.onNext(UIEvents.startPayment)
                })
                .disposed(by: disposeBag)
    }

    private func connectScanButton() {
        scanButton.rx.tap
                .asObservable()
                .observeOn(AppState.userInitiatedBgScheduler)
                .subscribe(onNext: { _ in
                    self.uiActions.onNext(UIEvents.startScan)
                })
                .disposed(by: disposeBag)
    }

    private func setUpConstraints(views: [String: UIView]) {
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-100-[scanButton]-[timeLabel]-[descLabel]-[amountLabel]-[expiryLabel]-50-[payButton]-30-[dismissButton]-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[scanButton]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[payButton]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[timeLabel]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[descLabel]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[amountLabel]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[expiryLabel]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[dismissButton]-20-|",
                metrics: nil,
                views: views))
    }
}
