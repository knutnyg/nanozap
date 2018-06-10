//
//  ViewController.swift
//  nanozap
//
//  Created by Knut Nygaard on 05/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import UIKit
import RxSwift

class WalletViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var transactionsView: UITableView!
    
    var transactions:[Transaction] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath)
        let transaction = transactions[indexPath.item]
        cell.textLabel?.text = "\(transaction.timestamp) - \(transaction.destination)"
        
        return cell
    }
    

    @IBOutlet weak var walletbalanceLabel: UILabel!

    let rpcmanager: RpcManager = RpcManager.shared

    // Creating a DisposeBag so subscription will be cancelled correctly
    let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        transactionsView.delegate = self
        transactionsView.dataSource = self
        
        
        
        guard let client = rpcmanager.client()
                else {
            return
        }
        do {
            let res = try client.walletBalance(Lnrpc_WalletBalanceRequest())
            walletbalanceLabel.text = String(format: "Balance: %ld", res.totalBalance)
            
            self.transactions = try WalletService.shared.listTransactions()
                .sorted(by: {$0.timestamp > $1.timestamp})
            
        } catch {
            print("Unexpected error: \(error).")
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

