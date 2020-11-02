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
    
    init(idx: Int, color: Color, radius: CGFloat, connectionSet: [Int]) {
        self.idx = idx
        self.color = color
        self.radius = radius
        self.connectionSet = connectionSet
    }
     
    
    var body: some View {
        coloredCircle(color: isEnabled ? color : Color.gray,
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
 
struct ContentView: View {
    
    @State private var ballCount = 3
    
    var body: some View {
        VStack (spacing: CGFloat(25)) {
            ForEach(0 ..< ballCount, id: \.self) { count -> EdgeBall in
//                EdgeBall(idx: count, color: Color.red, radius: 25)
                
                // 0..< ballCount should be ALL nodes for now
                
                // this works, but we want to use LESS THAN
                
                // can we do random number generation, and filter to be less than ballCount?
                let x: Int = Int.random(in: 0...ballCount)
                let y: Int = Int.random(in: 0...ballCount)
                let z: Int = Int.random(in: 0...ballCount)
                
//                let mySet: [Int] = [].map({Int.random(in: 0...ballCount)})
                let mySet: [Int] = [x, y, z]
                log("mySet in ForEach ballCount: \(mySet)")
                
                let connectionSet: [Int] = Array(0 ..< ballCount)
                log("connectionSet in ForEach ballCount: \(connectionSet)")
                
                return EdgeBall(idx: count,
                                color: Color.red,
                                radius: 25,
                                connectionSet: mySet //connectionSet
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
            
        }.backgroundPreferenceValue(BallPreferenceKey.self) { preferences in
             GeometryReader { geometry in
                ForEach(preferences, content: { (pref: BallPreferenceData) in
                    if preferences.count >= 2 {
                        log("We might draw some lines.")
                        
                        let currentPreference = preferences[pref.viewIdx]
                        let currentConnectionSet: [Int] = pref.connectionSet
                        log("currentConnectionSet in ForEach preferences: \(currentConnectionSet)")
                        
                        // draw a connection from the current node to each node in the connection set
                        ForEach(preferences, content: { (pref2 : BallPreferenceData) in
                            let additionalPreference = preferences[pref2.viewIdx]
                            
                            // for each preference/node pref1,
                            // go through every other preference/node pref2,
                            // and if pref2's index is in pref1's connection set,
                            // draw an edge
                            
                            // print out both the connection set and the current index,
                            // to make sure the .contains stuff is getting it right
                            log("pref2.viewIdx: \(pref2.viewIdx)")
                            
                            if currentConnectionSet.contains(pref2.viewIdx) {
                                log("We're gonna draw a line.")
                                line(from: geometry[currentPreference.center],
                                     to: geometry[additionalPreference.center])
                            }
                            
                            
                        })
                    }
                    else {
                        log("We will NOT draw any lines.")
                    }
                    
                    
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
