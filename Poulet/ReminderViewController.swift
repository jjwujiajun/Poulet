//
//  ReminderViewController.swift
//  Poulet
//
//  Created by Jiajun Wu on 6/14/15.
//  Copyright (c) 2015 Jiajun Wu. All rights reserved.
//

import UIKit

class ReminderViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    struct Picker {
        static let QuantityComponent = 0
        static let UnitsComponent = 1
        
    }
    
    @IBOutlet weak var reminderNameLabel: UITextField!
    @IBOutlet weak var reminderDateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var reminderRecurLabel: UILabel!
    @IBOutlet weak var recurrencePicker: UIPickerView!
    
    var reminder: Reminder? {
        didSet {
            self.configureView()
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if reminder != nil {
            reminderNameLabel?.text = reminder!.name
            reminderDateLabel?.text = Functionalities.dateFormatter(reminder!.dueDate)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        
        let dateLabelTapped = UITapGestureRecognizer(target: self, action: Selector("reminderDateLabelTapped"))
        reminderDateLabel.userInteractionEnabled = true
        reminderDateLabel.addGestureRecognizer(dateLabelTapped)
        
        let recurLabelTapped = UITapGestureRecognizer(target: self, action: Selector("reminderRecurLabelTapped"))
        reminderRecurLabel.userInteractionEnabled = true
        reminderRecurLabel.addGestureRecognizer(recurLabelTapped)
        
        reminderNameLabel.delegate = self
        recurrencePicker.delegate = self
        recurrencePicker.dataSource = self
    }
    
    @IBAction func datePicketValueChanged(sender: UIDatePicker) {
        reminderDateLabel?.text = Functionalities.dateFormatter(sender.date)
    }
    
    
    // MARK: - Selector functions
    func reminderDateLabelTapped() {
        if reminderNameLabel.isFirstResponder() {
            reminderNameLabel.resignFirstResponder()
        }
    }
    
    func reminderRecurLabelTapped() {
        if reminderNameLabel.isFirstResponder() {
            reminderNameLabel.resignFirstResponder()
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if count(reminderNameLabel.text ?? "") == 0 {
            //
        }
    }
    
    // MARK: - Text Field
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true // if true, autocorrect and autocapitalization will be triggered
    }
    
    // MARK: - Picker View delegate and dataSource
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case Picker.QuantityComponent:
            return 7
        case Picker.UnitsComponent:
            return 5
        default:
            return 0
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        if component == Picker.QuantityComponent {
            return "\(row)"
        } else if component == Picker.UnitsComponent {
            return Functionalities.Period[row]
        } else {
            println("Error in func pickerView(titleForRow:forComponent:)")
            return ""
        }
    }
}

