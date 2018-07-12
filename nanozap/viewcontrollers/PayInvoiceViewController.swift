import Foundation
import UIKit
import AVFoundation
import QRCodeReader
import RxSwift
import RxCocoa
import SwiftMessages

enum PayInvoiceEvents {
    case startScan
    case startPayment
    case dismissView
    case toastSuccess(message: String)
    case toastFailure(message: String)
}

enum PayInvoiceActions {
    case payInvoice(payableInvoice: PayableInvoice)
    case decodeInvoice(invoiceRaw: String)
}

enum PayInvoiceActionResponse {
    case invoicePaid(paymentResponse: PayInvoiceResponse)
    case invoiceDecoded(decodedInvoice: DecodeInvoiceResponse)
}

struct PayInvoiceViewModel {
    var invoice: DecodedInvoice?
}

class PayInvoiceViewController: UIViewController, QRCodeReaderViewControllerDelegate {
    var scanButton: UIButton!
    var payButton: UIButton!
    let dismissButton = createButton(text: "Cancel")

    var descTextView: UITextView!
    var amountLabel: UILabel!
    var expiryLabel: UILabel!

    let dateFormatter = DateFormatter()

    let actions = PublishSubject<PayInvoiceActions>()
    let uiActions = PublishSubject<PayInvoiceEvents>()
    let model = BehaviorSubject<PayInvoiceViewModel>(value: PayInvoiceViewModel())
    let disposeBag = DisposeBag()

    var confirmPay: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

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
                    case .startScan: self.present(self.readerVC, animated: true)
                    case .startPayment: self.present(self.confirmPay!, animated: true)
                    case .toastSuccess(let message): displaySuccess(message: message)
                    case .toastFailure(let message): displayError(message: message)
                    case .dismissView: self.dismiss(animated: true)
                    }
                })
                .disposed(by: disposeBag)

        actions
                .asObservable()
                .observeOn(AppState.userInitiatedBgScheduler)
                .flatMap { (action: PayInvoiceActions) -> Observable<PayInvoiceActionResponse> in
                    switch (action) {
                    case .payInvoice(let invoice):
                        return InvoiceService.shared.payInvoice(invoice: invoice)
                                .retry(3)
                                .catchError { error in
                                    self.uiActions.onNext(.toastFailure(message: "Ops.. Something went wrong"))
                                    return Observable.empty()
                                }
                                .map { res in
                                    return .invoicePaid(paymentResponse: res)
                                }
                    case .decodeInvoice(let data):
                        let payreq = self.stripPrefix(data: data)
                        return InvoiceService.shared.decodeInvoice(payreqString: payreq)
                                .retry(3)
                                .catchError { error in
                                    return Observable.empty()
                                }
                                .map { res in
                                    return .invoiceDecoded(decodedInvoice: res)
                                }

                    }
                }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (res: PayInvoiceActionResponse) in
                    switch (res) {
                    case .invoicePaid:
                        self.model.onNext(PayInvoiceViewModel())
                        self.uiActions.onNext(.toastSuccess(message: "Payments Success!"))
                    case .invoiceDecoded(let res):
                        self.model.onNext(PayInvoiceViewModel(invoice: res.decodedInvoice))
                    }
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

    private func stripPrefix(data: String) -> String {
        let charList = data
        if let colon = charList.index(of: ":") {
            return String(charList[charList.index(after: colon)..<charList.endIndex])
        } else {
            return ""
        }
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
                    self.uiActions.onNext(PayInvoiceEvents.dismissView)
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
                self.actions.onNext(
                        .payInvoice(payableInvoice: PayableInvoice(payreq: invoice.payreq, amount: invoice.amount))
                )
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
                    self.uiActions.onNext(PayInvoiceEvents.startPayment)
                })
                .disposed(by: disposeBag)
    }

    private func connectScanButton() {
        scanButton.rx.tap
                .asObservable()
                .observeOn(AppState.userInitiatedBgScheduler)
                .subscribe(onNext: { _ in
                    self.uiActions.onNext(PayInvoiceEvents.startScan)
                })
                .disposed(by: disposeBag)
    }

    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        let vc = QRCodeReaderViewController(builder: builder)
        vc.delegate = self
        return vc
    }()

    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        actions.onNext(.decodeInvoice(invoiceRaw: result.value))
        dismiss(animated: true)
    }

    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        dismiss(animated: true)
    }
}
