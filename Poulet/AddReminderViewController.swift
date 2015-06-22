//
//  AddReminderViewController.swift
//  Poulet
//
//  Created by Jiajun Wu on 6/14/15.
//  Copyright (c) 2015 Jiajun Wu. All rights reserved.
//

import UIKit

class AddReminderViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var inputField: UITextField!
    
    let reminder = Reminder()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        inputField.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        inputField.becomeFirstResponder()
    }
    
    // MARK: - Text Field Delegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if count(inputField.text ?? "") > 0 {
            if let name = inputField.text {
                reminder.name = name
                reminder.dueDate = NSDate(timeIntervalSince1970: 0)
                performSegueWithIdentifier("add", sender: self)
            }
        }
        return true // if true, autocorrect and autocapitalization will be triggered
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let lvc = segue.destinationViewController as? ListViewController {
            if let id = segue.identifier {
                switch id {
                case "add":
                    lvc.newReminder = reminder
                
                case "cancel":
                    fallthrough
                    
                default: break
                }
            }
        }
    }
    
}