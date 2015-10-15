//
//  List.swift
//  Poulet
//
//  Created by Jiajun Wu on 10/14/15.
//  Copyright © 2015 Jiajun Wu. All rights reserved.
//

import Foundation

class List {
    class var sharedInstance : List {
        struct Static {
            static let instance : List = List()
        }
        return Static.instance
    }
    var dueRmdCount: Int = 0
}