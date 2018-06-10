import Foundation
import UIKit
import AVFoundation
import QRCodeReader

class PayInvoiceViewController : UIViewController, QRCodeReaderViewControllerDelegate {
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var payButton: UIButton!
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var expiryLabel: UILabel!
    
    var invoice:Invoice?
    
    @IBAction func click(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // Start QRCode
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        return QRCodeReaderViewController(builder: builder)
    }()
    
    @IBAction func scanPayRequest(sender: UIButton) {
        readerVC.delegate = self
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
    }
    
    @IBAction func pay(_ sender: Any) {
        if let invoice = self.invoice {
            let alert = UIAlertController(
                title: "Pay?",
                message: "Confirm paying \(invoice.ammount) satoshis",
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

        let charList = result.value.characters
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
            amountLabel.text = String(invoice.ammount)
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
