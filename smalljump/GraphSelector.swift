//
//  GraphSelector.swift
//  smalljump
//
//  Created by cjc on 11/6/20.
//

import SwiftUI
import AVFoundation
import CoreData


struct GraphSelector: View {
    @Environment(\.managedObjectContext) var moc
    
    @State private var graphCount: Int
    
    @FetchRequest(entity: Graph.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Graph.graphId, ascending: true)])
    var graphs: FetchedResults<Graph>
    
    // TODO: Find a better approach to route to 'new screen'
    @State private var action: Int? = 0
    
    init(graphCount: Int) {
        self._graphCount = State.init(initialValue: graphCount)
    }
    
    var body: some View {
        NavigationView { 
            VStack(spacing: 30) {
                List {
                    // DEBUG: Doesn't have 'Back' nav-button if placed outside List
                    // DEBUG: Why must we use the $action mutation here? (graphCount mutation not enough...)
                    NavigationLink(destination: GraphEditor(graphId: graphCount), tag: 1, selection: $action)
                    {
                        Text("Create new graph").onTapGesture {
                            self.graphCount += 1
                            
                            // Create first node for new graph
                            let node = Node(context: self.moc)
                            mutateNewNode(node: node,
                                          nodeNumber: 1,
                                          graphId: graphCount)
                            
                            // Create graph itself
                            let graph = Graph(context: self.moc)
                            graph.id = UUID()
                            graph.graphId = Int32(graphCount)
                            
                            try? moc.save()
                            
                            // BUG?: sometimes CoreData mutation is not finished
                            // before we call this and go to graph-edit screen?
                            self.action = 1
                        }
                    }
                    ForEach(graphs, id: \.id) { (graph: Graph) in
                        NavigationLink(destination: GraphEditor(graphId: Int(graph.graphId))
                        ) {
                            Text("Graph \(graph.graphId)")
                        }
                    }
                }
            }.navigationBarTitle(Text("Graphs"), displayMode: .inline)
        } // NavigationView
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// i.e. create a new 'anchor/plus ball';
// must receive a node already created via `Node(context: self.moc)`
// and must be followed by `try? self.moc.save()`
// Apparently can't pass around the NSManagedObjectContext to a pure function?
func mutateNewNode(node: Node, nodeNumber: Int, graphId: Int) -> () {
    node.info = UUID()
    node.isAnchored = true // because 'anchor ball'
    node.nodeNumber = Int32(nodeNumber)
    node.graphId = Int32(graphId)
    node.positionX = Float(0)
    node.positionY = Float(0)
    node.radius = 50
}
