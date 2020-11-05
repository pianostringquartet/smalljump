//
//  Node+CoreDataProperties.swift
//  smalljump
//
//  Created by cjc on 11/5/20.
//
//

import Foundation
import CoreData


extension Node {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Node> {
        return NSFetchRequest<Node>(entityName: "Node")
    }

    @NSManaged public var isAnchored: Bool
    @NSManaged public var positionX: Float
    @NSManaged public var nodeNumber: Int64
    @NSManaged public var positionY: Float
    @NSManaged public var info: UUID?
    @NSManaged public var radius: Int64
    @NSManaged public var graph: Graph?

}

extension Node : Identifiable {

}
