//
//  Graph+CoreDataProperties.swift
//  smalljump
//
//  Created by cjc on 11/5/20.
//
//

import Foundation
import CoreData


extension Graph {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Graph> {
        return NSFetchRequest<Graph>(entityName: "Graph")
    }

    @NSManaged public var nodeCount: Int64
    @NSManaged public var nodes: NSSet?
    @NSManaged public var connections: NSSet?

}

// MARK: Generated accessors for nodes
extension Graph {

    @objc(addNodesObject:)
    @NSManaged public func addToNodes(_ value: Node)

    @objc(removeNodesObject:)
    @NSManaged public func removeFromNodes(_ value: Node)

    @objc(addNodes:)
    @NSManaged public func addToNodes(_ values: NSSet)

    @objc(removeNodes:)
    @NSManaged public func removeFromNodes(_ values: NSSet)

}

// MARK: Generated accessors for connections
extension Graph {

    @objc(addConnectionsObject:)
    @NSManaged public func addToConnections(_ value: Connection)

    @objc(removeConnectionsObject:)
    @NSManaged public func removeFromConnections(_ value: Connection)

    @objc(addConnections:)
    @NSManaged public func addToConnections(_ values: NSSet)

    @objc(removeConnections:)
    @NSManaged public func removeFromConnections(_ values: NSSet)

}

extension Graph : Identifiable {

}
