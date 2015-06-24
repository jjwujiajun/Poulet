//
//  DetailViewController.swift
//  Poulet
//
//  Created by Jiajun Wu on 6/14/15.
//  Copyright (c) 2015 Jiajun Wu. All rights reserved.
//

import UIKit

class ReminderViewController: UIViewController {
    
    @IBOutlet weak var reminderNameLabel: UILabel!
    @IBOutlet weak var reminderDateLabel: UILabel!

    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let reminder = self.detailItem as? Reminder {
            reminderNameLabel?.text = reminder.name
            reminderDateLabel?.text = reminder.dueDate.description
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

}

