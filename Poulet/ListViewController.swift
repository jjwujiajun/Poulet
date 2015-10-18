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
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    private var reminders = [Reminder]()
    
    // viewDidAppear animations
    var newReminder: Reminder?
    // How animation will work when reminder is newly added
    // fetchSortedReminders() in viewWillAppear
    // saveReminders() in viewWillAppear, not in viewDidAppear bc list could change when user completed reminder from notification
    // newlyAddedReminder pointer is nil-ed after viewDidAppear
    
    var editedReminder: Reminder?

    @IBAction func addReminder(sender: UIBarButtonItem) {
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().scheduledLocalNotifications?.removeAll()
        print(UIApplication.sharedApplication().scheduledLocalNotifications?.count)
        
        //NSFetchedResultsController for notifying tbableview when dataachanges, instead of refreshing table every "n" seconds
        
        // Fetch data
        fetchSortedReminders()
        
        // Set up notification center
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        
        notificationCenter.addObserverForName(Functionalities.Notification.ReminderDone, object: nil, queue: queue) { notification in
            if let indexPath = notification.userInfo?[Functionalities.Notification.CellIndexPath] as? NSIndexPath {
                self.doneReminder(self.reminders[indexPath.row])
            }
            
        }
        
        notificationCenter.addObserverForName(Functionalities.Notification.ScheduledNotificationDue, object: nil, queue: queue) { notification in
            print("ListVC received notification")
            if let userInfo = notification.userInfo {
                print(userInfo["uuid"])
                // Badge icon
                List.sharedInstance.dueRmdCount += 1
                UIApplication.sharedApplication().applicationIconBadgeNumber = List.sharedInstance.dueRmdCount
            }
        }
        
        // Set up display
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1] as? ReminderViewController // Self's detailVC is ReminderVC
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //TODO: investigate how to reload data when return from homescreen
        //tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        print("vda")
        if newReminder != nil { // If view appeared after AddRmdVC created new rmd
            fetchSortedReminders()
            saveReminders()
            createLocalNotification(newReminder!)
            animateInsertRmdIntoList(newReminder!)
            
            newReminder = nil
        }
        
        if editedReminder != nil {
            editReminder(editedReminder!)
            editedReminder = nil
        }
    }
    
    func animateInsertRmdIntoList(reminder: Reminder) {
        if let row = reminders.indexOf(reminder) { // will not work if did not call fetchSortedReminders()
            let insertIndex = NSIndexPath(forRow: row, inSection: 0)
            
            tableView.insertRowsAtIndexPaths([insertIndex], withRowAnimation: .Right)
        }
    }
    
    private func insertNewReminder(reminder: Reminder) {
        // New data is brought in from AddReminderVC. Update Data Model
        fetchSortedReminders()
        saveReminders()
        
        let thisFuncIsPartOfShiftingProcess = reminder.oldDueDate != nil
        if !thisFuncIsPartOfShiftingProcess {
            createLocalNotification(reminder)
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
                shiftReminder(reminder, toPositionForDate: reminder.dueDate!) // handlesNotification changes
                reminder.oldDueDate = nil
            } else {
                fetchSortedReminders()
                saveReminders()
                tableView.reloadData()
                if reminder.oldDueDate != reminder.dueDate {
                    deleteLocalNotificationForReminder(reminder.uuid as String?)
                    fillEmptySlotInNotificationQueue()
                }
            }
        }
        //TODO: highlight row when return
    }
    
    private func deleteReminder(rmd: Reminder) {
        var path: NSIndexPath?
        if let row = reminders.indexOf(rmd) {
            path = NSIndexPath(forRow: row, inSection: 0)
        }
        let thisFuncIsPartOfShiftingProcess = rmd.oldDueDate != nil
         
        let uuid = rmd.uuid as String?
        
        managedObjectContext.deleteObject(rmd) // Non-core data implementation: reminders.removeAtIndex(row)
        fetchSortedReminders()
        saveReminders()
        
        if path != nil {
            if thisFuncIsPartOfShiftingProcess {
                tableView.deleteRowsAtIndexPaths([path!], withRowAnimation: .Right)
            } else {
                tableView.deleteRowsAtIndexPaths([path!], withRowAnimation: .Fade)
                deleteLocalNotificationForReminder(uuid)
                fillEmptySlotInNotificationQueue()
            }
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
            }

        } else {
            // TODO : Create a archive list to save all done reminders before deleting over here
            deleteReminder(rmd)
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
            
            deleteLocalNotificationForReminder(uuid as String?)
            fillEmptySlotInNotificationQueue()
            
            return reminder
        }
        return nil
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showReminder" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! ReminderViewController
                controller.reminder = reminders[indexPath.row]
                controller.listViewController = self
                controller.reminderIndexPathInListView = indexPath
                
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

        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            deleteReminder(reminders[indexPath.row])
            // Non-core data execution          reminders.removeAtIndex(indexPath.row)
            
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
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
    
    // MARK: – Core Data
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
    
    // Local Notifications
    func createLocalNotification(reminder: Reminder) {
        let scheduledLocalNotifications = UIApplication.sharedApplication().scheduledLocalNotifications
        if let count = scheduledLocalNotifications?.count {
            
            if count < Functionalities.Notification.ScheduleLimit {
            
                // Create a corresponding local notification
                let notification = UILocalNotification()
                notification.alertBody = reminder.name
                notification.fireDate = reminder.dueDate
                notification.soundName = UILocalNotificationDefaultSoundName
                notification.userInfo = ["uuid": reminder.uuid! as String] // assign a unique identifier to the notification so that we can retrieve it later
                
                notification.alertAction = "Open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
                notification.category = "TODO_CATEGORY"
                
                // if reminder is < 64th, schedule. Update when old ones are completed
                UIApplication.sharedApplication().scheduleLocalNotification(notification)
                print("created notif: " + notification.alertBody!)
                
            } else if let lastScheduledRmdNotif = scheduledLocalNotifications?[count - 1] {
                if let lastScheduledRmdUserInfo = lastScheduledRmdNotif.userInfo {
                    for rmd in reminders {
                        if lastScheduledRmdUserInfo["uuid"] as! String == rmd.uuid {
                            let scheduledRmd = rmd
                            if let lastScheduledRmdDueDate = scheduledRmd.dueDate {
                                
                                if reminder.dueDate?.timeIntervalSinceDate(lastScheduledRmdDueDate) < 0 {
                                    
                                    deleteLocalNotificationForReminder(rmd.uuid as String?)
                                    createLocalNotification(reminder)
                                }
                                break
                            }
                        }
                    }
                }
            }
        }
    }
    
    func deleteLocalNotificationForReminder(UUID: String?) {
        if UUID != nil {
            if let scheduledNotifications = UIApplication.sharedApplication().scheduledLocalNotifications {
                for notification in scheduledNotifications {
                    if let userInfo = notification.userInfo {
                        if userInfo["uuid"] as? String == UUID {
                            UIApplication.sharedApplication().cancelLocalNotification(notification)
                            print("cancelled notif: " + notification.alertBody!)
                            
                            break
                        }
                    }
                }
            }
        }
    }
    
    func fillEmptySlotInNotificationQueue() {
        if reminders.count >= Functionalities.Notification.ScheduleLimit {
            // TODO: shift [reminder] into class List. instead of having var reminders
            
            // find 64th non-dued in line to be scheduled
            var i = 0
            for rmd in reminders {
                if rmd.dueDate?.timeIntervalSinceNow > 0 {
                    
                    i++;
                    if i == Functionalities.Notification.ScheduleLimit {
                        print("Fill slot with " + rmd.name! + " by: ")
                        createLocalNotification(rmd)
                        break
                    }
                }
            }
        }
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
