import Foundation
import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Result

class CreatePaymentViewController: UIViewController {
    let disposeBag = DisposeBag()

    let amountField = createTextField(placeholder: "Amount (Satoshis)")
    let descriptionField = createTextField(placeholder: "Description")
    let dismissButton = createButton(text: "Cancel")

    let createPaymentButton = createButton(text: "Create payment")

    let amount: PublishSubject<Int> = PublishSubject()
    let descriptionSub: BehaviorSubject<String> = BehaviorSubject(value: "")

    override func viewDidLoad() {
        super.viewDidLoad()

        amountField.keyboardType = .numberPad
        view.backgroundColor = UIColor.white

        self.view.addSubview(amountField)
        self.view.addSubview(descriptionField)
        self.view.addSubview(dismissButton)
        self.view.addSubview(createPaymentButton)

        amountField.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.descriptionField).offset(-60)
        }
        descriptionField.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(dismissButton).offset(-100)
            make.left.equalTo(self.view).offset(10)
            make.right.equalTo(self.view).offset(-10)
        }
        dismissButton.snp.makeConstraints { (make) in
            make.centerY.centerX.equalTo(self.view)
        }
        createPaymentButton.snp.makeConstraints { make in
            make.centerY.equalTo(dismissButton).offset(-50)
            make.centerX.equalTo(self.view)

        }


        connectDismissButton()
        connectFields()
        connectCreatePaymentButton()
    }

    func connectCreatePaymentButton() {
        amount.asObservable()
                .subscribe(
                        onNext: { val in print("got amount", val) }
                ).disposed(by: disposeBag)

        let taps = self.createPaymentButton.rx.tap.asObservable()
                .do { () in
                    print("tap createPaymentButton")
                }

        let latestData = Observable
                .combineLatest(self.amount.asObservable(), self.descriptionSub.asObservable(), taps)
                .map { (amount, desc, _) in
                    CreateInvoiceRequest(
                            amount: Int64(amount),
                            description: desc
                    )
                }
                .do(onNext: { request in print("got latest", request) })
                .flatMap { req in
                    InvoiceService.shared
                            .createInvoice(cir: req)
                            .retry(3)
                            .map {
                                Result(value: $0)
                            }
                            .catchError { error -> Observable<Result<AddInvoiceResponse, AnyError>> in
                                let res: Result<AddInvoiceResponse, AnyError> = Result(error: AnyError.error(from: error))
                                return Observable.just(res)
                            }
                }
                .subscribe(
                        onNext: { res in
                            switch (res) {
                            case .success(let value):
                                print("win! value", value)
                            case .failure(let error):
                                print("createPayment got error", error)
                                displayError(message: "That did not work...")
                            }
                        }
                ).disposed(by: disposeBag)

    }

    func connectFields() {
        amountField.rx.value
                .distinctUntilChanged()
                .do { () in
                    print("new value amountField")
                }
                .map { val in
                    Int(val.or(""))
                }
                .flatMap {
                    Observable.from(optional: $0)
                }
                .bind(to: amount)
                .disposed(by: disposeBag)

        descriptionField.rx.value.distinctUntilChanged()
                .do { () in
                    print("new value descriptionField")
                }
                .flatMap {
                    Observable.from(optional: $0)
                }
                .bind(to: descriptionSub)
                .disposed(by: disposeBag)
    }

    func connectDismissButton() {
        dismissButton.rx.tap.asObservable()
                .map { _ in
                    true
                }
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
