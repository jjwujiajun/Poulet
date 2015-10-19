//
//  Reminder.swift
//  Poulet
//
//  Created by Jiajun Wu on 6/18/15.
//  Copyright (c) 2015 Jiajun Wu. All rights reserved.
//

import Foundation
import CoreData

class Reminder: NSManagedObject {
    
    @NSManaged var name: String?
    @NSManaged var dueDate: NSDate?
    @NSManaged var isDone: NSNumber?
    @NSManaged var isRecurring: NSNumber?
    @NSManaged var nextRecurringDate: NSDate?
    @NSManaged var recurrenceCycleQty: NSNumber?
    @NSManaged var recurrenceCycleUnit: NSNumber?
    @NSManaged var uuid: NSString?
    
    var oldDueDate: NSDate?
    
    func updateRecurrenceForPickerIndexes(quantityIndex:Int, unitIndex:Int) {
        recurrenceCycleQty = quantityIndex
        recurrenceCycleUnit = unitIndex
        
        updateNextRecurringDueDate()
    }
    
    func updateNextRecurringDueDate() {
        let quantity = Double(recurrenceCycleQty ?? 0)
        let unit = Functionalities.Time.unitsArray[Int(recurrenceCycleUnit ?? 0)]
        
        let timeToNextDueDate = quantity * unit
        if timeToNextDueDate > 0 {
            if dueDate?.timeIntervalSinceNow < -1 && dueDate?.timeIntervalSinceNow < -timeToNextDueDate {
                nextRecurringDate = NSDate().dateByAddingTimeInterval(timeToNextDueDate)
            } else {
                nextRecurringDate = dueDate?.dateByAddingTimeInterval(timeToNextDueDate)
            }
            print("due date: \(dueDate) next recur date: \(nextRecurringDate)")
            isRecurring = true
        } else {
            isRecurring = false
        }
    }
    
}