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
    case toastSuccess(message: String)
    case toastFailure(message: String)
}

struct PayInvoiceViewModel {
    var invoice: DecodedInvoice?
}

class PayInvoiceViewController: UIViewController {
    var scanButton: UIButton!
    var payButton: UIButton!

    var descTextView: UITextView!
    var amountLabel: UILabel!
    var expiryLabel: UILabel!

    let dateFormatter = DateFormatter()

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

        scanButton = createButton(text: "Scan Invoice", font: NanoFonts.bigButton)
        payButton = createButton(text: "Pay", font: NanoFonts.bigButton)

        descTextView = UITextView()
        descTextView.translatesAutoresizingMaskIntoConstraints = false
        descTextView.font = NanoFonts.paragraph

        amountLabel = createLabel(text: "", font: NanoFonts.paragraphHighlighted)
        expiryLabel = createLabel(text: "")

        view.addSubview(scanButton)
        view.addSubview(payButton)
        view.addSubview(descTextView)
        view.addSubview(amountLabel)
        view.addSubview(expiryLabel)
        view.addSubview(dismissButton)

        setupConstraints()

        connectScanButton()
        connectPayButton()
        connectDismissButton()

        uiActions
                .subscribe(onNext: { event in
                    switch (event) {
                    case .startScan: self.qrReader.present()
                    case .startPayment: self.present(self.confirmPay!, animated: true)
                    case .dismissView: self.dismiss(animated: true)
                    case .toastSuccess(let message): displaySuccess(message: message)
                    case .toastFailure(let message): displayError(message: message)
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
                                self.uiActions.onNext(.toastFailure(message: "Ops.. Something went wrong"))
                                return Observable.empty()
                            }
                }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    self.model.onNext(PayInvoiceViewModel())
                    self.uiActions.onNext(.toastSuccess(message: "Success!"))
                })
                .disposed(by: disposeBag)

        model
                .asObservable()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (res: PayInvoiceViewModel) in
                    self.updateInvoiceLabels(decodedInvoice: res.invoice)

                    if let invoice = res.invoice {
                        self.updateConfirmPay(invoice: invoice)
                        self.payButton.isEnabled = true
                    } else {
                        self.payButton.isEnabled = false
                    }
                })
                .disposed(by: disposeBag)
    }

    private func setupConstraints() {
        expiryLabel.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(150)
            make.left.equalTo(self.view.snp.left).offset(70)
        }

        descTextView.snp.makeConstraints { make in
            make.top.equalTo(expiryLabel.snp.bottom).offset(10)
            make.left.equalTo(self.view.snp.left).offset(70)
            make.right.equalTo(self.view.snp.right).offset(-70)
            make.height.equalTo(70)
        }

        amountLabel.snp.makeConstraints { make in
            make.top.equalTo(descTextView.snp.bottom).offset(10)
            make.centerX.equalTo(self.view)
        }

        scanButton.snp.makeConstraints { make in
            make.bottom.equalTo(payButton.snp.top).offset(-30)
            make.centerX.equalTo(self.view)
        }

        payButton.snp.makeConstraints { make in
            make.bottom.equalTo(dismissButton.snp.top).offset(-30)
            make.centerX.equalTo(self.view)
        }

        dismissButton.snp.makeConstraints { make in
            make.bottom.equalTo(self.view).offset(-100)
            make.centerX.equalTo(self.view)
        }
    }

    private func connectDismissButton() {
        dismissButton.rx.tap
                .asObservable()
                .subscribe(onNext: { _ in
                    self.uiActions.onNext(UIEvents.dismissView)
                })
                .disposed(by: disposeBag)
    }

    private func updateInvoiceLabels(decodedInvoice: DecodedInvoice?) {
        if let invoice = decodedInvoice {
            dateFormatter.dateFormat = "dd.MM hh:mm:ss"
            self.descTextView.text = "\(invoice.description)"
            self.amountLabel.text = "Amount Payable: \(invoice.amount) sat"
            self.expiryLabel.text = "Valid until \(dateFormatter.string(from: invoice.expiry))"
        } else {
            self.descTextView.text = ""
            self.amountLabel.text = ""
            self.expiryLabel.text = ""
        }
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
}
