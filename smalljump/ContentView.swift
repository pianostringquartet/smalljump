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

struct Connection: Identifiable {
    let id: UUID = UUID()
    let from: Int
    let to: Int
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
    
    @Binding public var connections: [Connection]
    @Binding public var connectingNode: Int?
    
    let idx: Int
    let color: Color
    let radius: CGFloat
    
    init(idx: Int, color: Color, radius: CGFloat, connections: Binding<[Connection]>, connectingNode: Binding<Int?>) {
        self.idx = idx
        self.color = color
        self.radius = radius
        self._connections = connections
        self._connectingNode = connectingNode
    }
     
    var body: some View {
        let existsConnectingNode: Bool = self.connectingNode != nil
        let isConnectingNode: Bool = self.idx == self.connectingNode
        
        coloredCircle(color: isConnectingNode ? Color.green : (isEnabled ? Color.red : Color.gray),
                      radius: radius)
            // Child stores its center in anchor preference data,
            // for parent to later access.
            // NOTE: must come before .offset modifier
            .anchorPreference(key: BallPreferenceKey.self,
                              value: .center, // center for Anchor<CGPoint>
                              transform: { [BallPreferenceData(viewIdx: self.idx, center: $0, isEnabled: self.isEnabled)] })
            .offset(x: self.position.width, y: self.position.height)
            .gesture(DragGesture()
                        .onChanged { self.position = updatePosition(value: $0, position: self.previousPosition) }
                        .onEnded { _ in self.previousPosition = self.position })
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
             // Note: double-tap gesture must come before single-tap gesture
            .onTapGesture(count: 2, perform: {
                            // any time we double click the node, we put it
                            
                            // possible states:
                            // edit mode: i'm cnode and i was enabled
                            // edit mode: i'm cnode and i was disabled
                            // edit mode: i'm not cnode and i was disabled
                            
                            // i.e. if there was no existing cnode, and I'm disabled, re
                            if !existsConnectingNode && !isEnabled {
                                self.connectingNode = self.idx
                                self.isEnabled = true
                            }
                            
                            if isConnectingNode && !isEnabled {
                                // automatically enable nodes that become the connecting node,
//                                self.isEnabled.toggle()
                                self.isEnabled = true
                            }
                            
                            if existsConnectingNode && isConnectingNode {
                                log("edit mode: this node \(self.idx) is connecting node")
                                self.connectingNode = nil // ie user has toggled connecting mode off
                                // and re-enable the node:
                                self.isEnabled = true
                            }
                            else {
                                self.connectingNode = self.idx
                            }})
            
            .onTapGesture(count: 1, perform: {
                //
                
                if !existsConnectingNode { // if we're not in editing mode, enable/disable this node
                    log("not in edit mode: this node \(self.idx) will be enabled/disabled")
                    self.isEnabled.toggle()
                }
                // if we're in editing mode and this node is enabled:
                else if existsConnectingNode && isEnabled {
                    let newConnection: Connection = Connection(from: self.connectingNode!, to: self.idx)
                    self.connections.append(newConnection)
                }
                // else: if we're in editing mode but this node is disabled, don't create a new connection
            })
    }
}


/* ----------------------------------------------------------------
 CONTENT VIEW
 ---------------------------------------------------------------- */

struct ContentView: View {
    
    @State private var ballCount: Int = 3
    
    // the node seeking edges
    @State public var connectingNode: Int? = nil
    
    // all existings edges
    @State public var connections: [Connection] = []
    
    var body: some View {
        VStack (spacing: CGFloat(25)) {
            ForEach(0 ..< ballCount, id: \.self) { count -> EdgeBall in
                return EdgeBall(idx: count,
                                color: Color.red,
                                radius: 25,
                                connections: $connections,
                                connectingNode: $connectingNode
                )
            }
            Button(action: {
                self.ballCount += 1
            }) {
                Image(systemName: "plus")
                    .frame(width: 25, height: 25)
                    .background(Color.blue)
                    .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                    .foregroundColor(.white)
            }}
        .backgroundPreferenceValue(BallPreferenceKey.self) { (preferences: [BallPreferenceData]) in
            if connections.count >= 1 && ballCount >= 2 {
                GeometryReader { (geometry: GeometryProxy) in
                    ForEach(connections, content: { (connection: Connection) in
                        let toPref: BallPreferenceData = preferences[connection.to]
                        let fromPref: BallPreferenceData = preferences[connection.from]
                        
                        // TODO: Simplify this logic
//                            better?:
                        log("connection.to: \(connection.to)")
                        log("connection.from: \(connection.from)")
                        log("toPref.isEnabled: \(toPref.isEnabled)")
                        log("fromPref.isEnabled: \(fromPref.isEnabled)")
                        
                        let cannotDraw: Bool = !toPref.isEnabled || !fromPref.isEnabled
                        log("cannotDraw: \(cannotDraw)")
                        
                        
                        // if one of them is disabled
                        
                        
                        if !cannotDraw {
                            line(from: geometry[toPref.center],
                                 to: geometry[fromPref.center])
                        }
                        
//                        let canDrawConnection: Bool = (toPref.isEnabled && fromPref.isEnabled)
//                            || (connection.to == connectingNode && fromPref.isEnabled)
//                            || (connection.from == connectingNode && toPref.isEnabled)
//
//                        if canDrawConnection {
//                            line(from: geometry[toPref.center],
//                                 to: geometry[fromPref.center])
//                        }
                    })
                }
            }
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
