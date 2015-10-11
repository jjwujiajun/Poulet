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
        
        // Fetch data
        fetchSortedReminders()
        
        // Set up notification center
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        
        notificationCenter.addObserverForName(Functionalities.Notification.ReminderDone, object: nil, queue: queue) { notification in
            if let indexPath = notification.userInfo?[Functionalities.Notification.CellIndexPath] as? NSIndexPath {
                self.doneReminderAtRow(indexPath)
            }
        }
        
        // Set up display
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1] as? ReminderViewController // Self's detailVC is ReminderVC
        }
    }
    
    func insertNewReminder(reminder: Reminder) {
        
        // New data is brought in from AddReminderVC. Update Data Model
        fetchSortedReminders()
        saveReminders()
        
        if let row = reminders.indexOf(reminder) { // will not work if did not call fetchSortedReminders()
            let insertIndex = NSIndexPath(forRow: row, inSection: 0)
            var style = UITableViewRowAnimation.Right
            
            if row == reminder.oldIndexPath?.row {
                style = UITableViewRowAnimation.Fade
            }
            tableView.insertRowsAtIndexPaths([insertIndex], withRowAnimation: style)
        }
    }
    
    private func deleteReminderAtIndexPath(path: NSIndexPath) {
        var style = UITableViewRowAnimation.Fade
        if reminders[path.row].oldIndexPath != nil {
            style = UITableViewRowAnimation.Right
        }
        
        managedObjectContext.deleteObject(reminders[path.row])
        // Non-core data implementation :        reminders.removeAtIndex(row)
        
        fetchSortedReminders()
        saveReminders()
        
        tableView.deleteRowsAtIndexPaths([path], withRowAnimation: style)
    }
    
    private func doneReminderAtRow(indexPath: NSIndexPath) {
        let rmd = reminders[indexPath.row]
        
        rmd.isDone? = NSNumber(bool: true)
        
        if rmd.isRecurring?.boolValue ?? false {
            
            let name = rmd.name
            let isRecurring = rmd.isRecurring
            let recurrenceCycleQty = rmd.recurrenceCycleQty
            let recurrenceCycleUnit = rmd.recurrenceCycleUnit
            let oldIndexPath = rmd.oldIndexPath
            let dueDate = rmd.nextRecurringDate
            
            deleteReminderAtIndexPath(indexPath)
            
            if let reminder = NSEntityDescription.insertNewObjectForEntityForName(Functionalities.Entity.Reminder, inManagedObjectContext: managedObjectContext) as? Reminder{
                
                reminder.name = name
                reminder.isRecurring = isRecurring
                reminder.recurrenceCycleQty = recurrenceCycleQty
                reminder.recurrenceCycleUnit = recurrenceCycleUnit
                reminder.oldIndexPath = oldIndexPath
                reminder.dueDate = dueDate
                reminder.updateNextRecurringDueDate()
                
                insertNewReminder(reminder)
            }
        } else {
            // TODO : Create a archive list to save all done reminders before deleting over here
            deleteReminderAtIndexPath(indexPath)
        }
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
            
            deleteReminderAtIndexPath(indexPath)
            // Non-core data execution          reminders.removeAtIndex(indexPath.row)
            
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
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
