//
//  Country+CoreDataClass.swift
//  smalljump
//
//  Created by cjc on 11/5/20.
//
//

import Foundation
import CoreData

@objc(Country)
public class Country: NSManagedObject {
    
    // per: https://www.hackingwithswift.com/books/ios-swiftui/one-to-many-relationships-with-core-data-swiftui-and-fetchrequest
    public var wrappedShortName: String {
        shortName ?? "Unknown Country"
    }

    public var wrappedFullName: String {
        fullName ?? "Unknown Country"
    }
    
    public var candyArray: [Candy] {
        let set = candy as? Set<Candy> ?? []
        return set.sorted {
            $0.wrappedName < $1.wrappedName
        }
    }
}
