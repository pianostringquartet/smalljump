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


extension View {
  @ViewBuilder
  func `if`<Transform: View>(
    _ condition: Bool,
    transform: (Self) -> Transform
  ) -> some View {
    if condition {
      transform(self)
    } else {
      self
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


struct Ball: View {
    
    // ie balls start out at .zero
    @State private var position = CGSize.zero
    @State private var previousPosition = CGSize.zero
    @State private var isAnchored: Bool = true // true just iff ball has NEVER 'been moved enough'
        
    @Binding public var connections: [Connection]
    @Binding public var nodeCount: Int
    
    let idx: Int
    let color: Color
    let radius: CGFloat
    
    init(idx: Int, color: Color, radius: CGFloat, connections: Binding<[Connection]>, nodeCount: Binding<Int>) {
        self.idx = idx
        self.color = color
        self.radius = radius
        self._connections = connections
        self._nodeCount = nodeCount
    }
     
    var body: some View {
        coloredCircle(color: isAnchored ? .gray : .blue, //color,
                      radius: radius)
        // Child stores its center in anchor preference data,
        // for parent to later access.
        // NOTE: must come before .offset modifier
        .anchorPreference(key: BallPreferenceKey.self,
                          value: .center, // center for Anchor<CGPoint>
                          transform: { [BallPreferenceData(viewIdx: self.idx, center: $0)] })
        .offset(x: self.position.width, y: self.position.height)
        .gesture(DragGesture()
                    .onChanged { (value: DragGesture.Value) in
//                            self.position = updatePosition(value: $0, position: self.previousPosition)
                        self.position = updatePosition(value: value, position: self.previousPosition)
                    }
                    .onEnded { (value: DragGesture.Value) in
                        
                        log("onEnded: value.translation: \(value.translation)");
                        log("onEnded: isAnchored: \(isAnchored)")
                        log("onEnded: nodeCount: \(nodeCount)")
                        if isAnchored { // only care about minDistance etc. if Anchorded
                            let minDistance: CGFloat = CGFloat(100)
                            let movedEnough: Bool =
                                abs(value.translation.width) > minDistance ||
                                abs(value.translation.height) > minDistance
                            if movedEnough {
                                log("moved enough")
                                self.isAnchored.toggle()
                                self.previousPosition = self.position
                                
                                // ball was anchored, but was moved enough to become regular ball
                                // so we now need a new ball

                                log("nodeCount was: \(nodeCount)")
                                self.nodeCount += 1
                                log("nodeCount is now: \(nodeCount)")
                                log("idx is: \(idx)")
                            }
                            else {
                                log("did not move enough");
                                withAnimation(.spring()) { self.position = .zero }
                            }
                        }
                        else {
                            log("is not anchored; will let move freely");
                            self.previousPosition = self.position }
                    })
        .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
    }
}



/* ----------------------------------------------------------------
 CONTENT VIEW
 ---------------------------------------------------------------- */

func textOrNil(_ text: Bool) -> Text? {
    guard text else { return nil }
    return Text("Hello")
}

func imageOrNil(_ text: Bool) -> Image? {
    guard text else { return Image(systemName: "headphones") }
    return nil
}


struct ContentView: View {
    // always want at least 1 node!
    @State private var nodeCount: Int = 1
    
    // all existings edges
    @State public var connections: [Connection] = []

    // everytime the data changes, this exact code is run again with the data
    var body: some View {
        ZStack {
            log("nodeCount: \(nodeCount)")
            
            ForEach(1 ..< nodeCount + 1, id: \.self) { nodeNumber -> Ball in
                Ball(idx: nodeNumber,
                    color: Color.red,
                    radius: 10,
                    connections: $connections,
                    nodeCount: $nodeCount)
            }
        }
        
        // do nothing for now
        .backgroundPreferenceValue(BallPreferenceKey.self) { (preferences: [BallPreferenceData]) in
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
