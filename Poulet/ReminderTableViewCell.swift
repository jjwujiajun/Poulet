//
//  ReminderTableViewCell.swift
//  Poulet
//
//  Created by Jiajun Wu on 9/13/15.
//  Copyright (c) 2015 Jiajun Wu. All rights reserved.
//

import UIKit

class ReminderTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    var reminder: Reminder? {
        didSet {
            if let rmd = reminder {
                name?.text = rmd.name
                if let rmdDueDate = rmd.dueDate {
                    dueDate?.text = Functionalities.dateFormatter(rmdDueDate)
                }
                recurIntegerLabel.text = ""
                if rmd.isRecurring == 1{
                    doneButton.imageView?.image = UIImage(named: "ReminderRecurButton")
                    if rmd.recurrenceCycleUnit as? Int == Functionalities.Time.unitsArray.indexOf(Functionalities.Time.Day) {
                        if rmd.recurrenceCycleQty == 1 {
                            recurIntegerLabel.text = "24"
                        } else {
                            recurIntegerLabel.text = "\(rmd.recurrenceCycleQty as! Int)"
                        }
                    } else if rmd.recurrenceCycleUnit as? Int == Functionalities.Time.unitsArray.indexOf(Functionalities.Time.Week) {
                        if rmd.recurrenceCycleQty == 1 {
                            recurIntegerLabel.text = "7"
                        } else {
                            recurIntegerLabel.text = "\(rmd.recurrenceCycleQty as! Int)"
                        }
                    } else if rmd.recurrenceCycleUnit as? Int == Functionalities.Time.unitsArray.indexOf(Functionalities.Time.Hour) {
                        if rmd.recurrenceCycleQty == 1 {
                            recurIntegerLabel.text = "60"
                        } else {
                            recurIntegerLabel.text = "\(rmd.recurrenceCycleQty as! Int)"
                        }
                    } else {
                        recurIntegerLabel.text = "\(rmd.recurrenceCycleQty as! Int)"
                    }
                } else {
                    doneButton.imageView?.image = UIImage(named: "ReminderDoneButton")
                }
            }
        }
    }
    
    var tableView = UITableView()
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var dueDate: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var recurIntegerLabel: UILabel!
    
    @IBAction func doneButtonPressed(sender: UIButton) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let notification = NSNotification(name: Functionalities.Notification.ReminderDone, object: self, userInfo: [Functionalities.Notification.ReminderUUID: reminder?.uuid as! String])
        notificationCenter.postNotification(notification)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
