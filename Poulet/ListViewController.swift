//
//  ListController.swift
//  Poulet
//
//  Created by Jiajun Wu on 6/14/15.
//  Copyright (c) 2015 Jiajun Wu. All rights reserved.
//

import UIKit
import CoreData

class ListViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    private var detailViewController: ReminderViewController? = nil
    private let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    private let application = UIApplication.sharedApplication()
    
    private var reminders = [Reminder]()
    var newReminder: Reminder?
    var editedReminder: Reminder?
    
    private var selectedReminder = -1
    private var reminderToHideDrawer = -1

    @IBAction func addReminder(sender: UIBarButtonItem) {
    }
    
    // MARK: - View Controller Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Refresh table every 1 minute/"n" seconds (Use NSFetchedResultsController for notifying tabableview when datachanges?)
        
        // Fetch data
        fetchSortedReminders()
        
        // Set up notification center
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        let FN = Functionalities.Notification.self
        center.addObserverForName(FN.EnterAppByNotification, object: nil, queue: queue) { notif in print("EnterAppByNotification") }
        center.addObserverForName(FN.RefreshTable, object: nil, queue: queue) { notif in self.tableView.reloadData() }
        center.addObserverForName(FN.ResigningActive, object: nil, queue: queue) { notif in
            self.notifyAppResigningActive(notif) }
        center.addObserverForName(FN.ReminderDone, object: nil, queue: queue) { notif in self.notifyReminderDone(notif) }
        center.addObserverForName(FN.ReminderBug, object: nil, queue: queue) { notif in self.notifyReminderBug(notif) }
        center.addObserverForName(FN.ReminderPostpone, object: nil, queue: queue) { notif in self.notifyReminderPostpone(notif) }
        center.addObserverForName(FN.ReminderDelete, object: nil, queue: queue) { notif in self.notifyReminderDelete(notif) }
    
        // Set up display
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1] as? ReminderViewController // Self's detailVC is ReminderVC
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        print("Scheduled LocalNotif : \(application.scheduledLocalNotifications?.count ?? 0)")
        
        super.viewDidAppear(animated)
        print("vda")
        if newReminder != nil { // If view appeared after AddRmdVC created new rmd
            fetchSortedReminders()
            saveReminders()
            createLocalNotification(newReminder!, isForBugging: false)
            animateInsertRmdIntoList(newReminder!)
            
            newReminder = nil
        }
        
        if editedReminder != nil {
            editReminder(editedReminder!)
            editedReminder = nil
        }
    }
    
    // MARK: - Executing model change
    
    private func insertNewReminder(reminder: Reminder) {
        // New data is brought in from AddReminderVC. Update Data Model
        fetchSortedReminders()
        saveReminders()
        
        let thisFuncIsPartOfShiftingProcess = reminder.oldDueDate != nil
        if !thisFuncIsPartOfShiftingProcess {
            createLocalNotification(reminder, isForBugging: false)
        }
        animateInsertRmdIntoList(reminder)
    }
    
    func editReminder(reminder: Reminder) {
        if let oldRow = reminders.indexOf(reminder) {
            
            let previousRow = oldRow - 1
            let rmdHasMovedUp = previousRow >= 0 &&
                reminder.dueDate?.timeIntervalSinceDate(reminders[previousRow].dueDate!) < 0
            
            let nextRow = oldRow + 1
            let rmdHasMovedDown = nextRow < reminders.count &&
                reminder.dueDate?.timeIntervalSinceDate(reminders[nextRow].dueDate!) > 0
            
            if rmdHasMovedUp || rmdHasMovedDown {
                let isRecurring = reminder.isRecurring
                let recurQty = reminder.recurrenceCycleQty
                let recurUnit = reminder.recurrenceCycleUnit
                
                if let newRmd = shiftReminder(reminder, toPositionForDate: reminder.dueDate!) { // handlesNotification changes
                    newRmd.isRecurring = isRecurring
                    newRmd.recurrenceCycleQty = recurQty
                    newRmd.recurrenceCycleUnit = recurUnit
                    if newRmd.nextRecurringDate == nil {
                        newRmd.updateNextRecurringDueDate()
                    }
                    newRmd.oldDueDate = nil
                    
                    if let row = reminders.indexOf(newRmd) {
                        let indexPath = NSIndexPath(forRow: row, inSection: 0)
                        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                    }
                }
                
                fetchSortedReminders()
            } else {
                
                fetchSortedReminders()
                tableView.reloadData()
                if reminder.oldDueDate != reminder.dueDate {
                    deleteLocalNotificationForReminder(reminder.uuid as String?, isForBugging: false)
                    fillEmptySlotInNotificationQueue()
                }
                reminder.oldDueDate = nil
            }
            saveReminders()
        }
    }
    
    private func deleteReminder(rmd: Reminder) {
        
        // Close Reminder drawer – must be done before core data is deleted
        let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedReminder, inSection: 0)) as! ReminderTableViewCell
        cell.hideDrawer()
        tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: selectedReminder, inSection: 0)], withRowAnimation: .Automatic)
        selectedReminder = -1
        
        // Hold logical data before core data is deleted
        var path: NSIndexPath?
        if let row = reminders.indexOf(rmd) {
            path = NSIndexPath(forRow: row, inSection: 0)
        }
        let thisFuncIsPartOfShiftingProcess = rmd.oldDueDate != nil
        let uuid = rmd.uuid as String?
        
        // Core data – delete reminder
        managedObjectContext.deleteObject(rmd) // Non-core data implementation: reminders.removeAtIndex(row)
        fetchSortedReminders()
        saveReminders()
        
        // Animation and notification
        if path != nil {
            if thisFuncIsPartOfShiftingProcess {
                tableView.deleteRowsAtIndexPaths([path!], withRowAnimation: .Right)
            } else {
                tableView.deleteRowsAtIndexPaths([path!], withRowAnimation: .Fade)
                deleteLocalNotificationForReminder(uuid, isForBugging: false)
                fillEmptySlotInNotificationQueue()
            }
            application.applicationIconBadgeNumber -= 1
        }
    }
    
    private func doneReminder(rmd: Reminder) {
        
        rmd.isDone? = NSNumber(bool: true)
        
        if rmd.isRecurring?.boolValue ?? false {
            let isRecurring = rmd.isRecurring
            let recurrenceCycleQty = rmd.recurrenceCycleQty
            let recurrenceCycleUnit = rmd.recurrenceCycleUnit
            
            if let newRmd = shiftReminder(rmd, toPositionForDate: rmd.nextRecurringDate!) {
                newRmd.isRecurring = isRecurring
                newRmd.recurrenceCycleQty = recurrenceCycleQty
                newRmd.recurrenceCycleUnit = recurrenceCycleUnit
                newRmd.updateNextRecurringDueDate()
                
                if let row = reminders.indexOf(newRmd) {
                    let indexPath = NSIndexPath(forRow: row, inSection: 0)
                    tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                }
            }

        } else {
            // TODO: Create an archive list to save all done reminders before deleting over here
            deleteReminder(rmd)
        }
    }
    
    private func postponeReminder(rmd: Reminder, byTimeInterval time: NSTimeInterval) {
        
        if rmd.dueDate?.timeIntervalSinceNow < -1 && rmd.dueDate?.timeIntervalSinceNow < -time {
            rmd.dueDate = NSDate().dateByAddingTimeInterval(time)
        } else {
            rmd.dueDate = rmd.dueDate?.dateByAddingTimeInterval(time)
        }
        rmd.updateNextRecurringDueDate()
        editReminder(rmd)
    }
    
    private func animateInsertRmdIntoList(reminder: Reminder) {
        if let row = reminders.indexOf(reminder) { // will not work if did not call fetchSortedReminders()
            let insertIndex = NSIndexPath(forRow: row, inSection: 0)
            
            tableView.insertRowsAtIndexPaths([insertIndex], withRowAnimation: .Right)
        }
    }
    
    private func shiftReminder(rmd:Reminder, toPositionForDate finalDate: NSDate) -> Reminder? {
        
        let name = rmd.name
        let oldDueDate = rmd.oldDueDate
        let dueDate = finalDate
        let uuid = rmd.uuid
        
        deleteReminder(rmd)
        
        if let reminder = NSEntityDescription.insertNewObjectForEntityForName(Functionalities.Entity.Reminder, inManagedObjectContext: managedObjectContext) as? Reminder{
            
            reminder.name = name
            reminder.uuid = NSUUID().UUIDString
            reminder.oldDueDate = oldDueDate
            reminder.dueDate = dueDate
            
            insertNewReminder(reminder)
            
            deleteLocalNotificationForReminder(uuid as String?, isForBugging: false)
            fillEmptySlotInNotificationQueue()
            
            return reminder
        }
        return nil
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showReminder" {
            if selectedReminder != -1 {
                let row = selectedReminder
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! ReminderViewController
                controller.reminder = reminders[row]
                controller.listViewController = self
                
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    @IBAction func unwindToList(segue: UIStoryboardSegue) {
        if !segue.sourceViewController.isBeingDismissed() {
            segue.sourceViewController.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("ReminderCell", forIndexPath: indexPath) as! ReminderTableViewCell
        cell.reminder = reminders[indexPath.row]
        cell.tableView = self.tableView
        
        if indexPath.row == selectedReminder {
            cell.revealDrawer()
        } else {
            cell.hideDrawer()
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        if selectedReminder == -1 {
            selectedReminder = indexPath.row
        } else if selectedReminder == indexPath.row {
            selectedReminder = -1
        } else {
            reminderToHideDrawer = selectedReminder
            selectedReminder = indexPath.row
        }
        
        tableView.beginUpdates()
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        tableView.endUpdates()
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! ReminderTableViewCell
        if selectedReminder != -1 {
            cell.revealDrawer()
        } else {
            cell.hideDrawer()
        }
        
        if reminderToHideDrawer != -1 {
            let keepCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: reminderToHideDrawer, inSection: 0)) as! ReminderTableViewCell
            keepCell.hideDrawer()
            reminderToHideDrawer = -1
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if selectedReminder == indexPath.row {
            return 125
        } else {
            return 77
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let reminderCell = cell as? ReminderTableViewCell {
            if reminderCell.reminder?.dueDate?.timeIntervalSinceNow <= 0 {
                reminderCell.backgroundColor = Functionalities.ReminderCell.overdueColor // Or use .backgroundView if want to use a image/view for background instead
            } else {
                reminderCell.backgroundColor = Functionalities.ReminderCell.notDueColor
            }
        }
    }
    
    // This two delegate methods go hand-in-hand.
    // If canEditRowAtIndexPath returns false, then cannot slide UITableViewCell to select options in commitEditingStyle:ForRowAtIndexPath
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            deleteReminder(reminders[indexPath.row])
            // Non-core data execution          reminders.removeAtIndex(indexPath.row)
            
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    // MARK: - Core Data
    private func fetchSortedReminders() {
        let fetchRequest = NSFetchRequest(entityName: Functionalities.Entity.Reminder)
        let sortDescriptor = NSSortDescriptor(key: Functionalities.Entity.Reminder_sortKey, ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            if let fetchResults = try managedObjectContext.executeFetchRequest(fetchRequest) as? [Reminder] {
                reminders = fetchResults
            }
        } catch {
            abort()
        }
    }
    
    private func saveReminders() {
        do {
            try managedObjectContext.save()
        } catch {
            print("Cannot save, in ListVC.saveReminders()")
        }
    }
    
    // MARK: - Local Notifications
    private func createLocalNotification(reminder: Reminder, isForBugging: Bool) {
        let scheduledLocalNotifications = application.scheduledLocalNotifications
        if let count = scheduledLocalNotifications?.count {
            
            if count < Functionalities.Notification.ScheduleLimit {
            
                // Create a corresponding local notification
                let notification = UILocalNotification()
                notification.alertBody = reminder.name
                notification.soundName = UILocalNotificationDefaultSoundName
                notification.userInfo = [Functionalities.Notification.ReminderUUID: reminder.uuid! as String]
                notification.alertAction = "Open" //defaults to "slide to view"
                notification.category = Functionalities.Notification.Category_ToDo
                
                if isForBugging {
                    notification.fireDate = reminder.dueDate?.dateByAddingTimeInterval(1 * Functionalities.Time.Minute)
                    notification.repeatInterval = .Minute
                } else {
                    notification.fireDate = reminder.dueDate
                    notification.applicationIconBadgeNumber = application.applicationIconBadgeNumber + 1
                }
                
                // if reminder is < 64th, schedule. Update when old ones are completed
                application.scheduleLocalNotification(notification)
                print("created notif: " + notification.alertBody!)
                if !isForBugging {
                    if reminder.isBugged {
                        print("creating accompanying bugging notif...")
                        createLocalNotification(reminder, isForBugging: true)
                    }
                }
                
            } else if let lastScheduledRmdNotif = scheduledLocalNotifications?[count - 1] {
                if let lastScheduledRmdUserInfo = lastScheduledRmdNotif.userInfo {
                    for rmd in reminders {
                        if lastScheduledRmdUserInfo[Functionalities.Notification.ReminderUUID] as! String == rmd.uuid {
                            let scheduledRmd = rmd
                            if let lastScheduledRmdDueDate = scheduledRmd.dueDate {
                                
                                if reminder.dueDate?.timeIntervalSinceDate(lastScheduledRmdDueDate) < 0 {
                                    
                                    deleteLocalNotificationForReminder(rmd.uuid as String?, isForBugging: false)
                                    createLocalNotification(reminder, isForBugging: isForBugging)
                                }
                                break
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func deleteLocalNotificationForReminder(UUID: String?, isForBugging: Bool) {
        if UUID != nil {
            if let scheduledNotifications = application.scheduledLocalNotifications {
                if isForBugging {
                    for notification in scheduledNotifications {
                        if notification.repeatInterval == .Minute {
                            if notification.userInfo?[Functionalities.Notification.ReminderUUID] as? String == UUID! {
                                notification.repeatInterval = NSCalendarUnit(rawValue: 0)
                                application.cancelLocalNotification(notification)
                                print("cancelled bugging notif: " + notification.alertBody!)
                                break
                            }
                        }
                    }
                } else {
                    for notification in scheduledNotifications {
                        if let userInfo = notification.userInfo {
                            if userInfo[Functionalities.Notification.ReminderUUID] as? String == UUID! {
                                application.cancelLocalNotification(notification)
                                print("cancelled notif: " + notification.alertBody!)
                                print("deleting accompanying bugging notif...")
                                deleteLocalNotificationForReminder(UUID!, isForBugging: true)
                                break
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fillEmptySlotInNotificationQueue() {
        // TODO: shift [reminder] into class List. instead of having var reminders
        
        // find 64th non-dued in line to be scheduled
        var i = 0
        for rmd in reminders {
            if rmd.dueDate?.timeIntervalSinceNow > 0 {
                
                i++;
                if i == Functionalities.Notification.ScheduleLimit || i == reminders.count {
                    print("Fill slot with " + rmd.name! + " by: ")
                    createLocalNotification(rmd, isForBugging: false)
                    break
                }
            }
        }
    }
    
    private func notifyReminderDone(notification: NSNotification) {
        if let uuid = notification.userInfo?[Functionalities.Notification.ReminderUUID] as? String {
            // TODO: change reminders core data into a dictionary of [UUID: Reminder] pair
            for rmd in self.reminders {
                if rmd.uuid == uuid {
                    self.doneReminder(rmd)
                }
            }
        }
    }
    
    private func notifyReminderBug(notification: NSNotification) {
        if let uuid = notification.userInfo?[Functionalities.Notification.ReminderUUID] as? String {
            for rmd in self.reminders {
                if rmd.uuid == uuid {
                    
                    if rmd.isBugged {
                    
                        // Create bugging notification
                        print("Creating bug notif.")
                        createLocalNotification(rmd, isForBugging: true)
                    } else {
                        
                        // Delete bugging notification
                        deleteLocalNotificationForReminder(uuid, isForBugging: true)
                    }
                }
            }
        }
    }
    
    private func notifyReminderPostpone(notification: NSNotification) {
        if let uuid = notification.userInfo?[Functionalities.Notification.ReminderUUID] as? String {
            for rmd in self.reminders {
                if rmd.uuid == uuid {
                    postponeReminder(rmd, byTimeInterval:1 * Functionalities.Time.Hour)
                }
            }
        }
    }
    
    private func notifyReminderDelete(notification: NSNotification) {
        if let uuid = notification.userInfo?[Functionalities.Notification.ReminderUUID] as? String {
            for rmd in self.reminders {
                if rmd.uuid == uuid {
                    deleteReminder(rmd)
                }
            }
        }
    }
    
    private func notifyAppResigningActive(notification: NSNotification) {
        var dueRmdCount = 0
        for rmd in self.reminders {
            if rmd.dueDate?.timeIntervalSinceNow <= 0 {
                dueRmdCount += 1
            } else {
                break
            }
        }
        application.applicationIconBadgeNumber = dueRmdCount
    }
}

// Other useful codes

/*
Edit button
self.navigationItem.leftBarButtonItem = self.editButtonItem()
*/

/*
Plus sign button
let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
self.navigationItem.rightBarButtonItem = addButton
*/

/*
Creating an alert
let alert = UIAlertController(title: fetchResults[0].name, message: fetchResults[0].name, preferredStyle: .Alert)

self.presentViewController(alert, animated: true, completion: nil)
*/

/*
Array sorting comparison 
array.sorted({(left: TodoItem, right:TodoItem) -> Bool in
(left.deadline.compare(right.deadline) == .OrderedAscending)
*/

/*
Array of Array mapping to Array of Object // TodoItem in this case
items.map({
           TodoItem(deadline: $0["deadline"] as! NSDate,
                       title: $0["title"] as! String,
                        UUID: $0["UUID"] as! String!)
          })
*/

/*
func insertionRowForRmd(thisRmd: Reminder) -> Int {
    var i = 0
    for otherRmd in reminders {
        if otherRmd.dueDate?.timeIntervalSince1970 < thisRmd.dueDate?.timeIntervalSince1970 {
            i++
        } else {
            break
        }
    }
    return i;
}
*/

// Old Swift 1.0 code

/*
Set up display in viewDidLoad
self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
if let split = self.splitViewController {
    let controllers = split.viewControllers
    self.detailViewController = controllers[controllers.count-1].topViewController as? ReminderViewController 
}
*/
