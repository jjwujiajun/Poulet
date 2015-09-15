//
//  MasterViewController.swift
//  Poulet
//
//  Created by Jiajun Wu on 6/14/15.
//  Copyright (c) 2015 Jiajun Wu. All rights reserved.
//

import UIKit

class ListViewController: UITableViewController {

    var detailViewController: ReminderViewController? = nil
    
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
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
        
        // Self's detailVC is ReminderVC
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1].topViewController as? ReminderViewController
        }
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        
        notificationCenter.addObserverForName(Functionalities.Notification.ReminderDone, object: nil, queue: queue) { notification in
            if let row = notification?.userInfo?[Functionalities.Notification.CellRow] as? Int {
                let indexPath = NSIndexPath(forRow: row, inSection: 0)
                self.doneReminderAtRow(row)
            }
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
            if otherRmd.dueDate.timeIntervalSince1970 < thisRmd.dueDate.timeIntervalSince1970 {
                i++
            } else {
                break
            }
        }
        return i;
    }
    
    func insertNewReminder(reminder: Reminder, withStyle style: UITableViewRowAnimation, atIndex index:Int) {
        reminders.insert(reminder, atIndex: index)
        
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: style)
    }
    
    func insertNewReminder(reminder: Reminder, withStyle style: UITableViewRowAnimation) {
        let insertIndex = insertionRowForRmd(reminder)
        insertNewReminder(reminder, withStyle: style, atIndex: insertIndex)
    }
    
    func deleteReminderAtRow(row: Int, withStyle style: UITableViewRowAnimation) {
        reminders.removeAtIndex(row)
        tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: 0)], withRowAnimation: style)
    }
    
    func doneReminderAtRow(row: Int) {
        let rmd = reminders[row]
        if rmd.isRecurring {
            
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
            if let indexPath = self.tableView.indexPathForSelectedRow() {
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
            reminders.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
}

