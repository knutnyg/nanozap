import Foundation
import UIKit
import AVFoundation
import QRCodeReader
import RxSwift
import RxCocoa
import SnapKit

class CreatePaymentViewController : UIViewController {
    let disposeBag = DisposeBag()
    
    let dismissButton = createButton(text: "Cancel")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        
        self.view.addSubview(dismissButton)
        
        dismissButton.snp.makeConstraints { (make) in
            make.centerY.centerX.equalTo(self.view)
        }
        
        dismissButton.rx.tap.asObservable()
            .map { _ in true }
            .subscribe(
                onNext: { [weak self] val in
                    self?.dismiss(animated: true, completion: nil)
                },
                onError: { error in
                    print("died handling click.", error)
                    fatalError("died handling click")
                }
            ).disposed(by: disposeBag)
    }
 
}
