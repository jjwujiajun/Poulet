//
//  ReminderViewController.swift
//  Poulet
//
//  Created by Jiajun Wu on 6/14/15.
//  Copyright (c) 2015 Jiajun Wu. All rights reserved.
//

import UIKit

class ReminderViewController: UITableViewController, UITextViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // TODO: Let view be expandable just like native cal app
    
    struct Picker {
        static let QuantityComponent = 0
        static let UnitsComponent = 1
    }
    
    // MARK: - View Outlets
    @IBOutlet weak var reminderFieldsTable: UITableView!
    @IBOutlet weak var reminderNameLabel2: UITextView!
    @IBOutlet weak var reminderDateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var reminderRecurLabel: UILabel!
    @IBOutlet weak var recurrencePicker: UIPickerView!
    
    // MARK: - Logic properties
    var listViewController = ListViewController()
    var reminderFieldsWasEdited = false
    var reminder: Reminder? {
        didSet {
            self.configureView()
        }
    }
    var oldRmdNameLabel: String?
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
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        reminderFieldsTable.delegate = self
        reminderNameLabel2.delegate = self
        recurrencePicker.delegate = self
        recurrencePicker.dataSource = self
        
        self.configureView()
        
        let dateLabelTapped = UITapGestureRecognizer(target: self, action: Selector("reminderDateLabelTapped"))
        reminderDateLabel.userInteractionEnabled = true
        reminderDateLabel.addGestureRecognizer(dateLabelTapped)
        
        let recurLabelTapped = UITapGestureRecognizer(target: self, action: Selector("reminderRecurLabelTapped"))
        reminderRecurLabel.userInteractionEnabled = true
        reminderRecurLabel.addGestureRecognizer(recurLabelTapped)
        
        reminder?.oldDueDate = reminder?.dueDate
        oldRmdNameLabel = reminder?.name
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        if reminderNameLabel2.isFirstResponder() {
            saveNameLabelText()
            
        }
        
        if reminderFieldsWasEdited {
            if reminder != nil {
                if reminder!.name?.characters.count == 0 {
                    reminder!.name = oldRmdNameLabel
                }
                if reminder!.oldDueDate == reminder!.dueDate {
                    reminder!.oldDueDate = nil
                } else {
                    reminder!.updateNextRecurringDueDate()
                }
                listViewController.editedReminder = reminder!
            }
        }
    }
    
    
    // MARK: - Class functions
    func configureView() {
        // Update the user interface for the detail item.
        if let rmd = reminder {
            reminderNameLabel2?.text = rmd.name
            
            if let dueDate = rmd.dueDate {
                reminderDateLabel?.text = Functionalities.dateFormatter(dueDate)
                datePicker?.setDate(dueDate, animated: false)
            }
            
            updateRecurrenceLabel()
            
            if let picker = recurrencePicker {
                if let recurrenceCycleQty = rmd.recurrenceCycleQty as? Int {
                    picker.selectRow(recurrenceCycleQty, inComponent: Picker.QuantityComponent, animated: true)
                }
                if let recurrenceCycleUnit = rmd.recurrenceCycleUnit as? Int {
                    picker.selectRow(recurrenceCycleUnit, inComponent: Picker.UnitsComponent, animated: true)
                }
            }
        }
    }
    
    @IBAction func datePicketValueChanged(sender: UIDatePicker) {
        
        if let rmd = reminder {
            rmd.dueDate = sender.date
            reminderDateLabel?.text = Functionalities.dateFormatter(sender.date)
            
            reminderFieldsWasEdited = true
        }
    }
    
    func updateRecurrenceLabel() {
        if let rmd = reminder {
            var labelText = "Every "
            
            if rmd.recurrenceCycleQty == 0 || rmd.recurrenceCycleUnit == 0 {
                labelText = "Not repeated"
            } else {
                if let recurrenceCycleQty = rmd.recurrenceCycleQty as? Int {
                    if recurrenceCycleQty > 1 {
                        labelText += "\(recurrenceCycleQty) "
                    }
                }
                labelText += FunctionalitiesPeriod[(rmd.recurrenceCycleUnit ?? 0) as Int]
            }
            
            reminderRecurLabel?.text = labelText
        } else {
            reminderRecurLabel?.text = "No reminder"
        }
    }
    
    // MARK: - Selector functions
    func reminderDateLabelTapped() {
        if reminderNameLabel2.isFirstResponder() {
            reminderNameLabel2.resignFirstResponder()
        }
    }
    
    func reminderRecurLabelTapped() {
        if reminderNameLabel2.isFirstResponder() {
            reminderNameLabel2.resignFirstResponder()
        }
    }
    
    // MARK: - Text Field delegate
    func textViewDidChange(textView: UITextView) {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            print(reminderNameLabel2.contentSize.height)
            if reminderNameLabel2.contentSize.height >= 32 {
                let newSize = reminderNameLabel2.sizeThatFits(CGSize(width: reminderNameLabel2.frame.width, height: CGFloat.max))
                let newCellHeight = newSize.height + 8
                
                print(newCellHeight)
                return newCellHeight
            } else {
                return 32
            }
        } else if indexPath.row == 1 || indexPath.row == 3 {
            return 44
        } else {
            return 216
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        saveNameLabelText()
    }
    
    func saveNameLabelText() {
        if let rmd = reminder {
            if rmd.name != reminderNameLabel2.text {
                rmd.name = reminderNameLabel2.text
                reminderFieldsWasEdited = true
                print(reminderFieldsWasEdited)
            }
        }
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
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == Picker.QuantityComponent {
            return "\(row)"
        } else if component == Picker.UnitsComponent {
            return FunctionalitiesPeriod[row]
        } else {
            print("Error in func pickerView(titleForRow:forComponent:)")
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

