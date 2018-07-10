import UIKit
import QRCodeReader
import RxSwift

class QRReader : QRCodeReaderViewControllerDelegate{

    weak var delegate:UIViewController?
    let subject: PublishSubject<QRData>

    init(deletate: UIViewController, subject:PublishSubject<QRData>) {
        self.delegate = deletate
        self.subject = subject
    }

    func present() {
        if let del = self.delegate {
            readerVC.delegate = self
            readerVC.modalPresentationStyle = .formSheet
            del.present(readerVC, animated: true)
        }
    }

    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        return QRCodeReaderViewController(builder: builder)
    }()

    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()

        self.subject.onNext(QRData(data: result.value))

        delegate!.dismiss(animated: true, completion: nil)
    }

    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()

        if let del = delegate {
            del.dismiss(animated: true, completion: nil)
        }
    }
}
