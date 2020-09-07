//
//  HistoryViewControllerTableViewCell.swift
//  POW
//
//  Created by Gabriela Villalobos on 07.06.17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class HistoryViewControllerTableViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
