//
//  GraphEditor.swift
//  smalljump
//
//  Created by cjc on 11/6/20.
//

import SwiftUI
import AVFoundation
import CoreData


// NOTE: had to split single-graph view into parent (GraphEditor)
// and child (GraphEditorChild) because child relies on nodeCount,
// since it cannot access `nodes` in its own `init`.
struct GraphEditorChild: View {
    @Environment(\.managedObjectContext) var moc
    
    // particular node to which we are adding/removing connections
    @State public var connectingNode: Int? = nil // not persisted
    
    @State private var nodeCount: Int
    
    let graphId: Int
    
    var nodesFetchRequest: FetchRequest<Node>
    var nodes: FetchedResults<Node> { nodesFetchRequest.wrappedValue }
    
    var connectionsFetchRequest: FetchRequest<Connection>
    var connections: FetchedResults<Connection> { connectionsFetchRequest.wrappedValue }
    
    init(graphId: Int, nodeCount: Int) {
        self._nodeCount = State.init(initialValue: nodeCount)
        self.graphId = graphId
        
        nodesFetchRequest = FetchRequest<Node>(
            entity: Node.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Node.nodeNumber, ascending: true)],
            predicate: NSPredicate(format: "graphId = %i", graphId))
        
        connectionsFetchRequest = FetchRequest<Connection>(
            entity: Connection.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "graphId = %i", graphId))
    }
    
    var body: some View {
        VStack { // HACK: bottom right corner alignment
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    return ForEach(nodes, id: \.self) { (node: Node) in
                        Ball(nodeCount: $nodeCount,
                             connectingNode: $connectingNode,
                             node: node,
                             graphId: graphId)
                    }.padding(.trailing, 30).padding(.bottom, 30)
                    
                }
            }
        }
        .backgroundPreferenceValue(BallPreferenceKey.self) { (preferences: [BallPreferenceData]) in
            if connections.count >= 1 && nodeCount >= 2 {
                GeometryReader { (geometry: GeometryProxy) in
                    ForEach(connections, content: { (connection: Connection) in
                        // -1 to convert from 1-based count to 0-based index
                        let toPref: BallPreferenceData = preferences[Int(connection.to) - 1]
                        let fromPref: BallPreferenceData = preferences[Int(connection.from) - 1]
                        line(from: geometry[toPref.center], to: geometry[fromPref.center])
                    })
                    
                }
            }
        }
    }
}

// Given a graphId, fetch the nodeCount for that graph
struct GraphEditor: View {
    @Environment(\.managedObjectContext) var moc
    
    var nodesFetchRequest: FetchRequest<Node>
    var nodes: FetchedResults<Node> { nodesFetchRequest.wrappedValue }
        
    let graphId: Int
    
    init(graphId: Int) {
        nodesFetchRequest = FetchRequest<Node>(
            entity: Node.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Node.nodeNumber, ascending: true)],
            predicate: NSPredicate(format: "graphId = %i", graphId))
        
        self.graphId = graphId
    }
    var body: some View {
        return GraphEditorChild(graphId: graphId, nodeCount: nodes.count)
    }
}
