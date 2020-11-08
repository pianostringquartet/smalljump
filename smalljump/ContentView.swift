//
//  ContentView.swift
//  smalljump
//
//  Created by cjc on 10/31/20.
//

import SwiftUI
import AVFoundation
import CoreData

/* ----------------------------------------------------------------
 UTILS
 ---------------------------------------------------------------- */

// For debug printing from simulator
func log(_ log: String) -> EmptyView {
    print("** \(log)")
    return EmptyView()
}

var audioPlayer: AVAudioPlayer?

func playSound(sound: String, type: String) {
    if let path = Bundle.main.path(forResource: sound, ofType: type) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.play()
        } catch {
            log("Unable to play sound.")
        }
    }
}


/* ----------------------------------------------------------------
 PREFERENCE DATA: passing data up from children to parent view
 ---------------------------------------------------------------- */

// Datatype for preference data
struct BallPreferenceData: Identifiable {
    let id = UUID()
    let viewIdx: Int
    let center: Anchor<CGPoint>
}

// Preference key for preference data
struct BallPreferenceKey: PreferenceKey {
    typealias Value = [BallPreferenceData]
    
    static var defaultValue: [BallPreferenceData] = []
    
    static func reduce(value: inout [BallPreferenceData], nextValue: () -> [BallPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}


/* ----------------------------------------------------------------
 DOMAIN TYPES: representations of domain concepts
 ---------------------------------------------------------------- */

//struct Connection: Identifiable, Equatable {
//    let id: UUID = UUID()
//    let from: Int
//    let to: Int
//
//    static func ==(lhs: Connection, rhs: Connection) -> Bool {
//        // Edgeless connection:
//        return lhs.from == rhs.from && lhs.to == rhs.to || lhs.from == rhs.to && lhs.to == rhs.from
//    }
//}


/* ----------------------------------------------------------------
 UI ELEMENTS: draggable balls, etc.
 ---------------------------------------------------------------- */

struct Line: Shape {
    let from, to: CGPoint
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: self.from)
            p.addLine(to: self.to)
        }
    }
}

func line(from: CGPoint, to: CGPoint) -> some View {
    Line(from: from, to: to).stroke().animation(.default)
}

// ball's new position = old position + displacement from current drag gesture
func updatePosition(value: DragGesture.Value, position: CGSize) -> CGSize {
    CGSize(width: value.translation.width + position.width,
           height: value.translation.height + position.height)
}



/* ----------------------------------------------------------------
 CONTENT VIEW
 ---------------------------------------------------------------- */


struct CDBall: View {
    @Environment(\.managedObjectContext) var moc
    
    // for now these are still ViewState
    @Binding public var nodeCount: Int
    @Binding public var connectingNode: Int?

    // Node info
    @State private var info: UUID = UUID()
    @State private var showPopover: Bool = false

    
    var node: Node // mutated?

    @State private var localPosition: CGSize // = CGSize.zero
    @State private var localPreviousPosition: CGSize // = CGSize.zero
    
    let graphId: Int
    
    var connectionsFetchRequest: FetchRequest<Connection>
    var connections: FetchedResults<Connection> { connectionsFetchRequest.wrappedValue }
    
    
    init(nodeCount: Binding<Int>,
         connectingNode: Binding<Int?>,
         node: Node,
         graphId: Int
    ) {
        self._nodeCount = nodeCount
        self._connectingNode = connectingNode
        
        connectionsFetchRequest = FetchRequest<Connection>(
            entity: Connection.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "graphId = %@", NSNumber(value: graphId)))
        
        self.node = node
        
        let convertedPosition: CGSize = CGSize(width: CGFloat(node.positionX), height: CGFloat(node.positionY))
        self._localPosition = State.init(initialValue: convertedPosition)
        self._localPreviousPosition = State.init(initialValue: convertedPosition)
        
        self.graphId = graphId
    }

    private func determineColor() -> Color {
//        if connectingNode == nodeNumber {
//        if connectingNode == node.nodeNumber {
        
        // better?: use .map
        if connectingNode != nil && connectingNode! == node.nodeNumber {
            return Color.pink
        }
//        else if !isAnchored {
        else if !node.isAnchored {
            return Color.blue
        }
        else {
//            return position == CGSize.zero ?
                return localPosition == CGSize.zero ?
                    Color.white.opacity(0) :
//                    Color.blue.opacity(0 + Double((abs(position.height) + abs(position.width)) / 99))
                    Color.blue.opacity(0 + Double((abs(localPosition.height) + abs(localPosition.width)) / 99))
        }
    }

    var body: some View {
//        log("CDBall body run")
//        log("localPosition: \(localPosition)")
//        log("localPreviousPosition: \(localPreviousPosition)")
        log("CDBall: connectingNode: \(connectingNode)")
        log("CDBall: nodeCount: \(nodeCount)")
        
        log("CDBall: node: \(node)")
        log("CDBall: connections: \(connections)")
        
        Circle().stroke(Color.black)
//            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
//                VStack (spacing: 20) {
//                    Text("Node Number: \(nodeNumber)")
//                    Text("Node ID: \(info)")
//                }
//                .padding()
//            }
            .background(Image(systemName: "plus"))
            .overlay(LinearGradient(gradient: Gradient(colors: [
                                                        // white of opacity 0 means: 'invisible'
//                                                        position == CGSize.zero ? Color.white.opacity(0) : Color.white,
                                                        localPosition == CGSize.zero ? Color.white.opacity(0)
                                                            : determineColor()]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing
                ))
            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
            
            //added:
            .overlay(Text("\(node.nodeNumber)"))
//            .frame(width: radius, height: radius)
            .frame(width: CGFloat(node.radius), height: CGFloat(node.radius))
            // Child stores its center in anchor preference data,
            // for parent to later access.
            // NOTE: must come before .offset modifier
            .anchorPreference(key: BallPreferenceKey.self,
                              value: .center, // center for Anchor<CGPoint>
                              transform: {
                                [BallPreferenceData(viewIdx: Int(node.nodeNumber), center: $0)] })
//                                [BallPreferenceData(viewIdx: self.nodeNumber, center: $0)] })
//            .offset(x: self.position.width, y: self.position.height)
            .offset(x: localPosition.width, y: localPosition.height)
            .gesture(DragGesture()
                        .onChanged {
//                            self.position = updatePosition(value: $0,
//                                                           position: self.previousPosition)
//                            log("onChanged called")
                            self.localPosition = updatePosition(value: $0,
                                                           position: self.localPreviousPosition)
                            
                            
                        }
                        
                        .onEnded { (value: DragGesture.Value) in
//                            if isAnchored {
//                            log("onEnded called")
                            if node.isAnchored {
//                                log("node is anchored")
                                let minDistance: CGFloat = CGFloat(90)
                                // Did we move the node enough for it to become a free, de-anchored node?
                                let movedEnough: Bool =
                                    abs(value.translation.width) > minDistance ||
                                    abs(value.translation.height) > minDistance
                                if movedEnough {
//                                    log("node moved enough")
//                                    self.isAnchored.toggle()
                                    node.isAnchored = false
                                    
//                                    self.previousPosition = self.position
                                    self.localPreviousPosition = self.localPosition
                                    
//                                    self.nodeCount += 1
                                    playSound(sound: "positive_ping", type: "mp3")
                                    
                                    // now,
//                                    log("DE-ANCHORING: ")
//                                    log("will try to create a node:")
                                    let node: Node = Node(context: self.moc)
                                    mutateNewNode(node: node,
                                               nodeNumber: nodeCount + 1,
                                               graphId: graphId)
                                    try? self.moc.save()
                                    
                                    // do I even need to do this?
                                    // it would be better to just do nodes.count
                                    // wherever I need nodeCount + 1
                                    self.nodeCount += 1
                                }
                                else {
//                                    log("node did not move enough")
                                    withAnimation(.spring())
//                                        { self.position = .zero }
                                        { self.localPosition = CGSize.zero }
                                }
                            }
                            else {
//                                self.previousPosition = self.position
//                                log("node was not anchored")
                                self.localPreviousPosition = self.localPosition
                            }
                            
//                            log("Will try to set node position now")
                            // finally, in any case, we save the position of the ball:
                            node.positionX = Float(localPosition.width)
                            node.positionY = Float(localPosition.height)
//                            log("Will try to save node position now")
                            
                            try? moc.save()
                            
                        })
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
//            .onTapGesture(count: 2, perform: {
//                if !isAnchored {
//                    self.showPopover.toggle()
//                }
//            })
            .onTapGesture(count: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/, perform: {
//                if !isAnchored {
                if !node.isAnchored {
                    let existsConnectingNode: Bool = connectingNode != nil
//                    let isConnectingNode: Bool = existsConnectingNode && connectingNode == nodeNumber
                    let isConnectingNode: Bool = existsConnectingNode && connectingNode != nil && connectingNode! == node.nodeNumber

                    // Note: if no existing connecting node, make this node the connecting node
                    // ie user is attempting to create or remove a node
                    if !existsConnectingNode {
//                        self.connectingNode = self.nodeNumber
                        log("no connecting node; making myself the connector now")
                        self.connectingNode = Int(node.nodeNumber)
                    }
                    else { // ie there is an connecting node:
                        // CORE DATA:
//                        let edge: Connection = Connection(from: connectingNode!, to: self.nodeNumber)
                        
                        log("there exists a connecting node: \(connectingNode!)")
                        
                        // here we just create the Connection -- but don't save it yet...
//                        let edge = Connection(context: self.moc)
//                        edge.id = UUID()
//                        edge.from = Int32(connectingNode!)
//                        edge.to = node.nodeNumber
//                        edge.graphId = Int32(graphId)
                        

                        let edgeAlreadyExists: Bool = !connections.filter { (conn: Connection) -> Bool in
                            conn.graphId == Int32(graphId) &&
                                (conn.to == node.nodeNumber && conn.from == Int32(connectingNode!)
                                    || conn.from == node.nodeNumber && conn.to == Int32(connectingNode!))
                        }.isEmpty
                        
                        
//

                        
                        log("edgeAlreadyExists: \(edgeAlreadyExists)")

                        // if exist connecting node and I am the connecting node, cancel ie set connecting node=nil
                        if isConnectingNode {
                            log("I am the connecting node; turning me off")
                            self.connectingNode = nil
                        }
                        // if existing connecting node and I am NOT the connecting node AND there already exists a connxn(connecting node, me),
                        // remove the connection and set connecting node=nil
                        else if !isConnectingNode && edgeAlreadyExists {
//                            self.connections = connections.filter { $0 != edge }

                            log("will try to delete an existing edge between FROM connectingNode \(connectingNode!) and TO nodeNumber: \(node.nodeNumber)")
                            
                            
                            // Retrieve the existing connection and delete it
                            let fetchRequest : NSFetchRequest<Connection> = Connection.fetchRequest()
                            fetchRequest.predicate = NSPredicate(format: "graphId = %i AND (from = %i AND to = %i) OR (to = %i AND from = %i)", graphId, connectingNode!, node.nodeNumber, connectingNode!, node.nodeNumber)

                            let fetchedResults = try? moc.fetch(fetchRequest) as! [Connection]
                            log("fetchedResults: \(fetchedResults)")
                            log("node.nodeNumber: \(node.nodeNumber)")
                            log("NSInteger(node.nodeNumber): \(NSInteger(node.nodeNumber))")
                            if let aConnection = fetchedResults?.first {
                                log("there was a connection: \(aConnection)")
                                moc.delete(aConnection)
                                log("aConnection.isDeleted: \(aConnection.isDeleted)")
                                try? moc.save()
                                // okay, that worked, that deleted the connection
                            }
                            

                            self.connectingNode = nil
                            playSound(sound: "connection_removed", type: "mp3")
                        }
                        // if existing connecting node and I am NOT the connecting node AND there DOES NOT exist a connxn(connecting node, me),
                        // add the connection and set connecting node=nil
                        else if !isConnectingNode && !edgeAlreadyExists {
                            
//                            self.connections.append(edge)
                            // ie. save the edge we defined earlier
                            log("will try to save the earlier defined edge; ie commit the transactions")
                            
                            // alternatively, only finally create the edge here?
                            let edge = Connection(context: self.moc)
                            edge.id = UUID()
                            edge.from = Int32(connectingNode!)
                            edge.to = node.nodeNumber
                            edge.graphId = Int32(graphId)
    
                            
                            
                            try? moc.save()
                            
                            self.connectingNode = nil
                            playSound(sound: "connection_added", type: "mp3")
                        }
                    }
                }
            })
    }
}


struct GraphView: View {
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
            // should this be?:
            predicate: NSPredicate(format: "graphId = %@", NSNumber(value: graphId)))
        
        connectionsFetchRequest = FetchRequest<Connection>(
            entity: Connection.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "graphId = %@", NSNumber(value: graphId)))
    }
    
    var body: some View {
        VStack { // HACK: bottom right corner alignment
            log("nodeCount in View: \(nodeCount)")
            log("nodes.count: \(nodes.count)")
            
            Spacer()
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    return ForEach(nodes, id: \.self) { (node: Node) in
                        CDBall(
                            nodeCount: $nodeCount,
                            connectingNode: $connectingNode,
                            node: node,
                            graphId: graphId)
                    }.padding(.trailing, 30).padding(.bottom, 30)
                    
                }
            }
        }
        // nothing for now
        .backgroundPreferenceValue(BallPreferenceKey.self) { (preferences: [BallPreferenceData]) in
            if connections.count >= 1 && nodeCount >= 2 {
                log("might draw some lines...")
                GeometryReader { (geometry: GeometryProxy) in
                    ForEach(connections, content: { (connection: Connection) in
                        log("backgroundPreferenceValue: connections: \(connections)")
                        // need to be protected here..
                        
                        // -1 to convert from 1-based count to 0-based index
                        let toPref: BallPreferenceData = preferences[Int(connection.to) - 1]
                        let fromPref: BallPreferenceData = preferences[Int(connection.from) - 1]
                        
                        log("toPref: \(toPref)")
                        log("fromPref: \(fromPref)")
                        
                        line(from: geometry[toPref.center], to: geometry[fromPref.center])
                    })
                    
                }
            }
            
            
//            if connections.count >= 1 && nodeCount >= 2 {
//                GeometryReader { (geometry: GeometryProxy) in
//                    ForEach(connections, content: { (connection: Connection) in
//                        // Note: we must convert the node number to an index position
//                        let toPref: BallPreferenceData = preferences[connection.to - 1]
//                        let fromPref: BallPreferenceData = preferences[connection.from - 1]
//                        line(from: geometry[toPref.center], to: geometry[fromPref.center])
//
//                    })
//                }
//            }
        }
    }
}



// Retrieves nodes and connections just for this specific graph,
// passes them to GraphView
struct GraphDisplay: View {
    @Environment(\.managedObjectContext) var moc
    
    var nodesFetchRequest: FetchRequest<Node>
    var nodes: FetchedResults<Node> { nodesFetchRequest.wrappedValue }
    
    var connectionsFetchRequest: FetchRequest<Connection>
    var connections: FetchedResults<Connection> { connectionsFetchRequest.wrappedValue }
    
    let graphId: Int

    init(graphId: Int) {
        log("inside init: graphId: \(graphId)")
        
        nodesFetchRequest = FetchRequest<Node>(
            entity: Node.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Node.nodeNumber, ascending: true)],
            // should this be?:
            predicate: NSPredicate(format: "graphId = %@", NSNumber(value: graphId)))
        
        connectionsFetchRequest = FetchRequest<Connection>(
            entity: Connection.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "graphId = %@", NSNumber(value: graphId)))
        
        self.graphId = graphId
    }
    var body: some View {
        log("graphId in GraphDisplay: \(graphId)")
        log("nodes in GraphDisplay: \(nodes)")
        log("connections in GraphDisplay: \(connections)")
        return GraphView(graphId: graphId, nodeCount: nodes.count)
    }
}

/* ----------------------------------------------------------------
 PREVIEW
 ---------------------------------------------------------------- */


struct GraphSelectionView: View {
    @Environment(\.managedObjectContext) var moc

    @State public var graphCount: Int // = 0
    
    // not really used in this high level
    @FetchRequest(entity: Node.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Node.nodeNumber, ascending: true)])
    var nodes: FetchedResults<Node>
    
    @FetchRequest(entity: Graph.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Graph.graphId, ascending: true)])
    var graphs: FetchedResults<Graph>
    
    // TODO: Find a better approach
    @State private var action: Int? = 0
    
    init(graphs: FetchedResults<Graph>) {
        log("GraphSelectionView: graphs.count: \(graphs.count)")
        self._graphCount = State.init(initialValue: graphs.count)
    }

    var body: some View {
        NavigationView { // TODO: Look further into proper behavior for Nav on iPhone vs. iPad
            Text("Demo: add some simple user settings here?")
            // this is a view modifier; wherever you attach this, you'll have the
            .navigationBarTitle(Text("Settings"), displayMode: .inline)
        
            VStack(spacing: 30) {
                        List {
                            // DEBUG: Doesn't work if placed outside List
                            // DEBUG: Why must we use the $action mutation here? (graphCount mutation not enough)
                            NavigationLink(destination: GraphDisplay(graphId: graphCount), tag: 1, selection: $action)
                            {
                                Text("Create new graph").onTapGesture {
                                    log("we're gonna make a new graph")
                                    log("graphCount was: \(graphCount)")
                                    self.graphCount += 1
                                    log("graphCount is now: \(graphCount)")
                                    
                                    // Create first node for graph
                                    let node = Node(context: self.moc)
                                    mutateNewNode(node: node,
                                                  nodeNumber: 1,
                                                  graphId: graphCount)
                                    
                                    // Create graph itself
                                    let graph = Graph(context: self.moc)
                                    graph.id = UUID()
                                    graph.graphId = Int32(graphCount)
                                    
                                    try? moc.save()
                                    
                                    log("ContentView: nodes are now: \(nodes)")
                                    log("self.action: \(self.action)")
                                    
                                    // NOTE?: do the CoreData and local state mutate first;
                                    // and only then go to the NavLink view
                                    self.action = 1
                                }
                            }
                            ForEach(graphs, id: \.id) { (graph: Graph) in
                                NavigationLink(destination: GraphDisplay(graphId: Int(graph.graphId))
                                ) {
                                     Text("Go to Graph \(graph.graphId)")
                                }
                            }
                        } // list
            } // vstack
        } // nav view
    }
}


// right now this is basically the graph-selector view
struct ContentView: View { // MUST BE CALLED CONTENT VIEW
    @Environment(\.managedObjectContext) var moc
    
    @FetchRequest(entity: Graph.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Graph.graphId, ascending: true)])
    var graphs: FetchedResults<Graph>
    
    @FetchRequest(entity: Student.entity(),
                  sortDescriptors: [])
    var students: FetchedResults<Student>
    
    @FetchRequest(entity: Connection.entity(),
                  sortDescriptors: [],
                  predicate: NSPredicate(format: "graphId = %i", 1))
    var connections: FetchedResults<Connection>
    
    var nodeNumber: Int32 = 1
    
    var body: some View {
        return GraphSelectionView(graphs: graphs)
        
        
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView() // must be named content view
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)

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
    node.radius = 30
}
