import Foundation
import UIKit
import AVFoundation
import QRCodeReader
import RxSwift
import RxCocoa

enum FinalizePaymentChoice {
    case yes(payableInvoice: PayableInvoice)
    case cancel
}

class PayInvoiceViewController: UIViewController, QRCodeReaderViewControllerDelegate {
    var scanButton: UIButton!
    var payButton: UIButton!

    var timeLabel: UILabel!
    var descLabel: UILabel!
    var amountLabel: UILabel!
    var expiryLabel: UILabel!

    let disposeBag = DisposeBag()

    let dismissButton = createButton(text: "Cancel")

    var invoice: DecodedInvoice?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        dismissButton.addTarget(self, action: #selector(dismissMe), for: .touchUpInside)

        scanButton = createButton(text: "Scan")
        scanButton.addTarget(self, action: #selector(scanPayRequest), for: .touchUpInside)

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

        let paymentResult: Observable<FinalizePaymentChoice> = self.payButton.rx.tap.asObservable()
                .filter { _ in
                    self.invoice != nil
                    print("invoice is nil")
                }
                .map { _ in
                    PayableInvoice(
                            payreq: self.invoice!.payreq,
                            amount: self.invoice!.amount
                    )
                }
                .flatMap { payableInvoice in
                    return Observable.create { [weak self] sub in
                        guard let `self` = self else {
                            sub.onCompleted()
                            return Disposables.create()
                        }

                        let alert = UIAlertController(
                                title: "Pay?",
                                message: "Confirm paying \(payableInvoice.amount) SAT",
                                preferredStyle: .actionSheet
                        )
                        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                            print("Yes was clicked")
                            sub.onNext(.yes(payableInvoice: payableInvoice))
                            sub.onCompleted()
                        }))
                        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
                            print("Cancel was clocked")
                            sub.onNext(.cancel)
                            sub.onCompleted()
                        }))

                        self.present(alert, animated: true)

                        return Disposables.create {
                            alert.dismiss(animated: true, completion: nil)
                        }
                    }
                }

        paymentResult
                .observeOn(AppState.userInitiatedBgScheduler)
                .map { (choice: FinalizePaymentChoice) -> PayableInvoice? in
                    switch (choice) {
                    case .yes(let invoice):
                        return invoice
                    case .cancel:
                        return nil
                    }
                }
                .flatMap { (maybeInvoice: PayableInvoice?) -> Observable<PayInvoiceResponse> in
                    if let invoice = maybeInvoice {
                        return InvoiceService.shared.payInvoice(invoice: invoice)
                    } else {
                        return Observable.empty()
                    }
                }
                .observeOn(MainScheduler.instance)
                .subscribe(
                        onNext: { [weak self] res in
                            // maybe we were already gone by this time, so exit:
                            guard let `self` = self else {
                                return
                            }
                        },
                        onError: { [weak self] error in
                            print("Error paying: \(error)")
                        }

                        //, onError: , onCompleted: , onDisposed: ,
                )
                .disposed(by: self.disposeBag)
    }

    @objc func click(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    // Start QRCode
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        return QRCodeReaderViewController(builder: builder)
    }()

    @objc func dismissMe(sender: UIButton) {
        self.dismiss(animated: true)
    }

    @objc func scanPayRequest(sender: UIButton) {
        readerVC.delegate = self
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)

        func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
            reader.stopScanning()

            print(result.value)

            let payreq: String

            let charList = result.value
            if let colon = charList.index(of: ":") {
                payreq = String(result.value[charList.index(after: colon)..<result.value.endIndex])
            } else {
                payreq = ""
            }

            print("Payreq: \(payreq)")
            do {
                let invoice = try InvoiceService.shared.decodeInvoice(payreqString: payreq)
                timeLabel.text = invoice.timestamp.description
                descLabel.text = invoice.description
                amountLabel.text = String(invoice.amount)
                expiryLabel.text = invoice.expiry.description
                self.invoice = invoice
            } catch {

            }
            dismiss(animated: true, completion: nil)
        }

        func readerDidCancel(_ reader: QRCodeReaderViewController) {
            reader.stopScanning()
            dismiss(animated: true, completion: nil)
        }

// End QRCode
    }
}
