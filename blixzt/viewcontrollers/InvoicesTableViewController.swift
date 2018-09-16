import Foundation
import UIKit
import RxSwift
import RxCocoa
import Result
import FontAwesome_swift

func toInvoiceModel(vals: [Payable]) -> [InvoiceCellModel] {
    return vals.map { payable in
        switch (payable) {
        case .invoice(let invoice):
            let iconSize = CGSize(width: 30, height: 30)
            let settled = UIImage.fontAwesomeIcon(name: .arrowRight, textColor: NanoColors.green, size: iconSize)
            let unsettled = UIImage.fontAwesomeIcon(name: .arrowRight, textColor: NanoColors.gray, size: iconSize)

            let attachment = NSTextAttachment()
            attachment.image = invoice.settled ? settled : unsettled
            let imageOffsetY: CGFloat = 0.0
            attachment.bounds = CGRect(
                    x: 0,
                    y: imageOffsetY,
                    width: attachment.image!.size.width,
                    height: attachment.image!.size.height
            )

            let attachmentString = NSAttributedString(attachment: attachment)

            let myString = NSMutableAttributedString(string: "")
            myString.append(attachmentString)

            let formatter = DateFormatter()
            formatter.dateStyle = .medium

            return InvoiceCellModel(
                    payable: payable,
                    leftVal: myString,
                    topLeftVal: "Amount: \(invoice.amount)",
                    botLeftVal: "\(invoice.description)",
                    botRightVal: "\(formatter.string(from: invoice.timestamp))"
            )
        case .payment(let payment):
            let icoSize = CGSize(width: 30, height: 30)
            let settled = UIImage.fontAwesomeIcon(name: .arrowLeft, textColor: NanoColors.red, size: icoSize)
            let unsettled = UIImage.fontAwesomeIcon(
                    name: .arrowRight,
                    textColor: NanoColors.green,
                    size: icoSize
            )

            let attachment = NSTextAttachment()
            attachment.image = payment.amount > 0 ? settled : unsettled
            let imageOffsetY: CGFloat = 0.0
            attachment.bounds = CGRect(
                    x: 0,
                    y: imageOffsetY,
                    width: attachment.image!.size.width,
                    height: attachment.image!.size.height
            )

            let attachmentString = NSAttributedString(attachment: attachment)

            let myString = NSMutableAttributedString(string: "")
            myString.append(attachmentString)

            let formatter = DateFormatter()
            formatter.dateStyle = .medium

            return InvoiceCellModel(
                    payable: payable,
                    leftVal: myString,
                    topLeftVal: "Amount: \(payment.amount)",
                    botLeftVal: "Fee: \(payment.fee)",
                    botRightVal: "\(formatter.string(from: payment.creationDate))"
            )
        }
    }
}

enum LoadInvoicesResult {
    case loading()
    case done(res : [Payable])
    case failure(error : Error)
}

class InvoicesTableViewController: UITableViewController {
    private let disposeBag = DisposeBag()

    let loadInvoices = BehaviorSubject<Void>(value: ())
    let invocesObs = PublishSubject<LoadInvoicesResult>()
    let invoicesObs = BehaviorSubject<[Payable]>(value: [])

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = nil
        self.tableView.rowHeight = 50
        self.tableView.register(InvoiceCell.self, forCellReuseIdentifier: InvoiceCell.ReuseIdentifier)

        invoicesObs.asObservable()
                .observeOn(MainScheduler.instance)
                .map { toInvoiceModel(vals: $0) }
                .bind(to: self.tableView.rx.items(
                        cellIdentifier: InvoiceCell.ReuseIdentifier,
                        cellType: InvoiceCell.self
                )) { (row, aModel: InvoiceCellModel, cell: InvoiceCell) in
                    cell.update(model: aModel)
                }
                .disposed(by: disposeBag)

        let refreshControl = UIRefreshControl()
        self.refreshControl = refreshControl

        invocesObs
                // go back to main thread to touch UI
                .observeOn(MainScheduler.instance)
                .subscribe(
                        onNext: { [weak self] result in
                            print("some refresh result")
                            switch (result) {
                            case .loading:
                                self?.refreshControl?.beginRefreshing()
                            case .done(let invoices):
                                self?.invoicesObs.onNext(invoices)
                                self?.refreshControl?.endRefreshing()
                            case .failure(let error):
                                print("got error on refresh: ", error)
                                self?.refreshControl?.endRefreshing()
                                displayError(message: "Error refreshing invoices.")
                            }
                        },
                        onError: { (error) in
                            print("refreshcontrol died: ", error)
                            fatalError("refreshcontrol died!")
                        })
                .disposed(by: disposeBag)

        self.tableView.rx.modelSelected(InvoiceCellModel.self)
                .map { (dataModel: InvoiceCellModel) in

                    switch (dataModel.payable) {
                    case .invoice(let invoice):
                        return PaymentCreatedModel(
                                amount: invoice.amount,
                                description: invoice.description,
                                paymentHash: invoice.payreq,
                                rHash: invoice.rHash
                        )
                    case .payment(let payment):
                        return PaymentCreatedModel(
                                amount: Int(payment.amount),
                                description: "Fee: \(payment.fee)",
                                paymentHash: payment.paymentHash,
                                rHash: Data()
                        )
                    }
                }
                .map { model in
                    PaymentCreatedVC.make(model: model)
                }
                .observeOn(MainScheduler.instance)
                .subscribe(
                        onNext: { [weak self] (view) in
                            self?.present(view, animated: true, completion: nil)
                        },
                        onError: { err in
                            print("fatal error", err)
                            fatalError("observable died")
                        })
                .disposed(by: disposeBag)

        loadInvoices
                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .flatMap { [weak self] (_) in
                    return (self?.getInvoices()
                        .map { invs in LoadInvoicesResult.done(res: invs) }
                        .catchError { err in Observable.just(LoadInvoicesResult.failure(error: err)) }
                        .startWith(LoadInvoicesResult.loading())) ?? Observable.empty()
                }
                .bind(to: invocesObs)
                .disposed(by: disposeBag)

        refreshControl.rx
                .controlEvent(.valueChanged)
                .map { [weak self] _ in
                    self?.refreshControl?.isRefreshing ?? false
                }
                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .filter { val in
                    val == true
                }
                .flatMap { [weak self] _ in
                    return (self?.getInvoices()
                        .map { invs in LoadInvoicesResult.done(res: invs) }
                        .catchError { err in Observable.just(LoadInvoicesResult.failure(error: err)) }
                        .startWith(LoadInvoicesResult.loading())) ?? Observable.empty()
                }
                .bind(to: invocesObs)
                .disposed(by: disposeBag)
    }

    private func getInvoices() -> Observable<[Payable]> {
        return InvoiceService.shared.listPayables()
                .map { (values : [Payable]) in
                    return values.sorted(by: { (lhs, rhs) in
                        return rhs < lhs
                    })
                }
    }

    private func refreshInvoices() {
        loadInvoices.onNext(())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshInvoices()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        do {
            return try self.invoicesObs.value().count
        } catch {
            return 0
        }
    }
}
