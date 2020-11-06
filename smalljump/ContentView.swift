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

//struct Ball: View {
//    @State private var position = CGSize.zero
//    @State private var previousPosition = CGSize.zero
//
//    @State private var isAnchored: Bool = true // true just iff ball has NEVER 'been moved enough'
//
//    @Binding public var connections: [Connection]
//    @Binding public var nodeCount: Int
//    @Binding public var connectingNode: Int?
//
//    // Node info
//    @State private var info: UUID = UUID()
//    @State private var showPopover: Bool = false
//
//    let nodeNumber: Int
//    let radius: CGFloat
//
//    init(nodeNumber: Int, radius: CGFloat, connections: Binding<[Connection]>, nodeCount: Binding<Int>, connectingNode: Binding<Int?>) {
//        self.nodeNumber = nodeNumber
//        self.radius = radius
//        self._connections = connections
//        self._nodeCount = nodeCount
//        self._connectingNode = connectingNode
//    }
//
//    private func determineColor() -> Color {
//        if connectingNode == nodeNumber {
//            return Color.pink
//        }
//        else if !isAnchored {
//            return Color.blue
//        }
//        else {
//            return
//                position == CGSize.zero ?
//                    Color.white.opacity(0) :
//                    Color.blue.opacity(0 + Double((abs(position.height) + abs(position.width)) / 99))
//        }
//    }
//
//    var body: some View {
//        Circle().stroke(Color.black)
//            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
//                VStack (spacing: 20) {
//                    Text("Node Number: \(nodeNumber)")
//                    Text("Node ID: \(info)")
//                }
//                .padding()
//            }
//            .background(Image(systemName: "plus"))
//            .overlay(LinearGradient(gradient: Gradient(colors: [
//                                                        // white of opacity 0 means: 'invisible'
//                                                        position == CGSize.zero ? Color.white.opacity(0) : Color.white,
//                                                           determineColor()]),
//                               startPoint: .topLeading,
//                               endPoint: .bottomTrailing
//                ))
//            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
//            .frame(width: radius, height: radius)
//            // Child stores its center in anchor preference data,
//            // for parent to later access.
//            // NOTE: must come before .offset modifier
//            .anchorPreference(key: BallPreferenceKey.self,
//                              value: .center, // center for Anchor<CGPoint>
//                              transform: { [BallPreferenceData(viewIdx: self.nodeNumber, center: $0)] })
//            .offset(x: self.position.width, y: self.position.height)
//            .gesture(DragGesture()
//                        .onChanged { self.position = updatePosition(value: $0, position: self.previousPosition) }
//                        .onEnded { (value: DragGesture.Value) in
//                            if isAnchored {
//                                let minDistance: CGFloat = CGFloat(90)
//                                // Did we move the node enough for it to become a free, de-anchored node?
//                                let movedEnough: Bool =
//                                    abs(value.translation.width) > minDistance ||
//                                    abs(value.translation.height) > minDistance
//                                if movedEnough {
//                                    self.isAnchored.toggle()
//                                    self.previousPosition = self.position
//                                    self.nodeCount += 1
//                                    playSound(sound: "positive_ping", type: "mp3")
//                                }
//                                else {
//                                    withAnimation(.spring()) { self.position = .zero }
//                                }
//                            }
//                            else {
//                                self.previousPosition = self.position
//                            }
//                        })
//
//            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
//            .onTapGesture(count: 2, perform: {
//                if !isAnchored {
//                    self.showPopover.toggle()
//                }
//            })
//            .onTapGesture(count: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/, perform: {
//                if !isAnchored {
//                    let existsConnectingNode: Bool = connectingNode != nil
//                    let isConnectingNode: Bool = existsConnectingNode && connectingNode == nodeNumber
//
//                    // Note: if no existing connecting node, make this node the connecting node
//                    // ie user is attempting to create or remove a node
//                    if !existsConnectingNode {
//                        self.connectingNode = self.nodeNumber
//                    }
//                    else { // ie there is an connecting node:
//                        // CORE DATA:
//                        let edge: Connection = Connection(from: connectingNode!, to: self.nodeNumber)
//
//                        let edgeAlreadyExists: Bool = connections.contains(edge)
//
//                        // if exist connecting node and I am the connecting node, cancel ie set connecting node=nil
//                        if isConnectingNode {
//                            self.connectingNode = nil
//                        }
//                        // if existing connecting node and I am NOT the connecting node AND there already exists a connxn(connecting node, me),
//                        // remove the connection and set connecting node=nil
//                        else if !isConnectingNode && edgeAlreadyExists {
//                            // CORE DATA:
//                            self.connections = connections.filter { $0 != edge }
//                            self.connectingNode = nil
//                            playSound(sound: "connection_removed", type: "mp3")
//                        }
//                        // if existing connecting node and I am NOT the connecting node AND there DOES NOT exist a connxn(connecting node, me),
//                        // add the connection and set connecting node=nil
//                        else if !isConnectingNode && !edgeAlreadyExists {
//                            self.connections.append(edge)
//                            self.connectingNode = nil
//                            playSound(sound: "connection_added", type: "mp3")
//                        }
//                    }
//                }
//            })
//    }
//}


/* ----------------------------------------------------------------
 CONTENT VIEW
 ---------------------------------------------------------------- */


// method for saving
//func saveContext() {
//  do {
//    try managedObjectContext.save()
//  } catch {
//    print("Error saving managed object context: \(error)")
//  }
//}

struct CDBall: View {
    @Environment(\.managedObjectContext) var moc
    
    // instead of modifying these,
    // I actually want to mutate the passed in node
//    @State private var position = CGSize.zero
//    @State private var previousPosition = CGSize.zero
    
//
    
//    @State private var isAnchored: Bool = true
    
//    @Binding public var connections: [Connection]
    
    // for now these are still ViewState
    @Binding public var nodeCount: Int
    @Binding public var connectingNode: Int?

    // Node info
//    @State private var info: UUID = UUID()
//    @State private var showPopover: Bool = false

//    let nodeNumber: Int
//    let radius: CGFloat

    // these have to be carefully massaged etc. from the
//    var position: CGSize
//    var previousPosition: CGSize
    
    var node: Node
    
    // alternatively -- mutate these locally onDrag,
    //    // and only save them when onDragEnded
    @State private var localPosition: CGSize // = CGSize.zero
    @State private var localPreviousPosition: CGSize // = CGSize.zero
    
    init(
//        nodeNumber: Int,
//         radius: CGFloat,
////         connections: Binding<[Connection]>,

         nodeCount: Binding<Int>,
         connectingNode: Binding<Int?>,
         node: Node
        
    ) {
//        self.nodeNumber = nodeNumber
//        self.radius = radius
//        self._connections = connections
//        self.node
        self._nodeCount = nodeCount
        self._connectingNode = connectingNode
        
        // convert node positionX,Y to CGSize
        
        self.node = node
        
        let convertedPosition: CGSize = CGSize(width: CGFloat(node.positionX), height: CGFloat(node.positionY))
        //        self.previousPosition = convertedPosition
                
                // alternative: reset these everytime we persist-save,
                // and we only persist-save when we finish onDragEnded;
                // otherwise these are mutated locally during onDrag
        self._localPosition = State.init(initialValue: convertedPosition)
        self._localPreviousPosition = State.init(initialValue: convertedPosition)
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
                                    let node1: Node = Node(context: self.moc)
                                    node1.info = UUID()
                                    node1.isAnchored = true
                //                    node1.nodeNumber = //Int32.random(in: 0 ..< 100) //1
                                    // create it with next node count,
                                    // but don't mutate nodeCount itself until we've successfully saved it in the context
                                    node1.nodeNumber = Int32(nodeCount + 1)

                                    node1.positionX = Float(0)
                                    node1.positionY = Float(0)
                                    node1.radius = 30
                                    do {
//                                        log("will attempt save...")
                                        try self.moc.save()
                                        // if it was successful, then increment the node count
                                        self.nodeCount += 1
                                      } catch {
//                                        log("failed to save")
                                        log("error was: \(error.localizedDescription)")
                                      }
                                    
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
//            .onTapGesture(count: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/, perform: {
//                if !isAnchored {
//                    let existsConnectingNode: Bool = connectingNode != nil
//                    let isConnectingNode: Bool = existsConnectingNode && connectingNode == nodeNumber
//
//                    // Note: if no existing connecting node, make this node the connecting node
//                    // ie user is attempting to create or remove a node
//                    if !existsConnectingNode {
//                        self.connectingNode = self.nodeNumber
//                    }
//                    else { // ie there is an connecting node:
//                        // CORE DATA:
//                        let edge: Connection = Connection(from: connectingNode!, to: self.nodeNumber)
//
//                        let edgeAlreadyExists: Bool = connections.contains(edge)
//
//                        // if exist connecting node and I am the connecting node, cancel ie set connecting node=nil
//                        if isConnectingNode {
//                            self.connectingNode = nil
//                        }
//                        // if existing connecting node and I am NOT the connecting node AND there already exists a connxn(connecting node, me),
//                        // remove the connection and set connecting node=nil
//                        else if !isConnectingNode && edgeAlreadyExists {
//                            // CORE DATA:
//                            self.connections = connections.filter { $0 != edge }
//                            self.connectingNode = nil
//                            playSound(sound: "connection_removed", type: "mp3")
//                        }
//                        // if existing connecting node and I am NOT the connecting node AND there DOES NOT exist a connxn(connecting node, me),
//                        // add the connection and set connecting node=nil
//                        else if !isConnectingNode && !edgeAlreadyExists {
//                            self.connections.append(edge)
//                            self.connectingNode = nil
//                            playSound(sound: "connection_added", type: "mp3")
//                        }
//                    }
//                }
//            })
    }
}





struct GraphView: View {
    // must come first
    @Environment(\.managedObjectContext) var moc

    // Okay to be local for now, but in feature will need to be feature of
    @State private var nodeCount: Int // = 1 // start with one node

    // all existings edges
//    @State public var connections: [Connection] = []

    // WILL NOT BE PERSISTED:
    // particular node to which we are adding/removing connections
    @State public var connectingNode: Int? = nil

//    @FetchRequest(entity: Node.entity(),
//                  // i.e. want to retrieve them in a consistent order, just like when they were created
//                  // could also do this sorting outside or elsewhere?
//                  sortDescriptors: [NSSortDescriptor(keyPath: \Node.nodeNumber, ascending: true)])
    var nodes: FetchedResults<Node>
    
    @FetchRequest(entity: Connection.entity(),
                  sortDescriptors: [])
    var connections: FetchedResults<Connection>
    
    init(nodes: FetchedResults<Node>
//         connections: FetchedResults<Connection>
    ) {
        self._nodeCount = State.init(initialValue: nodes.count)
        self.nodes = nodes
//        self.connections = connections
        
    }

    // also causes undefined behavior
//    func updatedNodes(loveNodes: [Node]) -> [Node] {
//        let node1: Node = Node(context: moc)
//        node1.info = UUID()
//        node1.isAnchored = true
////                    node1.nodeNumber = //Int32.random(in: 0 ..< 100) //1
//        // create it with next node count,
//        // but don't mutate nodeCount itself until we've successfully saved it in the context
//        node1.nodeNumber = Int32(1)
//
//        node1.positionX = Float(0)
//        node1.positionY = Float(0)
//        node1.radius = 30
//
////        if loveNodes.isEmpty {
////            log("loveNodes was empty")
////            loveNodes.append(node1)
////        }
////
////        Array(loveNodes)
////
////        log("loveNodes: \(loveNodes)")
////        return loveNodes
//
//        log("loveNodes.isEmpty: \(loveNodes.isEmpty)")
//
//        let myNodes = loveNodes.isEmpty ? Array(loveNodes) + [node1] : nodes
//        print("myNodes: \(myNodes)")
//        return myNodes
//    }
    
    
    var body: some View {
        VStack { // HACK: bottom right corner alignment
            log("nodeCount in View: \(nodeCount)")
            log("nodes.count: \(nodes.count)")
            
            Spacer()
            startOrNil(nodesEmpty: nodes.isEmpty, moc: moc)
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    
//                    ForEach(1 ..< nodeCount + 1, id: \.self) { nodeNumber -> Ball in
//                    ForEach(1 ..< nodeCount + 1, id: \.self) { nodeNumber -> CDBall in
                    
                    // what happens if you DON'T have any nodes at all...
                    // can do the workaround for the "If no nodes" check
                    
//                    let node1: Node = Node(context: moc)
//                    node1.info = UUID()
//                    node1.isAnchored = true
//            //                    node1.nodeNumber = //Int32.random(in: 0 ..< 100) //1
//                    // create it with next node count,
//                    // but don't mutate nodeCount itself until we've successfully saved it in the context
//                    node1.nodeNumber = Int32(1)
//
//                    node1.positionX = Float(0)
//                    node1.positionY = Float(0)
//                    node1.radius = 30
//
//                    let myNodes = nodes.isEmpty ? nodes.append(node1) : nodes
                    
                    
                    
                    return ForEach(nodes, id: \.self) { (node: Node) in
//                    let myNodes = updatedNodes(loveNodes: nodes)
//                    ForEach(myNodes, id: \.self) { (node: Node) in
                        CDBall(
//                            nodeNumber: nodeNumber,
//                            radius: 60,
//                            connections: $connections,
                            nodeCount: $nodeCount,
                            connectingNode: $connectingNode,
                            node: node)

                    }.padding(.trailing, 30).padding(.bottom, 30)
                    
                }
            }
        }
        // nothing for now
        .backgroundPreferenceValue(BallPreferenceKey.self) { (preferences: [BallPreferenceData]) in
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



//struct ContentView1: View {
struct GraphDisplay: View {

    @Environment(\.managedObjectContext) var moc
    
    @FetchRequest(entity: Node.entity(),
                  // i.e. want to retrieve them in a consistent order, just like when they were created
                  // could also do this sorting outside or elsewhere?
                  sortDescriptors: [NSSortDescriptor(keyPath: \Node.nodeNumber, ascending: true)])
    var nodes: FetchedResults<Node>


//    // if connections are still stored separately...
//    @FetchRequest(entity: Connection.entity(),
//                  sortDescriptors: [])
//    var connections: FetchedResults<Connection>
    
    let graphID: Int
    
    var body: some View {
        log("graphID in GraphDisplay: \(graphID)")
        log("nodes in GraphDisplay: \(nodes)")
//        return GraphView(nodes: nodes, connections: connections)
        return GraphView(nodes: nodes)
    }
}

/* ----------------------------------------------------------------
 PREVIEW
 ---------------------------------------------------------------- */

struct GraphID: Identifiable {
    let id = UUID()
    let graphNumber: Int
}


struct ContentView: View { // MUST BE CALLED CONTENT VIEW
    @Environment(\.managedObjectContext) var moc
    
//    let graphCount: Int = 1
    // Start out with zero graphs
    @State public var graphCount: Int = 0
    
    
    @FetchRequest(entity: Node.entity(),
                  // i.e. want to retrieve them in a consistent order, just like when they were created
                  // could also do this sorting outside or elsewhere?
                  sortDescriptors: [NSSortDescriptor(keyPath: \Node.nodeNumber, ascending: true)])
    var nodes: FetchedResults<Node>
    
    @FetchRequest(entity: Connection.entity(),
                  sortDescriptors: [])
    var connections: FetchedResults<Connection>
        
    let graphs: [GraphID] = [GraphID(graphNumber: 1), GraphID(graphNumber: 2), GraphID(graphNumber: 3)]
    
    @State private var action: Int? = 0
    
    var body: some View {
        
        // TODO: Look further into proper behavior for Nav on iPhone vs. iPad
        NavigationView {
            
            Text("Demo: add some simple user settings here?")
            // this is a view modifier; wherever you attach this, you'll have the
            .navigationBarTitle(Text("Settings"), displayMode: .inline)
                        
            VStack(spacing: 30) {
                List {
                    // DEBUG: Doesn't work if placed outside List
                    // DEBUG: Why must we use the $action mutation here? (graphCount mutation not enough)
                    NavigationLink(destination: GraphDisplay(graphID: graphCount), tag: 1, selection: $action)
                    {
                        Text("Create new graph").onTapGesture {
                            log("we're gonna make a new graph")
    
                            graphCount += 1
                            
                            let node1: Node = Node(context: self.moc)
                            node1.info = UUID()
                            node1.isAnchored = true
                            node1.nodeNumber = Int32(1)
                            node1.positionX = Float(0)
                            node1.positionY = Float(0)
                            node1.radius = 30
                            try? moc.save()
                            
                            log("ContentView: nodes are now: \(nodes)")
                            log("self.action: \(self.action)")
                            
                            // NOTE?: do the CoreData and local state mutate first;
                            // and only then go to the NavLink view
                            self.action = 1

                        }
                    }
                    ForEach(graphs, id: \.id) { (graph: GraphID) in
                        NavigationLink(destination:
                                        Text("Graph: \(graph.graphNumber)")//GraphDisplay(graphID: graph.graphNumber)
                        ) {
                             Text("Edit Graph \(graph.graphNumber)")
                        }
                    }
                }
            }
//            .navigationBarTitle(Text("Graphs"), displayMode: .inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView() // must be named content view
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)

    }
}


func startOrNil(nodesEmpty: Bool, moc: NSManagedObjectContext) -> Button<Text>? {
    if nodesEmpty {
        return Button("Start") {
            let node1: Node = Node(context: moc)
            node1.info = UUID()
            node1.isAnchored = true
            node1.nodeNumber = Int32(1)
            node1.positionX = Float(0)
            node1.positionY = Float(0)
            node1.radius = 30
            try? moc.save()
        }
    }
    else {
        return nil
    }
}
