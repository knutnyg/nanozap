import Foundation
import UIKit
import AVFoundation
import QRCodeReader

class PayInvoiceViewController : UIViewController, QRCodeReaderViewControllerDelegate {
    var scanButton: UIButton!
    var payButton: UIButton!
    
    var timeLabel: UILabel!
    var descLabel: UILabel!
    var amountLabel: UILabel!
    var expiryLabel: UILabel!
    
    var invoice:DecodedInvoice?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        scanButton = createButton(text: "Scan")
        scanButton.addTarget(self, action: #selector(scanPayRequest), for: .touchUpInside)

        payButton = createButton(text: "Pay!")
        payButton.addTarget(self, action: #selector(pay), for: .touchUpInside)

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

        let views: [String:UIView] = [
            "scanButton":scanButton,
            "payButton":payButton,
            "timeLabel":timeLabel,
            "descLabel":descLabel,
            "amountLabel":amountLabel,
            "expiryLabel":expiryLabel
        ]

        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-100-[scanButton]-[timeLabel]-[descLabel]-[amountLabel]-[expiryLabel]-50-[payButton]",
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
    
    @objc func scanPayRequest(sender: UIButton) {
        readerVC.delegate = self
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
    }

    @objc func pay(_ sender: Any) {
        if let invoice = self.invoice {
            let alert = UIAlertController(
                title: "Pay?",
                message: "Confirm paying \(invoice.amount) satoshis",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(
                title: "Yes",
                style: .default,
                handler: { action in print("paying")}
            ))
            alert.addAction(UIAlertAction(
                title: "No",
                style: .cancel,
                handler: { action in print("cancel")}
            ))
            
            self.present(alert, animated: true)
        } else {
            return
        }
        
    }
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        print(result.value)
        
        let payreq:String

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
