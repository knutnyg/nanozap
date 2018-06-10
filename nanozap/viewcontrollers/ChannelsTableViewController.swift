//
//  ChannelsTableViewController.swift
//  nanozap
//
//  Created by Knut Nygaard on 06/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation
import UIKit

class ChannelsTableViewController: UITableViewController {
    var channels:[Channel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            let channelService = ChannelService()
            self.channels = try channelService.getChannels()
                .sorted(by: {$0.localBalance > $1.localBalance})
        } catch {
            print("Unexpected error: \(error).")
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)
        
        cell.textLabel?.text = "ID: \(channels[indexPath.row].channelId) $: \(channels[indexPath.row].localBalance)"
        
        return cell
    }
    
}

