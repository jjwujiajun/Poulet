//
//  Reminder.swift
//  Poulet
//
//  Created by Jiajun Wu on 6/18/15.
//  Copyright (c) 2015 Jiajun Wu. All rights reserved.
//

import Foundation

class Reminder {
    
    var name: String? = ""
    var dueDate = NSDate()
    var isDone = false
    var isRecurring = false
    var nextRecurringDate = NSDate()
    var recurrenceCycleQty = 0
    var recurrenceCycleUnit = 0
    
    func updateRecurrenceForPickerIndexes(quantityIndex:Int, unitIndex:Int) {
        recurrenceCycleQty = quantityIndex
        recurrenceCycleUnit = unitIndex
        
        updateNextRecurringDueDate()
    }
    
    func updateNextRecurringDueDate() {
        let quantity = Double(recurrenceCycleQty)
        let unit = Functionalities.Time.unitsArray[recurrenceCycleUnit]
        
        let timeToNextDueDate = quantity * unit
        if timeToNextDueDate > 0 {
            nextRecurringDate = NSDate(timeInterval: timeToNextDueDate, sinceDate: dueDate)
            isRecurring = true
        } else {
            isRecurring = false
        }
    }
    
}