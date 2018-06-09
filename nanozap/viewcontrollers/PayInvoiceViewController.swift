import Foundation
import UIKit
import AVFoundation
import QRCodeReader


class PayInvoiceViewController : UIViewController, QRCodeReaderViewControllerDelegate {
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!
    @IBAction func click(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // Good practice: create the reader lazily to avoid cpu overload during the
    // initialization and each time we need to scan a QRCode
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    @IBAction func scanAction(_ sender: AnyObject) {
        // Retrieve the QRCode content
        // By using the delegate pattern
        readerVC.delegate = self
        
        // Or by using the closure pattern
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in
            print(result)
            
            let payreq:String
            
            let c = result!.value.characters
            if let colon = c.index(of: ":") {
                payreq = String(result!.value[c.index(after: colon)..<result!.value.endIndex])
            } else {
                payreq = ""
            }
            
            do {
                let invoiceService = try InvoiceService()
                let invoice = try invoiceService.decodeInvoice(invoice: payreq)
                print(invoice.ammount)
            } catch {
                print(error)
            }
            
        }
        
        // Presents the readerVC as modal form sheet
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
    }
    
    // MARK: - QRCodeReaderViewController Delegate Methods
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    //This is an optional delegate method, that allows you to be notified when the user switches the cameraName
    //By pressing on the switch camera button
    func reader(_ reader: QRCodeReaderViewController, didSwitchCamera newCaptureDevice: AVCaptureDeviceInput) {
        let cameraName = newCaptureDevice.device.localizedName
        print("Switching capturing to: \(cameraName)")
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
}
