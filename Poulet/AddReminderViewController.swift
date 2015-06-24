//
//  AddReminderViewController.swift
//  Poulet
//
//  Created by Jiajun Wu on 6/14/15.
//  Copyright (c) 2015 Jiajun Wu. All rights reserved.
//

import UIKit

class AddReminderViewController: UIViewController, UITextFieldDelegate {
    
    struct Time {
        static let Minute:Double = 60
        static let Hour:Double = 60 * Time.Minute
        static let Day:Double = 24 * Time.Hour
        static let Week:Double = 7 * Time.Day
    }
    let WeekDay = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    let Month = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

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
                let currentHour = Double(gregorian.component(.CalendarUnitHour, fromDate: NSDate()))
                let currentMinute = Double(gregorian.component(.CalendarUnitMinute, fromDate: NSDate()))
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
    @IBAction func datePickerValueChanged(datePicker: UIDatePicker) {
        timeLabelDate = datePicker.date
    }
    
    @IBAction func addButtonTouchUp(sender: UIButton) {
        reminder.name = inputField.text
        reminder.dueDate = datePicker.date
        
        performSegueWithIdentifier("add", sender: self)
    }
    
    var reminder = Reminder()
    
    var timeLabelDate = NSDate() {
        didSet {
            var dateString: String? = ""
            var timeString: String? = ""
            if let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) {
                var timeFromNow = timeLabelDate.timeIntervalSinceDate(NSDate())
                
                if timeFromNow > 0 && timeFromNow < 2 * Time.Hour {
                    if dateString != nil {
                        dateString = "In"
                    }
                    if Int(timeFromNow/Time.Hour) > 0 {
                        dateString = dateString! + " \(Int(timeFromNow/Time.Hour)) hours"
                        timeFromNow = timeFromNow%Time.Hour
                    }
                    if timeFromNow > 0 {
                        dateString = dateString! + " \(Int(timeFromNow/Time.Minute)) minutes"
                    }
                } else {
                    let dateToday = gregorian.component(.CalendarUnitDay, fromDate: NSDate())
                    let dateSet = gregorian.component(.CalendarUnitDay, fromDate: timeLabelDate)
                    
                    println(dateToday , " ",  dateSet);
                    
                    if dateSet == dateToday {
                        dateString = "Today"
                    } else if dateSet - 1 == dateToday {
                        dateString = "Tomorrow"
                    } else if timeFromNow < 1 * Time.Week {
                        let weekday = gregorian.component(.CalendarUnitWeekday, fromDate: timeLabelDate)
                        dateString = "On " + WeekDay[weekday]
                    } else {
                        let month = gregorian.component(.CalendarUnitMonth, fromDate: timeLabelDate)
                        let date = gregorian.component(.CalendarUnitDay, fromDate: timeLabelDate)
                        dateString = "On " + Month[month] + " \(date)"
                    }
                    let hour = gregorian.component(.CalendarUnitHour, fromDate: timeLabelDate)
                    let minute = gregorian.component(.CalendarUnitMinute, fromDate: timeLabelDate)
                    var minuteString = ""
                    if minute < 10 {
                        minuteString = "0" + "\(minute)"
                    } else {
                        minuteString = "\(minute)"
                    }
                    dateString = (dateString ?? "") + " at \(hour):" + minuteString
                }
            }
            timeLabel.text = dateString;
        }
    }
    
    var timeSectionIsEnabled = false {
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
            addButton.enabled = timeSectionIsEnabled
            
            if self.addButton.enabled {
                self.addButton.backgroundColor = UIColor.orangeColor()
            } else {
                self.addButton.backgroundColor = UIColor.whiteColor()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        inputField.delegate = self
        timeSectionIsEnabled = false
        datePicker.minimumDate = NSDate()
        datePicker.date = NSDate(timeIntervalSinceNow: 11 * Time.Minute)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        inputField.becomeFirstResponder()
    }
    
    // MARK: - Text Field Delegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if count(inputField.text ?? "") > 0 {
            textField.resignFirstResponder()
            timeSectionIsEnabled = true
            timeLabelDate = datePicker.date
            println(datePicker.date)
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