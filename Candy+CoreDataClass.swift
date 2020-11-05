//
//  Candy+CoreDataClass.swift
//  smalljump
//
//  Created by cjc on 11/5/20.
//
//

import Foundation
import CoreData

@objc(Candy)
public class Candy: NSManagedObject {
    // per: https://www.hackingwithswift.com/books/ios-swiftui/one-to-many-relationships-with-core-data-swiftui-and-fetchrequest
    public var wrappedName: String {
        name ?? "Unknown Candy"
    }
}
