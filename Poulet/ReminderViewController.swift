//
//  ReminderViewController.swift
//  Poulet
//
//  Created by Jiajun Wu on 6/14/15.
//  Copyright (c) 2015 Jiajun Wu. All rights reserved.
//

import UIKit

class ReminderViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    struct Picker {
        static let QuantityComponent = 0
        static let UnitsComponent = 1
    }
    
    var listViewController = ListViewController()
    var reminderIndexPathInListView = NSIndexPath()
    
    @IBOutlet weak var reminderFieldsTable: UITableView!
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
    
    var reminderFieldsWasEdited = false
    
    var FunctionalitiesPeriod: [String] {
        get{
            if let rmd = reminder {
                if !(rmd.recurrenceCycleQty == 1 || rmd.recurrenceCycleQty == 0) {
                    return Functionalities.Period_Plural
                }
            }
            return Functionalities.Period_Singular
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reminderFieldsTable.delegate = self
        reminderNameLabel.delegate = self
        recurrencePicker.delegate = self
        recurrencePicker.dataSource = self
        
        self.configureView()
        
        let dateLabelTapped = UITapGestureRecognizer(target: self, action: Selector("reminderDateLabelTapped"))
        reminderDateLabel.userInteractionEnabled = true
        reminderDateLabel.addGestureRecognizer(dateLabelTapped)
        
        let recurLabelTapped = UITapGestureRecognizer(target: self, action: Selector("reminderRecurLabelTapped"))
        reminderRecurLabel.userInteractionEnabled = true
        reminderRecurLabel.addGestureRecognizer(recurLabelTapped)
    }
    
    override func viewWillDisappear(animated: Bool) {
        if reminderNameLabel.isFirstResponder() {
            reminder?.name = reminderNameLabel.text
        }
        
        listViewController.tableView.reloadRowsAtIndexPaths([reminderIndexPathInListView as AnyObject], withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let rmd = reminder {
            reminderNameLabel?.text = rmd.name
            
            reminderDateLabel?.text = Functionalities.dateFormatter(rmd.dueDate)
            datePicker?.setDate(rmd.dueDate, animated: false)
            
            updateRecurrenceLabel()
            recurrencePicker?.selectRow(rmd.recurrenceCycleQty, inComponent: Picker.QuantityComponent, animated: true)
            recurrencePicker?.selectRow(rmd.recurrenceCycleUnit, inComponent: Picker.UnitsComponent, animated: true)
        }
    }
    
    @IBAction func datePicketValueChanged(sender: UIDatePicker) {
        if let rmd = reminder {
            rmd.dueDate = sender.date
            reminderDateLabel?.text = Functionalities.dateFormatter(rmd.dueDate)
            
            reminderFieldsWasEdited = true
        }
    }
    
    func updateRecurrenceLabel() {
        if let rmd = reminder {
            var labelText = "Every "
            
            if rmd.recurrenceCycleQty == 0 || rmd.recurrenceCycleUnit == 0 {
                labelText = "Not repeated"
            } else {
                if rmd.recurrenceCycleQty > 1 {
                    labelText += "\(rmd.recurrenceCycleQty) "
                }
                labelText += FunctionalitiesPeriod[rmd.recurrenceCycleUnit]
            }
            
            reminderRecurLabel?.text = labelText
        } else {
            reminderRecurLabel?.text = "No reminder"
        }
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
        
        if reminderFieldsWasEdited {
            println("true")
        } else {
            println("false")
        }
        if let tbvc = segue.destinationViewController as? ListViewController {
            println("hi")
            if reminderFieldsWasEdited {
                tbvc.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Text Field
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if let rmd = reminder {
            rmd.name = reminderNameLabel.text
            reminderFieldsWasEdited = true
        }
        
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
            return FunctionalitiesPeriod[row]
        } else {
            println("Error in func pickerView(titleForRow:forComponent:)")
            return ""
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Update Reminder object
        if let rmd = reminder {
            let quantityIndex = recurrencePicker.selectedRowInComponent(Picker.QuantityComponent)
            let unitIndex = recurrencePicker.selectedRowInComponent(Picker.UnitsComponent)
            rmd.updateRecurrenceForPickerIndexes(quantityIndex, unitIndex: unitIndex)
            reminderFieldsWasEdited = true
        }
        
        // Update Recurrence label
        updateRecurrenceLabel()
        
        recurrencePicker.reloadComponent(Picker.UnitsComponent)
    }
}

