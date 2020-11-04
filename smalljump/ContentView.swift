//
//  ContentView.swift
//  smalljump
//
//  Created by cjc on 10/31/20.
//

import SwiftUI
import AVFoundation

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
            log("Will try to play sound")
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.play()
        } catch {
            log("Unable to play sound")
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
//    let isEnabled: Bool
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

struct Connection: Identifiable, Equatable {
    let id: UUID = UUID()
    let from: Int
    let to: Int
    
    static func ==(lhs: Connection, rhs: Connection) -> Bool {
//        return lhs.from == rhs.from && lhs.to == rhs.to
        // Edgeless connection:
        return lhs.from == rhs.from && lhs.to == rhs.to || lhs.from == rhs.to && lhs.to == rhs.from
    }
}


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

struct Ball: View {
    // ie balls start out at .zero
    @State private var position = CGSize.zero
    @State private var previousPosition = CGSize.zero
    
    @State private var isAnchored: Bool = true // true just iff ball has NEVER 'been moved enough'
        
    @Binding public var connections: [Connection]
    @Binding public var nodeCount: Int
    @Binding public var connectingNode: Int?
    
    let nodeNumber: Int
    let radius: CGFloat
    
    init(nodeNumber: Int, radius: CGFloat, connections: Binding<[Connection]>, nodeCount: Binding<Int>, connectingNode: Binding<Int?>) {
        self.nodeNumber = nodeNumber
        self.radius = radius
        self._connections = connections
        self._nodeCount = nodeCount
        self._connectingNode = connectingNode
    }
     
    private func determineColor() -> Color {
//        return !isAnchored ? .blue : Color.gray.opacity(0 + Double((abs(position.height) + abs(position.width)) / 99))
        return
            connectingNode == nodeNumber ? .pink :
                !isAnchored ? .blue :
                    Color.gray.opacity(0 + Double((abs(position.height) + abs(position.width)) / 99))
    }
    
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [.white, determineColor()]),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
            .clipShape(Circle())
            .background(Image(systemName: "plus"))
            
            // Child stores its center in anchor preference data,
            // for parent to later access.
            // NOTE: must come before .offset modifier
            .anchorPreference(key: BallPreferenceKey.self,
                              value: .center, // center for Anchor<CGPoint>
                              transform: { [BallPreferenceData(viewIdx: self.nodeNumber, center: $0)] })
            .offset(x: self.position.width, y: self.position.height)
            .gesture(DragGesture()
                        .onChanged { self.position = updatePosition(value: $0, position: self.previousPosition) }
                        .onEnded { (value: DragGesture.Value) in
                            if isAnchored { // only care about minDistance etc. if Anchorded
                                let minDistance: CGFloat = CGFloat(90)
                                let movedEnough: Bool =
                                    abs(value.translation.width) > minDistance ||
                                    abs(value.translation.height) > minDistance
                                if movedEnough {
                                    self.isAnchored.toggle()
                                    self.previousPosition = self.position
                                    self.nodeCount += 1
//                                    log("nodeCount is now: \(nodeCount)")
//                                    log("idx is: \(nodeNumber)")
                                    playSound(sound: "positive_ping", type: "mp3")
                                }
                                else {
                                    withAnimation(.spring()) { self.position = .zero }
                                }
                            }
                            else {
//                                log("is not anchored; will let move freely");
                                self.previousPosition = self.position }
                        })
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
            .frame(width: radius, height: radius)
            .onTapGesture(count: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/, perform: {
                if !isAnchored {
                    log("nodeNumber \(nodeNumber) is not anchored, will allow connections ")
                    log("node is not anchored, so will consider connections...")
                    let existsConnectingNode: Bool = connectingNode != nil
                    let isConnectingNode: Bool = existsConnectingNode && connectingNode == nodeNumber
                    
                    // if no existing connecting node, make this node this cnode
                    // ie user is attempting to create or remove a node
                    if !existsConnectingNode {
                        log("rule 0: nodeNumber: \(nodeNumber)")
//                        log("nodeNumber: \(nodeNumber)")
                        self.connectingNode = self.nodeNumber  //self.nodeCount
                    }
                    else { // ie there is an connecting node:
                        // Does this node already have a connection to the connection node
                        
                        // connection is by index, nodeNumber is by count
                        
//                        let edge1: Connection = Connection(from: connectingNode!, to: self.nodeNumber)
//                        let edge2: Connection = Connection(from: self.nodeNumber, to: connectingNode!)
                        let edge1: Connection = Connection(from: connectingNode! - 1, to: self.nodeNumber - 1)
                        let edge2: Connection = Connection(from: self.nodeNumber - 1, to: connectingNode! - 1)
                        
                        
                        let connectionAlreadyExists: Bool =
                            connections.contains(edge1) || connections.contains(edge2)
                        
                        log("connectionAlreadyExists: \(connectionAlreadyExists)")
                        log("connections.contains(edge1): \(connections.contains(edge1))")
                        log("connections.contains(edge2): \(connections.contains(edge2))")
                        
                        
                        // if exist cnode and I am the cnode, cancel ie set cnode=nil
                        if isConnectingNode {
                            log("rule 1: nodeNumber: \(nodeNumber)")
                            self.connectingNode = nil
                        }
                        // if existing cnode and I am NOT the cnode AND there already exists a connxn(cnode, me), remove the connection and set cnode=nil
                        else if !isConnectingNode && connectionAlreadyExists {
                            log("rule 2: nodeNumber: \(nodeNumber)")
    //                        connections.removeAll(where: (connection: Connection) -> Bool in)
                            let lessConnections = connections.filter { $0 != edge1 && $0 != edge2 }
                            log("lessConnections: \(lessConnections)")
                            self.connections = lessConnections
                            self.connectingNode = nil
                        }
                        // if existing cnode and I am NOT the cnode AND there DOES NOT exist a connxn(cnode, me), add the connection and set cnode=nil
                        else if !isConnectingNode && !connectionAlreadyExists {
                            log("rule 3: nodeNumber: \(nodeNumber)")
                            log("connections was: \(connections)")
                            self.connections.append(edge1)
                            log("connections is now: \(connections)")
                            self.connectingNode = nil
                        }
                    }
                    }

            })
    }
}



/* ----------------------------------------------------------------
 CONTENT VIEW
 ---------------------------------------------------------------- */

struct ContentView: View {
    @State private var nodeCount: Int = 1 // start with one node
    
    // all existings edges
    @State public var connections: [Connection] = []
    
    @State public var connectingNode: Int? = nil

    // everytime the data changes, this exact code is run again with the data
    // but any components with local state will retain their local state, e.g. their position
    var body: some View {
        // Hack for corner alignment
        
//        let conn1 = Connection(from: 1, to: 2)
//        let conn2 = Connection(from: 2, to: 3)
//        let conn3 = Connection(from: 1, to: 2)
//        let conn4 = Connection(from: 2, to: 1)
//        log("should be false: conn1 == conn2: \(conn1 == conn2)")
//        log("should be true: conn1 == conn3: \(conn1 == conn3)")
//        log("should be true: conn1 == conn4: \(conn1 == conn4)")
        
        VStack { // HACK for bottom right corner alignment
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    log("nodeCount: \(nodeCount)")
                    ForEach(1 ..< nodeCount + 1, id: \.self) { nodeNumber -> Ball in
                        Ball(nodeNumber: nodeNumber,
                            radius: 40,
                            connections: $connections,
                            nodeCount: $nodeCount,
                            connectingNode: $connectingNode)
                    }.padding(.trailing, 30).padding(.bottom, 30)
                }
            }
        }
        
        // do nothing for now
        .backgroundPreferenceValue(BallPreferenceKey.self) { (preferences: [BallPreferenceData]) in
            if connections.count >= 1 && nodeCount >= 2 {
                GeometryReader { (geometry: GeometryProxy) in
                    ForEach(connections, content: { (connection: Connection) in
                        log("connection.to: \(connection.to)")
                        log("connection.from: \(connection.from)")
                        
                        // need make these one less
                        
                        let toPref: BallPreferenceData = preferences[connection.to]
                        let fromPref: BallPreferenceData = preferences[connection.from]
//                        let toPref: BallPreferenceData = preferences[connection.to - 1]
//                        let fromPref: BallPreferenceData = preferences[connection.from - 1]
                        log("toPref: \(toPref)")
                        log("fromPref: \(fromPref)")
                        
                        line(from: geometry[toPref.center], to: geometry[fromPref.center])
                        
                    })
                }
            }
            
            
            
            
//            if connections.count >= 1 && nodeCount >= 2 {
//                GeometryReader { (geometry: GeometryProxy) in
//                    ForEach(connections, content: { (connection: Connection) in
//                        let toPref: BallPreferenceData = preferences[connection.to]
//                        let fromPref: BallPreferenceData = preferences[connection.from]
//                        if toPref.isEnabled && fromPref.isEnabled {
//                            line(from: geometry[toPref.center],
//                                 to: geometry[fromPref.center])
//                        }
//                    })
//                }
//            }
        }
    }
}
    


/* ----------------------------------------------------------------
 PREVIEW
 ---------------------------------------------------------------- */

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
