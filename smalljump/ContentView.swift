//
//  ContentView.swift
//  smalljump
//
//  Created by cjc on 10/31/20.
//

import SwiftUI

/* ----------------------------------------------------------------
 UTILS
 ---------------------------------------------------------------- */

// For debug printing from simulator
func log(_ log: String) -> EmptyView {
    print("** \(log)")
    return EmptyView()
}


/* ----------------------------------------------------------------
 PREFERENCE DATA: passing data up from children to parent view
 ---------------------------------------------------------------- */

// Datatype for preference data
struct BallPreferenceData: Identifiable {
    let id = UUID()
    let viewIdx: Int
    let center: Anchor<CGPoint>
    let isEnabled: Bool
    
    // list of other nodes, id'd by Index, that this node can be / should be / is connected to
    let connectionSet: [Int]
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


func coloredCircle(color: Color, radius: CGFloat) -> some View {
    LinearGradient(gradient: Gradient(colors: [.white, color]),
                   startPoint: .topLeading,
                   endPoint: .bottomTrailing)
        .frame(width: radius, height: radius)
        .clipShape(Circle())
}

// ball's new position = old position + displacement from current drag gesture
func updatePosition(value: DragGesture.Value, position: CGSize) -> CGSize {
    CGSize(width: value.translation.width + position.width,
           height: value.translation.height + position.height)
}
 

 struct EdgeBall: View {
    @State private var position = CGSize.zero
    @State private var previousPosition = CGSize.zero
    
    @State private var isEnabled: Bool = true
    
    @Binding public var activeNodes: [Int]
    @Binding public var connections: [Connection]
    @Binding public var connectingNode: Int
    
    // ForEach connection in connectionSet, create a node
    
    // connectionSet starts out empty
//    @State private var connectionSet: [Int] = []
    
    let connectionSet: [Int]
    
    let idx: Int // should still be able to use their
    let color: Color
    let radius: CGFloat
    
    // can pass connectionSet to EdgeBall when
//    init(connectionSet: [Int]) {
//        self.connectionSet = connectionSet
//    }
    
    init(idx: Int, color: Color, radius: CGFloat, connectionSet: [Int], activeNodes: Binding<[Int]>, connections: Binding<[Connection]>, connectingNode: Binding<Int>) {
        self.idx = idx
        self.color = color
        self.radius = radius
        self.connectionSet = connectionSet
    
    // underscore var name for Bindings
        self._activeNodes = activeNodes
        self._connections = connections
        self._connectingNode = connectingNode
    }
     
    
    var body: some View {
        coloredCircle(color:
//                        activeNodes.contains(idx) ? Color.blue : Color.gray,
                        self.idx == connectingNode ? Color.green : (activeNodes.contains(idx) ? Color.blue : Color.gray),
                        
//                        activeNodes.contains(idx) ? (self.idx == connectingNode ? Color.blue : Color.gray) : Color.gray,
                        
                      // isEnabled ? color : Color.gray,
                      radius: radius)
            // Child stores its center in anchor preference data,
            // for parent to later access.
            // NOTE: must come before .offset modifier
            .anchorPreference(key: BallPreferenceKey.self,
                              value: .center, // center for Anchor<CGPoint>
                              transform: { [BallPreferenceData(viewIdx: self.idx,
                                                               center: $0,
                                                               isEnabled: isEnabled,
                                                               connectionSet: connectionSet
                              )] })
            .offset(x: self.position.width, y: self.position.height)
            .gesture(DragGesture()
                        .onChanged { self.position = updatePosition(value: $0, position: self.previousPosition) }
                        .onEnded { _ in self.previousPosition = self.position })
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
            
            // when double tapped, add self to activeNodes
            .onTapGesture(count: 2,
                          perform: {
                            log("onTapGesture called in EdgeBall \(self.idx)")
                            
                            // will eventually want to remove this?
                            // or allow double tap to toggle this?
                            self.activeNodes.append(self.idx)
                            
                            // ie using the global connectingNode and the global connections list,
                            
                            let newConnection: Connection = Connection(from: self.connectingNode, to: self.idx)
                            log("newConnection will be: \(newConnection)")
                            log("self.connections was: \(self.connections)")
                            self.connections.append(newConnection)
                            log("self.connections is now: \(self.connections)")
                          })

        // remove the tap gesture
        // or use double tap to enter 'edit connection mode'
//            .onTapGesture(count: 2, perform: {
//                self.isEnabled.toggle()
//            })
    }
}


/* ----------------------------------------------------------------
 CONTENT VIEW
 ---------------------------------------------------------------- */


// better?: tuple?
struct Connection: Identifiable {
    let id: UUID = UUID() // implement Identifiable protocol
    let from: Int
    let to: Int
}

struct ContentView: View {
    
    @State private var ballCount: Int = 3
    
    // global public state, ie. redux-db
    @State public var activeNodes: [Int] = [2]
    
    // the node in connecting mode
    // this is not what you want -- don't want to start in editing mode etc.
    // for now, start with a set editing node, and then later use the Int? type to do 0 or nil?
    @State public var connectingNode: Int = 0
//    @State public var connectingNode: Int? = nil
    
    
    
    // dict of
    // i.e. node 0 can connect to node 2 (but not node 1)
    //@State public var connections: Dictionary<Int, [Int]> = [0: [2]]
    
    @State public var connections: [Connection] = [Connection(from: 1, to: 2)]
    
    // later: child can edit its own connections,
    //
    
    
    var body: some View {
        VStack (spacing: CGFloat(25)) {
            ForEach(0 ..< ballCount, id: \.self) { count -> EdgeBall in
//                EdgeBall(idx: count, color: Color.red, radius: 25)
                
                // 0..< ballCount should be ALL nodes for now
                
                // this works, but we want to use LESS THAN
                
                // can we do random number generation, and filter to be less than ballCount?
//                let x: Int = Int.random(in: 0...ballCount)
//                let y: Int = Int.random(in: 0...ballCount)
//                let z: Int = Int.random(in: 0...ballCount)
                
//                let mySet: [Int] = [].map({Int.random(in: 0...ballCount)})
//                let mySet: [Int] = [x, y]
                let mySet: [Int] = []
//                log("mySet in ForEach ballCount: \(mySet)")
                
//                let connectionSet: [Int] = Array(0 ..< ballCount)
//                log("connectionSet in ForEach ballCount: \(connectionSet)")
//                log("activeNodes in ForEach ballCount: \($activeNodes)")
                
                // would be better to pass in a callback, no? that updates the data
                return EdgeBall(idx: count,
                                color: Color.red,
                                radius: 25,
                                connectionSet: mySet, //connectionSet
                                activeNodes: $activeNodes,
                                connections: $connections,
                                connectingNode: $connectingNode
                )
            }
            Button(action: {
                self.ballCount += 1
            }) {
                Text("Create node")
            }
            Button(action: {
                self.ballCount -= 1
            }) {
                Text("Remove node")
            }
            
            
            
//        }.backgroundPreferenceValue(BallPreferenceKey.self) { preferences in
        }.backgroundPreferenceValue(BallPreferenceKey.self) { (preferences: [BallPreferenceData]) in
            // should move if conditional here:
            
            if connections.count >= 1 && ballCount >= 2 {
                log("we have at least one connection")
                GeometryReader { (geometry: GeometryProxy) in
                    ForEach(connections, content: { (connection: Connection) in
                        let toPref: BallPreferenceData = preferences[connection.to]
                        let fromPref: BallPreferenceData = preferences[connection.from]
                        
                        log("toPref: \(toPref)")
                        log("fromPref: \(fromPref)")
                        
                        line(from: geometry[toPref.center],
                             to: geometry[fromPref.center])
                    })
                }
            }
            else {
                log("we don't have any connections to draw")
            }
            
            
            GeometryReader { geometry in
                ForEach(preferences, content: { (pref: BallPreferenceData) in
                    // RULE:
                    // only draw edges if there are atleast two nodes and at least one connection and ballCount >= 2
                    if preferences.count >= 2 && connections.count >= 1 && ballCount >= 2 {
                        log("We might draw some lines.")
                        let currentPreference = preferences[pref.viewIdx]
                        let currentConnectionSet: [Int] = pref.connectionSet
//                        log("currentConnectionSet in ForEach preferences: \(currentConnectionSet)")

                        // draw a connection from the current node to each node in the connection set
                        ForEach(preferences, content: { (pref2 : BallPreferenceData) in
                            let additionalPreference = preferences[pref2.viewIdx]

                            // for each preference/node pref1,
                            // go through every other preference/node pref2,
                            // and if pref2's index is in pref1's connection set,
                            // draw an edge

                            // print out both the connection set and the current index,
                            // to make sure the .contains stuff is getting it right
//                            log("pref2.viewIdx: \(pref2.viewIdx)")

                            if currentConnectionSet.contains(pref2.viewIdx) {
//                                log("We're gonna draw a line.")
                                line(from: geometry[currentPreference.center],
                                     to: geometry[additionalPreference.center])
                            }

                        })
                    }

                    
                    
                    
                    
                    
                    
//
//                    if preferences.count >= 2 {
////                        log("We might draw some lines.")
//
//                        let currentPreference = preferences[pref.viewIdx]
//                        let currentConnectionSet: [Int] = pref.connectionSet
////                        log("currentConnectionSet in ForEach preferences: \(currentConnectionSet)")
//
//                        // draw a connection from the current node to each node in the connection set
//                        ForEach(preferences, content: { (pref2 : BallPreferenceData) in
//                            let additionalPreference = preferences[pref2.viewIdx]
//
//                            // for each preference/node pref1,
//                            // go through every other preference/node pref2,
//                            // and if pref2's index is in pref1's connection set,
//                            // draw an edge
//
//                            // print out both the connection set and the current index,
//                            // to make sure the .contains stuff is getting it right
////                            log("pref2.viewIdx: \(pref2.viewIdx)")
//
//                            if currentConnectionSet.contains(pref2.viewIdx) {
////                                log("We're gonna draw a line.")
//                                line(from: geometry[currentPreference.center],
//                                     to: geometry[additionalPreference.center])
//                            }
//
//                        })
//                    }
//                    else {
////                        log("We will NOT draw any lines.")
//                    }
                    
                    
                    // Only draw edge if at least two nodes and node is enabled
//                    if preferences.count >= 2 && pref.isEnabled {
//                        let currentPreference = preferences[pref.viewIdx]
//                        ForEach(preferences, content: { (pref2: BallPreferenceData) in
//                            let additionalPreference = preferences[pref2.viewIdx]
//                            // Only draw edge is both nodes enabled
//                            if additionalPreference.isEnabled && currentPreference.isEnabled {
//                                line(from: geometry[currentPreference.center],
//                                     to: geometry[additionalPreference.center])
//                            }
//                        } )
//                    }
                })
            }}
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
