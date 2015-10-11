//
//  MasterViewController.swift
//  Poulet
//
//  Created by Jiajun Wu on 6/14/15.
//  Copyright (c) 2015 Jiajun Wu. All rights reserved.
//

import UIKit
import CoreData

class ListViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: ReminderViewController? = nil
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
        //reminders.append("test")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

//        let reminder = NSEntityDescription.insertNewObjectForEntityForName("Reminder", inManagedObjectContext: managedObjectContext) as! Reminder
//        
//        reminder.name = "testReminder"
        
        // Fetch data
        fetchReminders()
        
        // Set up notification center
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        
        notificationCenter.addObserverForName(Functionalities.Notification.ReminderDone, object: nil, queue: queue) { notification in
            if let row = notification.userInfo?[Functionalities.Notification.CellRow] as? Int {
                self.doneReminderAtRow(row)
            }
        }
        
        // Set up display
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1] /*.topViewController*/ as? ReminderViewController // Self's detailVC is ReminderVC
        }
        
        // Other
        // Edit button
        //self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        // Plus sign button
        //let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        //self.navigationItem.rightBarButtonItem = addButton
    }
    
    func insertionRowForRmd(thisRmd: Reminder) -> Int {
        var i = 0
        for otherRmd in reminders {
            // core data changed this: duedates
            if otherRmd.dueDate!.timeIntervalSince1970 < thisRmd.dueDate!.timeIntervalSince1970 {
                i++
            } else {
                break
            }
        }
        return i;
    }
    
    func insertNewReminder(reminder: Reminder, withStyle style: UITableViewRowAnimation, atIndex index:Int) {
        // Non-core data implementation
        /*
        reminders.insert(reminder, atIndex: index)
        */
        
        // New data is brought in from AddReminderVC. Update Data Model
        fetchReminders() // TODO 1: if let index = find(reminders, reminder) instead of using insertionRowForRmd
        saveReminders()
        
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: style)
    }
    
    func insertNewReminder(reminder: Reminder, withStyle style: UITableViewRowAnimation) {
        // See TODO 1
        let insertIndex = insertionRowForRmd(reminder)
        
        insertNewReminder(reminder, withStyle: style, atIndex: insertIndex)
    }
    
    func deleteReminderAtRow(row: Int, withStyle style: UITableViewRowAnimation) {
        // Non-core data implementation
        /*
        reminders.removeAtIndex(row)
        */
        
        managedObjectContext.deleteObject(reminders[row])
        
        tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: 0)], withRowAnimation: style)
        
        saveReminders()
    }
    
    func doneReminderAtRow(row: Int) {
        let rmd = reminders[row]
        // core date changed this
        if (rmd.isRecurring != nil) {
            
            deleteReminderAtRow(row, withStyle: .Right)
            
            rmd.dueDate = rmd.nextRecurringDate
            rmd.updateNextRecurringDueDate()
            
            let insertIndex = insertionRowForRmd(rmd)
            if insertIndex == row {
                insertNewReminder(rmd, withStyle: .Fade, atIndex: insertIndex)
            } else {
                insertNewReminder(rmd, withStyle: .Right, atIndex: insertIndex)
            }
        } else {
            deleteReminderAtRow(row, withStyle: .Fade)
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
        cell.tableView = self.tableView//indexPath.row

        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Non-core data execution
            /* reminders.removeAtIndex(indexPath.row) */
            
            let reminderToDelete = reminders[indexPath.row]
            managedObjectContext.deleteObject(reminderToDelete)
            
            fetchReminders()
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    // MARK: – Core Data
    func fetchReminders() {
        let fetchRequest = NSFetchRequest(entityName: "Reminder")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            if let fetchResults = try managedObjectContext.executeFetchRequest(fetchRequest) as? [Reminder] {
                reminders = fetchResults
            }
        } catch {
            abort()
        }
    }
    
    func saveReminders() {
        do {
            try managedObjectContext.save()
        } catch {
            print("Cannot save, in ListVC.saveReminders()")
        }
    }
}

/*
Creating an alert
let alert = UIAlertController(title: fetchResults[0].name, message: fetchResults[0].name, preferredStyle: .Alert)

self.presentViewController(alert, animated: true, completion: nil)

*/
