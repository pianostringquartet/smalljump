//
//  Connection+CoreDataProperties.swift
//  smalljump
//
//  Created by cjc on 11/5/20.
//
//

import Foundation
import CoreData


extension Connection {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Connection> {
        return NSFetchRequest<Connection>(entityName: "Connection")
    }

    @NSManaged public var from: Int64
    @NSManaged public var to: Int64
    @NSManaged public var id: UUID?
    @NSManaged public var graph: Graph?

}

extension Connection : Identifiable {

}
