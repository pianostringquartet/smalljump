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
 UI ELEMENTS: draggable balls, drawn edges etc.
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

struct Ball: View {
    @Environment(\.managedObjectContext) var moc
    
    @Binding private var nodeCount: Int
    @Binding private var connectingNode: Int? // not persisted
    
    // node info
    @State private var info: UUID = UUID()
    @State private var showPopover: Bool = false // not persisted
    
    private var node: Node
    
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    let graphId: Int
    
    private var connectionsFetchRequest: FetchRequest<Connection>
    private var connections: FetchedResults<Connection> { connectionsFetchRequest.wrappedValue }
    
    // minimum distance for plus-sign to be dragged to become committed as a node
    let minDistance: CGFloat = CGFloat(90)
    
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
        if connectingNode != nil && connectingNode! == node.nodeNumber {
            return Color.pink
        }
        else if !node.isAnchored {
            return Color.blue
        }
        else {
            return localPosition == CGSize.zero ?
                Color.white.opacity(0) :
                Color.blue.opacity(0 + Double((abs(localPosition.height) + abs(localPosition.width)) / 99))
        }
    }
    
    private func movedEnough(width: CGFloat, height: CGFloat) -> Bool {
        return abs(width) > minDistance || abs(height) > minDistance
    }
    
    var body: some View {
        Circle().stroke(Color.black)
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                VStack (spacing: 20) {
                    Text("Node Number: \(node.nodeNumber)")
                    Text("Node ID: \(info)")
                }
                .padding()
            }
            .background(Image(systemName: "plus"))
            .overlay(LinearGradient(gradient: Gradient(colors: [
                                                        // white of opacity 0 means: 'invisible'
                                                        localPosition == CGSize.zero ? Color.white.opacity(0) : Color.white,
                                                        localPosition == CGSize.zero ? Color.white.opacity(0) : determineColor()]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
            ))
            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
            .overlay(Text(movedEnough(width: localPosition.width, height: localPosition.height) ? "\(node.nodeNumber)": ""))
            .frame(width: CGFloat(node.radius), height: CGFloat(node.radius))
            // Child stores its center in anchor preference data,
            // for parent to later access.
            // NOTE: must come before .offset modifier
            .anchorPreference(key: BallPreferenceKey.self,
                              value: .center, // center for Anchor<CGPoint>
                              transform: {
                                [BallPreferenceData(viewIdx: Int(node.nodeNumber), center: $0)] })
            .offset(x: localPosition.width, y: localPosition.height)
            .gesture(DragGesture()
                        .onChanged {
                            self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                        }
                        .onEnded { (value: DragGesture.Value) in
                            if node.isAnchored {
                                if movedEnough(width: value.translation.width, height: value.translation.height) {
                                    node.isAnchored = false
                                    self.localPreviousPosition = self.localPosition
                                    
                                    let node: Node = Node(context: self.moc)
                                    mutateNewNode(node: node,
                                                  nodeNumber: nodeCount + 1,
                                                  graphId: graphId)
                                    try? self.moc.save()
                                    
                                    self.nodeCount += 1
                                    playSound(sound: "positive_ping", type: "mp3")
                                }
                                else {
                                    withAnimation(.spring()) { self.localPosition = CGSize.zero }
                                }
                            }
                            else {
                                self.localPreviousPosition = self.localPosition
                            }
                            
                            node.positionX = Float(localPosition.width)
                            node.positionY = Float(localPosition.height)
                            
                            try? moc.save()
                        })
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
            .onTapGesture(count: 2, perform: {
                if !node.isAnchored {
                    self.showPopover.toggle()
                }
            })
            .onTapGesture(count: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/, perform: {
                if !node.isAnchored {
                    let existsConnectingNode: Bool = connectingNode != nil
                    let isConnectingNode: Bool = existsConnectingNode && connectingNode != nil && connectingNode! == node.nodeNumber
                    
                    // Note: if no existing connecting node, make this node the connecting node
                    // ie user is attempting to create or remove a node
                    if !existsConnectingNode {
                        self.connectingNode = Int(node.nodeNumber)
                    }
                    else { // ie there is an connecting node:
                        let edgeAlreadyExists: Bool = !connections.filter { (conn: Connection) -> Bool in
                            conn.graphId == Int32(graphId) &&
                                (conn.to == node.nodeNumber && conn.from == Int32(connectingNode!)
                                    || conn.from == node.nodeNumber && conn.to == Int32(connectingNode!))
                        }.isEmpty
                        
                        if isConnectingNode {
                            self.connectingNode = nil
                        }
                        // if existing connecting node and I am NOT the connecting node AND there already exists a connxn(connecting node, me),
                        // remove the connection and set connecting node=nil
                        else if !isConnectingNode && edgeAlreadyExists {
                            
                            // Retrieve the existing connection and delete it
                            let fetchRequest : NSFetchRequest<Connection> = Connection.fetchRequest()
                            fetchRequest.predicate = NSPredicate(format: "graphId = %i AND (from = %i AND to = %i) OR (to = %i AND from = %i)",
                                                                 graphId, connectingNode!, node.nodeNumber, connectingNode!, node.nodeNumber)
                            let fetchedResults = try? moc.fetch(fetchRequest) as! [Connection]
                            if let aConnection = fetchedResults?.first {
                                moc.delete(aConnection)
                                try? moc.save()
                            }
                            
                            self.connectingNode = nil
                            playSound(sound: "connection_removed", type: "mp3")
                        }
                        // if existing connecting node and I am NOT the connecting node AND there DOES NOT exist a connxn(connecting node, me),
                        // add the connection and set connecting node=nil
                        else if !isConnectingNode && !edgeAlreadyExists {
                            
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

struct GraphDisplay: View {
    @Environment(\.managedObjectContext) var moc
    
    var nodesFetchRequest: FetchRequest<Node>
    var nodes: FetchedResults<Node> { nodesFetchRequest.wrappedValue }
    
    var connectionsFetchRequest: FetchRequest<Connection>
    var connections: FetchedResults<Connection> { connectionsFetchRequest.wrappedValue }
    
    let graphId: Int
    
    init(graphId: Int) {
        nodesFetchRequest = FetchRequest<Node>(
            entity: Node.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Node.nodeNumber, ascending: true)],
            predicate: NSPredicate(format: "graphId = %@", NSNumber(value: graphId)))
        
        connectionsFetchRequest = FetchRequest<Connection>(
            entity: Connection.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "graphId = %@", NSNumber(value: graphId)))
        
        self.graphId = graphId
    }
    var body: some View {
        return GraphView(graphId: graphId, nodeCount: nodes.count)
    }
}


/* ----------------------------------------------------------------
 PREVIEW
 ---------------------------------------------------------------- */


struct GraphSelectionView: View {
    @Environment(\.managedObjectContext) var moc
    
    @State private var graphCount: Int // = 0
    
    // not really used in this high level
    //    @FetchRequest(entity: Node.entity(),
    //                  sortDescriptors: [NSSortDescriptor(keyPath: \Node.nodeNumber, ascending: true)])
    //    var nodes: FetchedResults<Node>
    
    //    @FetchRequest(entity: Graph.entity(),
    //                  sortDescriptors: [NSSortDescriptor(keyPath: \Graph.graphId, ascending: true)])
    var graphs: FetchedResults<Graph>
    
    // TODO: Find a better approach to route to 'new screen'
    @State private var action: Int? = 0
    
    init(graphs: FetchedResults<Graph>) {
        self._graphCount = State.init(initialValue: graphs.count)
        self.graphs = graphs
    }
    
    var body: some View {
        NavigationView { // TODO: Look further into proper behavior for Nav on iPhone vs. iPad
            Text("Demo: add some simple user settings here?")
                .navigationBarTitle(Text("Settings"), displayMode: .inline)
            
            VStack(spacing: 30) {
                List {
                    // DEBUG: Doesn't work if placed outside List
                    // DEBUG: Why must we use the $action mutation here? (graphCount mutation not enough)
                    NavigationLink(destination: GraphDisplay(graphId: graphCount), tag: 1, selection: $action)
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
                        NavigationLink(destination: GraphDisplay(graphId: Int(graph.graphId))
                        ) {
                            Text("Go to Graph \(graph.graphId)")
                        }
                    }
                }
            }
        }
    }
}

/* ----------------------------------------------------------------
 CONTENT VIEW
 ---------------------------------------------------------------- */

struct ContentView: View { // MUST BE CALLED CONTENT VIEW
    @Environment(\.managedObjectContext) var moc
    
    @FetchRequest(entity: Graph.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Graph.graphId, ascending: true)])
    var graphs: FetchedResults<Graph>
    
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
    node.radius = 50
}
