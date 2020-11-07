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


struct CDBall: View {
    @Environment(\.managedObjectContext) var moc
    
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
    
    let graphId: Int
    
    // could instead just pass around an array?
//    var connections: FetchedResults<Connection>
//    var connections: [Connection]
    
    
    @FetchRequest(entity: Connection.entity(),
                  sortDescriptors: []
                  //,
//                  predicate: NSPredicate(format: "trashed == %@", false)
    )
//    var fetchedConnections: FetchedResults<Connection>
    var connections: FetchedResults<Connection>
    
    
    init(
//        nodeNumber: Int,
//         radius: CGFloat,
//         connections: Binding<[Connection]>,
//        connections: FetchedResults<Connection>,
         nodeCount: Binding<Int>,
         connectingNode: Binding<Int?>,
         node: Node,
        graphId: Int
        
    ) {
//        self.nodeNumber = nodeNumber
//        self.radius = radius
//        self._connections = connections
//        self.connections = connections
//        self.connections = Array(connections)
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
                        let edge = Connection(context: self.moc)
                        edge.id = UUID()
                        edge.from = Int32(connectingNode!)
                        edge.to = node.nodeNumber
                        edge.graphId = Int32(graphId)
                        edge.trashed = false

//                        let edgeAlreadyExists: Bool = connections.contains(edge)
                        
//                        let edgeAlreadyExists: Bool = Array(connections).contains(edge)
                        
                        // this is not doing what we want --
//                        let edgeAlreadyExists: Bool = !Array(connections).filter { (conn: Connection) -> Bool in
//                            conn.graphId == Int32(graphId) && conn.to == node.nodeNumber && conn.from == Int32(connectingNode!)
//                        }.isEmpty
                        
                        // this works -- ie. can be true or false appropriately
                        let edgeAlreadyExists: Bool = !connections.filter { (conn: Connection) -> Bool in
                            conn.graphId == Int32(graphId) &&
                                (conn.to == node.nodeNumber && conn.from == Int32(connectingNode!)
                                    || conn.from == node.nodeNumber && conn.to == Int32(connectingNode!))
                        }.isEmpty
                        
                        // Alternatively, you can try to fetch a
                        
                        
//                            .contains(edge)
                        
                        log("edgeAlreadyExists: \(edgeAlreadyExists)")

                        // if exist connecting node and I am the connecting node, cancel ie set connecting node=nil
                        if isConnectingNode {
                            log("I am the connecting node; turning me off")
                            self.connectingNode = nil
                        }
                        // if existing connecting node and I am NOT the connecting node AND there already exists a connxn(connecting node, me),
                        // remove the connection and set connecting node=nil
                        else if !isConnectingNode && edgeAlreadyExists {
                            // CORE DATA:
//                            self.connections = connections.filter { $0 != edge }
//
//                            self.connections = connections.filter { $0 != edge }
//                            connections
                            // will this work? ... the edge was even't inserted yet?
                            log("!isConnectingNode && edgeAlreadyExists: connections was: \(Array(connections))")
//                            log("!isConnectingNode && edgeAlreadyExists: fetchedConnections was: \(Array(fetchedConnections))")
                            log("will try to delete an existing edge between FROM connectingNode \(connectingNode!) and TO nodeNumber: \(node.nodeNumber)")
                            
                            // this seems to not be deleting...
                            
//                            moc.delete(edge)
                            
                            let alreadyExistingEdge: Int? = connections.firstIndex(where: { (conn: Connection) -> Bool in
                                conn.graphId == Int32(graphId) &&
                                    (conn.to == node.nodeNumber && conn.from == Int32(connectingNode!)
                                        || conn.from == node.nodeNumber && conn.to == Int32(connectingNode!))
                            })
                            
//                            let FCalreadyExistingEdge: Int = fetchedConnections.firstIndex(where: { (conn: Connection) -> Bool in
//                                conn.graphId == Int32(graphId) &&
//                                    (conn.to == node.nodeNumber && conn.from == Int32(connectingNode!)
//                                        || conn.from == node.nodeNumber && conn.to == Int32(connectingNode!))
//                            })!
  
//                            let xedgeAlreadyExists: Bool = !connections.filter { (conn: Connection) -> Bool in
//                                conn.graphId == Int32(graphId) &&
//                                    (conn.to == node.nodeNumber && conn.from == Int32(connectingNode!)
//                                        || conn.from == node.nodeNumber && conn.to == Int32(connectingNode!))
//                            }.isEmpty
                            
//
                            log("alreadyExistingEdge INDEX is: \(alreadyExistingEdge)")
//                            log("FCalreadyExistingEdge INDEX is: \(FCalreadyExistingEdge)")
                            
//                            fetchedConnections[alreadyExistingEdge!]
                            
                            // These pull out different objects... that's interesting
//                            let conn: Connection = fetchedConnections[alreadyExistingEdge!]
//                            let FCconn: Connection = fetchedConnections[FCalreadyExistingEdge]
                            let conn: Connection = connections[alreadyExistingEdge!]
//                            let FCconn: Connection = fetchedConnections[FCalreadyExistingEdge]
                            
//                            let conn: Connection = fetchedConnections[0]
//                            moc.delete(fetchedConnections[alreadyExistingEdge!])
                            log("conn: \(conn)")
//                            log("FCconn: \(FCconn)")
                            
                            
                            
//                            self.moc.delete(fetchedConnections[alreadyExistingEdge!])
//                            self.moc.delete(connections[alreadyExistingEdge!])
                            
//                            self.moc.delete(connections[alreadyExistingEdge!])
//                            self.moc.delete(connections[alreadyExistingEdge!])
//
//                            log("conn.isDeleted: \(conn.isDeleted)")
//
//                            log("conn.trashed was: \(conn.trashed)")
//                            conn.trashed = true
//                            log("conn.trashed is now: \(conn.trashed)")
//
//
        
                            let fetchRequest : NSFetchRequest<Connection> = Connection.fetchRequest()
//                            fetchRequest.predicate = NSPredicate(format: "from == %@", NSNumber(value: 1))
//                            fetchRequest.predicate = NSPredicate(format: "from == %@", NSNumber(value: NSInteger(node.nodeNumber)))
//                            fetchRequest.predicate = NSPredicate(format: "from == %i", node.nodeNumber)
                            
                            
                            fetchRequest.predicate = NSPredicate(format: "from = %i AND to = %i", connectingNode!, node.nodeNumber)
//                            fetchRequest.predicate = NSPredicate(format: "from == 1",)
                            let fetchedResults = try? moc.fetch(fetchRequest) as! [Connection]
                            log("fetchedResults: \(fetchedResults)")
                            log("node.nodeNumber: \(node.nodeNumber)")
                            log("NSInteger(node.nodeNumber): \(NSInteger(node.nodeNumber))")
                            if let aConnection = fetchedResults?.first {
//                               providerName.text = aContact.providerName
                                log("there was connection: \(aConnection)")
                                moc.delete(aConnection)
                                log("aConnection.isDeleted: \(aConnection.isDeleted)")
                                try? moc.save()
                                // okay, that worked, that deleted the connection
                            }
                            // this can successfully retrieve a connection
                            
//                            self.moc.delete(fetchedConnections[FCalreadyExistingEdge])
                            
                            // these must come after the .delete, but before the moc.save
                            
//                            log("FCconn.isDeleted: \(FCconn.isDeleted)")
                            
                            // this can manually delete certain nodes, yes.
//                            self.moc.delete(fetchedConnections[0])
                            
//                            try? self.moc.save()

//
//                            self.moc.delete(FCconn)
//                            fetchedConnections.remove(at: alreadyExistingEdge)
                            
//                            try? moc.save()
                            
                            // doesn't throw an error...
//                            do {
//                                log("will try to save...")
//                               try moc.save()
//                            } catch {
//                                log("failed to save! error: \(error)")
//                            }
                            
                            
                            
                            log("!isConnectingNode && edgeAlreadyExists: connections is now: \(Array(connections))")
//                            log("!isConnectingNode && edgeAlreadyExists: fetchedConnections was: \(Array(fetchedConnections))")
                            
                            self.connectingNode = nil
                            playSound(sound: "connection_removed", type: "mp3")
                        }
                        // if existing connecting node and I am NOT the connecting node AND there DOES NOT exist a connxn(connecting node, me),
                        // add the connection and set connecting node=nil
                        else if !isConnectingNode && !edgeAlreadyExists {
                            
//                            self.connections.append(edge)
                            // ie. save the edge we defined earlier
                            log("will try to save the earlier defined edge; ie commit the transactions")
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

    
    @State private var nodeCount: Int // = 1 // start with one node

    // all existings edges
//    @State public var connections: [Connection] = []

    // WILL NOT BE PERSISTED:
    // particular node to which we are adding/removing connections
    @State public var connectingNode: Int? = nil
    
    var nodes: FetchedResults<Node>
//    var connections: FetchedResults<Connection>
    
    // filter down to
    @FetchRequest(entity: Connection.entity(),
                  sortDescriptors: []
//                  ,
//                  predicate: NSPredicate(format: "trashed == %@", false)
    )
    var connections: FetchedResults<Connection>
    
    let graphId: Int // doesn't change
    
    init(nodes: FetchedResults<Node>,
         graphId: Int
//         connections: FetchedResults<Connection>
    ) {
        self._nodeCount = State.init(initialValue: nodes.count)
        self.nodes = nodes
//        self.connections = connections
        self.graphId = graphId
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
//                            nodeNumber: nodeNumber,
//                            radius: 60,
//                            connections: $connections,
//                            connections: connections,
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
//            log("backgroundPreferenceValue called")
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
    
//    var connectionsFetchRequest: FetchRequest<Connection>
//    var connections: FetchedResults<Connection> { connectionsFetchRequest.wrappedValue }
//
    @FetchRequest(entity: Connection.entity(),
                  sortDescriptors: []
//                  ,
//                  predicate: NSPredicate(format: "trashed == %@", false)
    )
    var connections: FetchedResults<Connection>
    
    let graphId: Int

    init(graphId: Int) {
        log("inside init: graphId: \(graphId)")
        
        nodesFetchRequest = FetchRequest<Node>(
            entity: Node.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Node.nodeNumber, ascending: true)],
            // should this be?:
            predicate: NSPredicate(format: "graphId = %@", NSNumber(value: graphId)))
        
//        connectionsFetchRequest = FetchRequest<Connection>(
//            entity: Connection.entity(),
//            sortDescriptors: [],
//            predicate: NSPredicate(format: "graphId == %@", NSNumber(value: graphId)))
        
        self.graphId = graphId
    }
    var body: some View {
        log("graphId in GraphDisplay: \(graphId)")
//        log("fetchRequest in GraphDisplay: \(nodesFetchRequest)")
        log("nodes in GraphDisplay: \(nodes)")
        log("connections in GraphDisplay: \(connections)")
//        return GraphView(nodes: nodes, graphId: graphId, connections: connections)
        return GraphView(nodes: nodes, graphId: graphId
//                         ,
//                         connections: connections
        )
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
//                  predicate: NSPredicate(format: "graphId == %@ AND trashed == false", NSNumber(value: 1)))
                  predicate: NSPredicate(format: "graphId = %@", NSNumber(value: 1)))
    var connections: FetchedResults<Connection>
    
    var nodeNumber: Int32 = 1
    
    var body: some View {
        return GraphSelectionView(graphs: graphs)
        
        
////         WORKS:
////        Button("Make students") {
//        Button("Make connections") {
////            let s = Student(context: moc)
////            s.id = UUID()
////            s.name = "Bobby"
////
////            let s2 = Student(context: moc)
////            s2.id = UUID()
////            s2.name = "Diana"
//
//            let edge = Connection(context: self.moc)
//            edge.id = UUID()
//            edge.from = Int32(1)
//            edge.to = 2
//            edge.graphId = Int32(1)
//
////            let edge2 = Connection(context: self.moc)
////            edge2.id = UUID()
////            edge2.from = 1
////            edge2.to = node.nodeNumber
////            edge2.graphId = Int32(graphId)
//
//
//            try? self.moc.save()
//        }
////        Button("Delete someone") {
//        Button("Delete a connection") {
//            // this is also works
////            let bIndex: Int = students.firstIndex(where: {(student: Student) -> Bool in student.name == "Bobby"})!
////            log("bIndex: \(bIndex)")
////            let b = students[bIndex]
////            log("b: \(b)")
////            moc.delete(b)
//            let edgeIndex: Int = connections.firstIndex(where: { (conn: Connection) -> Bool in
//                Int32(1) == Int32(1) &&
//                    (conn.to == nodeNumber && conn.from == Int32(2)
//                        || conn.from == nodeNumber && conn.to == Int32(2))
//            })!
//            log("edgeIndex: \(edgeIndex)")
//
//            let b = connections[edgeIndex]
//            moc.delete(b)
//            // true
//            log("b.isDeleted was just deleted: \(b.isDeleted)")
//
//            try? self.moc.save()
//
//            // false
//            log("b.isDeleted: \(b.isDeleted)")
//        }
//
////        ForEach(students, id: \.id) { (student: Student) in
////            Text("Student: \(student)")
////        }
//        ForEach(connections, id: \.id) { (conn: Connection) in
//            Text("Connection: \(conn)")
//        }
        
        
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
