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
    var isRecurring = false
    var nextRecurringDate = NSDate()
    var recurrenceCycleQty = 0
    var recurrenceCycleUnit = 0
    
    func updateRecurrenceForPickerIndexes(quantityIndex:Int, unitIndex:Int) {
        let quantity = Double(quantityIndex)
        let unit = Functionalities.Time.unitsArray[unitIndex]
        
        recurrenceCycleQty = quantityIndex
        recurrenceCycleUnit = unitIndex
        
        let timeToNextDueDate = quantity * unit
        if timeToNextDueDate > 0 {
            nextRecurringDate = NSDate(timeInterval: timeToNextDueDate, sinceDate: dueDate)
            isRecurring = true
        } else {
            isRecurring = false
        }
    }
    
}