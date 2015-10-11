//
//  AddReminderViewController.swift
//  Poulet
//
//  Created by Jiajun Wu on 6/14/15.
//  Copyright (c) 2015 Jiajun Wu. All rights reserved.
//

import UIKit
import CoreData

class AddReminderViewController: UIViewController, UITextFieldDelegate {
    
    struct Time {
        static let Minute = Functionalities.Time.Minute
        static let Hour = Functionalities.Time.Hour
        static let Day = Functionalities.Time.Day
        static let Week = Functionalities.Time.Week
    }

    @IBOutlet weak var inputField: UITextField!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var relativeTimeButton1: UIButton!
    @IBOutlet weak var relativeTimeButton2: UIButton!
    @IBOutlet weak var relativeTimeButton3: UIButton!
    @IBOutlet weak var relativeTimeButton4: UIButton!
    @IBOutlet weak var relativeTimeButton5: UIButton!
    @IBOutlet weak var relativeTimeButton6: UIButton!
    @IBOutlet weak var relativeTimeButton7: UIButton!
    @IBOutlet weak var relativeTimeButton8: UIButton!
    
    @IBOutlet weak var absoluteTimeButton1: UIButton!
    @IBOutlet weak var absoluteTimeButton2: UIButton!
    @IBOutlet weak var absoluteTimeButton3: UIButton!
    @IBOutlet weak var absoluteTimeButton4: UIButton!
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    private var timeLabelDate = NSDate() {
        didSet {
            timeLabel.text = Functionalities.dateFormatter(timeLabelDate)
        }
    }
    
    private var timeSectionIsEnabled = false {
        didSet {
            timeLabel.enabled = timeSectionIsEnabled
            relativeTimeButton1.enabled = timeSectionIsEnabled
            relativeTimeButton2.enabled = timeSectionIsEnabled
            relativeTimeButton3.enabled = timeSectionIsEnabled
            relativeTimeButton4.enabled = timeSectionIsEnabled
            relativeTimeButton5.enabled = timeSectionIsEnabled
            relativeTimeButton6.enabled = timeSectionIsEnabled
            relativeTimeButton7.enabled = timeSectionIsEnabled
            relativeTimeButton8.enabled = timeSectionIsEnabled
            absoluteTimeButton1.enabled = timeSectionIsEnabled
            absoluteTimeButton2.enabled = timeSectionIsEnabled
            absoluteTimeButton3.enabled = timeSectionIsEnabled
            absoluteTimeButton4.enabled = timeSectionIsEnabled
        }
    }
    private var addButtonIsEnabled = false {
        didSet {
            addButton.enabled = addButtonIsEnabled
            
            if self.addButton.enabled {
                self.addButton.backgroundColor = UIColor.orangeColor()
            } else {
                self.addButton.backgroundColor = UIColor.whiteColor()
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func absoluteTimeButtonTouchUp(button: UIButton) {
        if let option = button.titleLabel?.text {
            var hourSet = 0.0;
            switch option {
            case "Morning":
                hourSet = 8
            case "Noon":
                hourSet = 13
            case "Evening":
                hourSet = 19
            case "Night":
                hourSet = 22
            default:
                break
            }
            if let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) {
                let currentHour = Double(gregorian.component(.Hour, fromDate: NSDate()))
                let currentMinute = Double(gregorian.component(.Minute, fromDate: NSDate()))
                var forwardedTime = 0.0
                if currentHour >= hourSet {
                    forwardedTime = (24 - currentHour + hourSet) * Time.Hour - currentMinute * Time.Minute
                } else {
                    forwardedTime = (hourSet - currentHour) * Time.Hour - currentMinute * Time.Minute
                }
                datePicker.date = NSDate(timeInterval: forwardedTime, sinceDate: NSDate())
            }
            timeLabelDate = datePicker.date
        }
    }
    
    @IBAction func relativeTimeButtonTouchUp(button: UIButton) {
        if let option = button.titleLabel?.text {
            switch option {
            case "+ 10 min":
                datePicker.date = NSDate(timeInterval: 10 * Time.Minute, sinceDate: datePicker.date)
            case "+ 30 min":
                datePicker.date = NSDate(timeInterval: 30 * Time.Minute, sinceDate: datePicker.date)
            case "+ 1 hour":
                datePicker.date = NSDate(timeInterval: 1 * Time.Hour, sinceDate: datePicker.date)
            case "+ 1 day":
                datePicker.date = NSDate(timeInterval: 1 * Time.Day, sinceDate: datePicker.date)
            case "- 10 min":
                datePicker.date = NSDate(timeInterval: -10 * Time.Minute, sinceDate: datePicker.date)
            case "- 30 min":
                datePicker.date = NSDate(timeInterval: -30 * Time.Minute, sinceDate: datePicker.date)
            case "- 1 hour":
                datePicker.date = NSDate(timeInterval: -1 * Time.Hour, sinceDate: datePicker.date)
            case "- 1 day":
                datePicker.date = NSDate(timeInterval: -1 * Time.Day, sinceDate: datePicker.date)
            default:
                break
            }
            timeLabelDate = datePicker.date
        }
    }
    
    @IBAction func datePickerValueChanged(datePicker: UIDatePicker) {
        timeLabelDate = datePicker.date
    }
    
    @IBAction func addButtonTouchUp(sender: UIButton) {
        performSegueWithIdentifier("add", sender: self)
    }
    
    // MARK: - View
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        inputField.delegate = self
        inputField.addTarget(self, action:"textFieldDidClear", forControlEvents: .EditingChanged)
        timeSectionIsEnabled = false
        addButtonIsEnabled = false
        datePicker.minimumDate = NSDate()
        datePicker.date = NSDate(timeIntervalSinceNow: 11 * Time.Minute)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        inputField.becomeFirstResponder()
    }
    
    // MARK: - Text Field
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (inputField.text ?? "").characters.count > 0 {
            textField.resignFirstResponder()
            timeSectionIsEnabled = true
            addButtonIsEnabled = true
            timeLabelDate = datePicker.date
        }
        return true // if true, autocorrect and autocapitalization will be triggered
    }
    
    func textFieldDidClear() {
        if (inputField.text ?? "").characters.count == 0 {
            timeSectionIsEnabled = false
            addButtonIsEnabled = false
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let lvc = segue.destinationViewController as? ListViewController {
            if let id = segue.identifier {
                switch id {
                case "add":
                    if (inputField.text ?? "").characters.count > 0 {
                        if let reminder = NSEntityDescription.insertNewObjectForEntityForName("Reminder", inManagedObjectContext: managedObjectContext) as? Reminder{
                                
                            reminder.name = inputField.text
                            reminder.dueDate = datePicker.date
                            
                            // TODO 2: Should use a more notification based reach out?
                            // Or no need, because the LVC explicitly lent AddRmdVC the power, when making itself the delegate
                            // Therefore should just private/public appropriate functions in LVC?
                            lvc.insertNewReminder(reminder, withStyle: .Automatic)
                        }
                    }
                
                case "cancel":
                    fallthrough
                    
                default: break
                }
            }
        }
    }
    
}